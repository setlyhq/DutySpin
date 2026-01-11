import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';
import 'storage.dart';
import '../services/cloud_service.dart';

enum PostLoginDestination { home, spaces }

class AppState extends ChangeNotifier {
  AppState({StateStorage? storage, required this.firebaseReady}) : _storage = storage ?? StateStorage();

  final bool firebaseReady;

  final StateStorage _storage;
  final _uuid = const Uuid();

  CloudService? _cloud;
  StreamSubscription<Room?>? _roomSub;
  StreamSubscription<List<Roommate>>? _membersSub;
  StreamSubscription<List<Chore>>? _choresSub;
  StreamSubscription<List<DutyRequest>>? _requestsSub;

  bool _hydrated = false;
  bool get hydrated => _hydrated;

  bool onboardingComplete = false;
  bool proUnlocked = false;

  // Session-only auth: not persisted. This matches the "OTP each time" flow.
  bool authenticated = false;

  // Session-only OTP challenge: not persisted.
  String? _otpDestination;
  String? _otpCode;
  DateTime? _otpExpiresAt;

  Room? room;
  List<Roommate> roommates = [];
  List<Chore> chores = [];
  List<DutyRequest> requests = [];
  Preferences preferences = Preferences.defaults();
  // All rooms/spaces the user belongs to (cloud-backed when available).
  List<Room> joinedRooms = [];

  /// Local-only seed data for end-to-end tests.
  ///
  /// This avoids talking to Firebase/Firestore and gives Playwright
  /// a deterministic room, roommates, chores, and requests to assert on.
  Future<void> seedForE2eTests() async {
    await _storage.clear();
    await _roomSub?.cancel();
    await _membersSub?.cancel();
    await _choresSub?.cancel();
    await _requestsSub?.cancel();
    _roomSub = null;
    _membersSub = null;
    _choresSub = null;
    _requestsSub = null;

    authenticated = true;
    onboardingComplete = true;
    proUnlocked = false;
    clearOtpChallenge();

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final you = Roommate(id: _uuid.v4(), name: 'You (Test)', email: 'you@test.local', isYou: true);
    final alex = Roommate(id: _uuid.v4(), name: 'Alex', email: 'alex@test.local');
    final jamie = Roommate(id: _uuid.v4(), name: 'Jamie', email: 'jamie@test.local');

    final testRoom = Room(id: _uuid.v4(), name: 'Test Home', inviteCode: 'TEST01');

    final dishes = Chore(
      id: _uuid.v4(),
      title: 'Dishes',
      createdAtIso: now.toIso8601String(),
      participantRoommateIds: [you.id, alex.id, jamie.id],
      currentTurnRoommateId: you.id,
      nextTurnRoommateId: alex.id,
      repeatText: 'Daily',
      history: [
        ChoreHistoryEntry(
          id: _uuid.v4(),
          completedByRoommateId: alex.id,
          completedAtIso: yesterday.toIso8601String(),
        ),
      ],
    );

    final trash = Chore(
      id: _uuid.v4(),
      title: 'Take out trash',
      createdAtIso: now.toIso8601String(),
      participantRoommateIds: [you.id, alex.id, jamie.id],
      currentTurnRoommateId: alex.id,
      nextTurnRoommateId: jamie.id,
      repeatText: 'Weekly',
      history: const [],
    );

    final request = DutyRequest(
      id: _uuid.v4(),
      choreId: dishes.id,
      fromRoommateId: you.id,
      toRoommateId: alex.id,
      createdAtIso: now.toIso8601String(),
      note: 'Can you cover dishes tonight? I will be late.',
    );

    room = testRoom;
    roommates = [you, alex, jamie];
    chores = [dishes, trash];
    requests = [request];
    preferences = Preferences.defaults();
    joinedRooms = [testRoom];

    _hydrated = true;
    await _persist();
    notifyListeners();
  }

  Future<void> hydrate() async {
    final loaded = await _storage.load();
    if (loaded != null) {
      onboardingComplete = loaded.onboardingComplete;
      proUnlocked = loaded.proUnlocked;
      room = loaded.room;
      roommates = _ensureYou(loaded.roommates);
      chores = loaded.chores;
      preferences = loaded.preferences;
    } else {
      roommates = _ensureYou(roommates);
    }

    _hydrated = true;
    notifyListeners();
  }

  Future<void> _ensureCloudReady() async {
    if (!firebaseReady) return;
    _cloud ??= CloudService();
    try {
      await _cloud!.ensureSignedIn();
    } catch (_) {
      // If Firebase isn't fully configured on this platform, stay in local mode.
      _cloud = null;
    }
  }

  Future<void> _subscribeToCloudRoom(String roomId) async {
    await _ensureCloudReady();
    if (_cloud == null) return;

    await _roomSub?.cancel();
    await _membersSub?.cancel();
    await _choresSub?.cancel();
    await _requestsSub?.cancel();

    _roomSub = _cloud!.watchRoom(roomId).listen((r) {
      room = r;
      notifyListeners();
      _persist();
    });

    _membersSub = _cloud!.watchMembers(roomId).listen((list) {
      roommates = _ensureYou(list);
      notifyListeners();
      _persist();
    });

    _choresSub = _cloud!.watchChores(roomId).listen((list) {
      chores = list;
      notifyListeners();
      _persist();
    });

    _requestsSub = _cloud!.watchRequests(roomId).listen((list) {
      requests = list;
      notifyListeners();
    });
  }

  /// Switches the active space/room by subscribing to its
  /// cloud streams. Intended for use by UI when the user
  /// picks a different space from the Spaces tab.
  Future<void> switchToRoom(String roomId) async {
    await _subscribeToCloudRoom(roomId);
  }

  /// Refreshes the list of rooms the current user belongs to.
  ///
  /// When cloud sync is unavailable, this falls back to the
  /// locally-tracked `room` so the rest of the app can still
  /// reason about "zero vs some" spaces.
  Future<void> refreshJoinedRooms() async {
    await _ensureCloudReady();
    if (_cloud == null) {
      joinedRooms = room == null ? <Room>[] : <Room>[room!];
      return;
    }

    try {
      joinedRooms = await _cloud!.listMyRooms();
    } catch (_) {
      // If listing fails, fall back to the current room.
      joinedRooms = room == null ? <Room>[] : <Room>[room!];
    }
    notifyListeners();
  }

  /// Where to land the user after a fresh login.
  ///
  /// - If the user has exactly 1 space, go to Home.
  /// - If they have 0 or 2+ spaces, start them on the Spaces tab
  ///   so they can create or pick a space.
  Future<PostLoginDestination> decidePostLoginDestination() async {
    await refreshJoinedRooms();

    // When cloud is unavailable, infer from local room state.
    if (_cloud == null) {
      return room == null ? PostLoginDestination.spaces : PostLoginDestination.home;
    }

    final count = joinedRooms.length;
    if (count == 1) {
      final only = joinedRooms.first;
      room = only;
      await _subscribeToCloudRoom(only.id);
      notifyListeners();
      await _persist();
      return PostLoginDestination.home;
    }

    // 0 or 2+ spaces → start on Spaces tab.
    // If a previously-selected room exists, keep it subscribed;
    // otherwise, pick the first as the current room so Home tab
    // will have context once the user navigates there.
    if (count >= 1) {
      Room selected = joinedRooms.first;
      try {
        await _ensureCloudReady();
        final preferredId = await _cloud!.getMyRoomId();
        if (preferredId != null && preferredId.isNotEmpty) {
          final match = joinedRooms.where((r) => r.id == preferredId);
          if (match.isNotEmpty) {
            selected = match.first;
          }
        }
      } catch (_) {}

      room = selected;
      await _subscribeToCloudRoom(selected.id);
      notifyListeners();
      await _persist();
    } else {
      room = null;
      notifyListeners();
      await _persist();
    }

    return PostLoginDestination.spaces;
  }

  bool get hasActiveOtp {
    if (_otpCode == null || _otpExpiresAt == null) return false;
    return DateTime.now().isBefore(_otpExpiresAt!);
  }

  String? get otpDestination => _otpDestination;

  Duration? get otpTimeRemaining {
    if (_otpExpiresAt == null) return null;
    final d = _otpExpiresAt!.difference(DateTime.now());
    if (d.isNegative) return Duration.zero;
    return d;
  }

  void setAuthenticated(bool value) {
    authenticated = value;
    if (!value) {
      _roomSub?.cancel();
      _membersSub?.cancel();
      _choresSub?.cancel();
      _requestsSub?.cancel();
      _roomSub = null;
      _membersSub = null;
      _choresSub = null;
      _requestsSub = null;
      room = null;
      roommates = _ensureYou([]);
      chores = [];
      requests = [];
      notifyListeners();
      return;
    }

    _syncYouFromFirebaseUser();
    notifyListeners();

    // Best-effort cloud hydration when Firebase is available.
    unawaited(() async {
      await _ensureCloudReady();
      if (_cloud == null) return;
      final roomId = await _cloud!.getMyRoomId();
      if (roomId == null || roomId.isEmpty) return;
      await _subscribeToCloudRoom(roomId);
    }());
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final idx = roommates.indexWhere((r) => r.isYou);
    if (idx >= 0) {
      final existing = roommates[idx];
      roommates = [
        ...roommates.take(idx),
        Roommate(
          id: existing.id,
          name: trimmed,
          email: existing.email,
          avatarUrl: existing.avatarUrl,
          isYou: true,
        ),
        ...roommates.skip(idx + 1),
      ];
      notifyListeners();
      await _persist();
    }

    if (firebaseReady) {
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(trimmed);
      } catch (_) {}
    }

    await _ensureCloudReady();
    if (_cloud != null && room != null) {
      unawaited(_cloud!.updateMyDisplayName(roomId: room!.id, displayName: trimmed));
    }
  }

  Future<void> updateAvatarUrl(String? url) async {
    final idx = roommates.indexWhere((r) => r.isYou);
    if (idx >= 0) {
      final existing = roommates[idx];
      roommates = [
        ...roommates.take(idx),
        Roommate(
          id: existing.id,
          name: existing.name,
          email: existing.email,
          avatarUrl: url,
          isYou: true,
        ),
        ...roommates.skip(idx + 1),
      ];
      notifyListeners();
      await _persist();
    }

    if (firebaseReady) {
      try {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
      } catch (_) {}
    }

    await _ensureCloudReady();
    if (_cloud != null && room != null) {
      unawaited(_cloud!.updateMyAvatarUrl(roomId: room!.id, avatarUrl: url));
    }
  }

  /// Creates a new 6-digit OTP challenge for the given destination.
  /// In a real build, this would call the backend (Firebase/Auth API).
  void startOtpChallenge({required String destination}) {
    _otpDestination = destination;
    // Pseudo-random but deterministic enough for a demo.
    final seed = DateTime.now().microsecondsSinceEpoch % 900000;
    _otpCode = (100000 + seed).toString().padLeft(6, '0');
    _otpExpiresAt = DateTime.now().add(const Duration(minutes: 5));
    notifyListeners();
  }

  bool verifyOtpCode(String entered) {
    final c = entered.trim();
    if (c.length != 6) return false;
    if (_otpCode == null || _otpExpiresAt == null) return false;
    if (DateTime.now().isAfter(_otpExpiresAt!)) return false;
    return c == _otpCode;
  }

  void clearOtpChallenge() {
    _otpDestination = null;
    _otpCode = null;
    _otpExpiresAt = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (!_hydrated) return;
    final snapshot = PersistedState(
      onboardingComplete: onboardingComplete,
      proUnlocked: proUnlocked,
      room: room,
      roommates: roommates,
      chores: chores,
      preferences: preferences,
    );
    await _storage.save(snapshot);
  }

  List<Roommate> _ensureYou(List<Roommate> list) {
    if (list.any((r) => r.isYou)) return list;
    return [Roommate(id: _uuid.v4(), name: 'You', isYou: true), ...list];
  }

  void _syncYouFromFirebaseUser() {
    if (!firebaseReady) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? name = user.displayName?.trim();
      if (name == null || name.isEmpty) {
        final email = user.email?.trim();
        if (email != null && email.isNotEmpty && email.contains('@')) {
          name = email.split('@').first;
        } else if (user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty) {
          name = user.phoneNumber!.trim();
        }
      }

      if (name == null || name.isEmpty) return;

      final idx = roommates.indexWhere((r) => r.isYou);
      if (idx < 0) {
        roommates = _ensureYou(roommates);
        return;
      }

      final existing = roommates[idx];
      final email = user.email ?? existing.email;

      final avatarUrl = user.photoURL ?? existing.avatarUrl;

      if (existing.name == name && (existing.email ?? '') == (email ?? '') && (existing.avatarUrl ?? '') == (avatarUrl ?? '')) {
        return;
      }

      roommates = [
        ...roommates.take(idx),
        Roommate(id: existing.id, name: name, email: email, avatarUrl: avatarUrl, isYou: true),
        ...roommates.skip(idx + 1),
      ];

      _persist();
    } catch (_) {
      // If Firebase isn't available or something goes wrong, silently ignore
      // and keep the existing local "You" placeholder.
    }
  }

  String _inviteCode() {
    final v = _uuid.v4().replaceAll('-', '');
    return v.substring(v.length - 6).toUpperCase();
  }

  String _pickInitialTurnId() {
    final you = roommates.where((r) => r.isYou).toList();
    if (you.isNotEmpty) return you.first.id;
    if (roommates.isNotEmpty) return roommates.first.id;
    final fallback = Roommate(id: _uuid.v4(), name: 'You', isYou: true);
    roommates = [fallback];
    return fallback.id;
  }

  ({String current, String next}) _computeNextTurn(String currentId) {
    if (roommates.isEmpty) {
      return (current: currentId, next: currentId);
    }
    final idx = roommates.indexWhere((r) => r.id == currentId);
    final safeIdx = idx >= 0 ? idx : 0;
    final nextIdx = (safeIdx + 1) % roommates.length;
    return (current: roommates[safeIdx].id, next: roommates[nextIdx].id);
  }

  Future<void> reset() async {
    await _storage.clear();
    onboardingComplete = false;
    proUnlocked = false;
    authenticated = false;
    clearOtpChallenge();
    await _roomSub?.cancel();
    await _membersSub?.cancel();
    await _choresSub?.cancel();
    await _requestsSub?.cancel();
    _roomSub = null;
    _membersSub = null;
    _choresSub = null;
    _requestsSub = null;
    room = null;
    roommates = _ensureYou([]);
    chores = [];
    requests = [];
    preferences = Preferences.defaults();
    notifyListeners();
  }

  Future<void> createRoom(String roomName) async {
    final trimmed = roomName.trim().isEmpty ? 'My Home' : roomName.trim();

    await _ensureCloudReady();
    if (authenticated && _cloud != null) {
      final displayName = roommates.where((r) => r.isYou).isNotEmpty ? roommates.firstWhere((r) => r.isYou).name : 'You';
      final created = await _cloud!.createRoom(name: trimmed, displayName: displayName);
      room = created;
      notifyListeners();
      await _persist();
      await _subscribeToCloudRoom(created.id);
      await refreshJoinedRooms();
      return;
    }

    room = Room(id: _uuid.v4(), name: trimmed, inviteCode: _inviteCode());
    roommates = _ensureYou(roommates);
    notifyListeners();
    await _persist();
    await refreshJoinedRooms();
  }

  Future<void> joinRoom(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase();

    await _ensureCloudReady();
    if (authenticated && _cloud != null) {
      final displayName = roommates.where((r) => r.isYou).isNotEmpty ? roommates.firstWhere((r) => r.isYou).name : 'You';
      final joined = await _cloud!.joinRoom(inviteCode: code, displayName: displayName);
      room = joined;
      notifyListeners();
      await _persist();
      await _subscribeToCloudRoom(joined.id);
      await refreshJoinedRooms();
      return;
    }

    room = Room(id: _uuid.v4(), name: 'Shared Home', inviteCode: code);
    roommates = _ensureYou(roommates);
    notifyListeners();
    await _persist();
    await refreshJoinedRooms();
  }

  Future<void> leaveRoom() async {
    final r = room;
    if (r == null) return;

    await _ensureCloudReady();
    if (authenticated && _cloud != null) {
      await _cloud!.leaveRoom(r.id);
    }

    room = null;
    chores = [];
    roommates = _ensureYou([]);
    notifyListeners();
    await _persist();
    await refreshJoinedRooms();
  }

  Future<void> setRoomName(String name) async {
    if (room == null) return;
    room = Room(id: room!.id, name: name, inviteCode: room!.inviteCode);
    notifyListeners();
    await _persist();

    await _ensureCloudReady();
    if (authenticated && _cloud != null) {
      try {
        await _cloud!.updateRoomName(roomId: room!.id, name: name);
        await refreshJoinedRooms();
      } catch (_) {
        // Ignore cloud errors; local state is already updated.
      }
    }
  }

  Future<void> addRoommate({required String name, String? email}) async {
    final n = name.trim();
    if (n.isEmpty) return;
    roommates = _ensureYou([...roommates, Roommate(id: _uuid.v4(), name: n, email: email?.trim().isEmpty == true ? null : email?.trim())]);
    _reconcileChoreTurns();
    notifyListeners();
    await _persist();
  }

  Future<void> removeRoommate(String roommateId) async {
    final rm = roommates.firstWhere((r) => r.id == roommateId, orElse: () => Roommate(id: '', name: ''));
    if (rm.id.isEmpty || rm.isYou) return;
    roommates = _ensureYou(roommates.where((r) => r.id != roommateId).toList());
    _reconcileChoreTurns();
    notifyListeners();
    await _persist();
  }

  void _reconcileChoreTurns() {
    for (var i = 0; i < chores.length; i += 1) {
      final c = chores[i];
      // Keep participant list in sync with current roommates.
      var participants = c.participantRoommateIds.where((id) => roommates.any((r) => r.id == id)).toList();
      if (participants.isEmpty) {
        participants = roommates.map((r) => r.id).toList();
      }

      var currentId = c.currentTurnRoommateId;
      if (!participants.contains(currentId)) {
        currentId = participants.isNotEmpty ? participants.first : _pickInitialTurnId();
      }

      final idx = participants.indexOf(currentId);
      final safeIdx = idx >= 0 ? idx : 0;
      final nextIdx = (safeIdx + 1) % participants.length;

      chores[i] = Chore(
        id: c.id,
        title: c.title,
        createdAtIso: c.createdAtIso,
        participantRoommateIds: participants,
        repeatText: c.repeatText,
        currentTurnRoommateId: participants[safeIdx],
        nextTurnRoommateId: participants[nextIdx],
        history: c.history,
      );
    }
  }

  Future<void> addChore(String title) async {
    final t = title.trim();
    if (t.isEmpty) return;

    await _ensureCloudReady();
    if (room != null && authenticated && _cloud != null) {
      await _cloud!.addChore(roomId: room!.id, title: t);
      return;
    }

    roommates = _ensureYou(roommates);
    final initial = _pickInitialTurnId();
    final turn = _computeNextTurn(initial);

    final participants = roommates.map((r) => r.id).toList();

    final chore = Chore(
      id: _uuid.v4(),
      title: t,
      createdAtIso: DateTime.now().toIso8601String(),
      participantRoommateIds: participants,
      currentTurnRoommateId: turn.current,
      nextTurnRoommateId: turn.next,
      history: const [],
    );

    chores = [chore, ...chores];
    notifyListeners();
    await _persist();
  }

  Future<void> removeChore(String choreId) async {
    await _ensureCloudReady();
    if (room != null && authenticated && _cloud != null) {
      await _cloud!.removeChore(roomId: room!.id, choreId: choreId);
      return;
    }

    chores = chores.where((c) => c.id != choreId).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> createRequest({
    required String choreId,
    required String toRoommateId,
    String? note,
  }) async {
    final r = room;
    if (r == null) return;

    await _ensureCloudReady();
    final me = roommates.where((rm) => rm.isYou).isNotEmpty ? roommates.firstWhere((rm) => rm.isYou) : null;
    final fromId = me?.id ?? (roommates.isNotEmpty ? roommates.first.id : '');

    if (authenticated && _cloud != null) {
      await _cloud!.createRequest(
        roomId: r.id,
        choreId: choreId,
        fromRoommateId: fromId,
        toRoommateId: toRoommateId,
        note: note,
      );
      return;
    }

    // Local-only fallback so the Requests tab still reflects intent.
    final entry = DutyRequest(
      id: _uuid.v4(),
      choreId: choreId,
      fromRoommateId: fromId,
      toRoommateId: toRoommateId,
      createdAtIso: DateTime.now().toIso8601String(),
      note: note,
    );
    requests = [entry, ...requests];
    notifyListeners();
  }

  Future<void> configureChore({
    required String choreId,
    required String repeatText,
    required List<String> participantRoommateIds,
    required String firstTurnRoommateId,
  }) async {
    final trimmedRepeat = repeatText.trim().isEmpty ? 'Weekly' : repeatText.trim();

    await _ensureCloudReady();
    if (room != null && authenticated && _cloud != null) {
      await _cloud!.configureChore(
        roomId: room!.id,
        choreId: choreId,
        repeatText: trimmedRepeat,
        participantRoommateIds: participantRoommateIds,
        firstTurnRoommateId: firstTurnRoommateId,
      );
      return;
    }

    // Local-only mode: update the in-memory chore and persist.
    final idx = chores.indexWhere((c) => c.id == choreId);
    if (idx < 0) return;

    var participants = participantRoommateIds.where((id) => roommates.any((r) => r.id == id)).toList();
    if (participants.isEmpty) {
      participants = roommates.map((r) => r.id).toList();
    }

    var first = firstTurnRoommateId;
    if (!participants.contains(first)) {
      first = participants.isNotEmpty ? participants.first : _pickInitialTurnId();
    }

    final firstIdx = participants.indexOf(first);
    final safeIdx = firstIdx >= 0 ? firstIdx : 0;
    final nextIdx = (safeIdx + 1) % participants.length;

    final existing = chores[idx];
    chores[idx] = Chore(
      id: existing.id,
      title: existing.title,
      createdAtIso: existing.createdAtIso,
      participantRoommateIds: participants,
      repeatText: trimmedRepeat,
      currentTurnRoommateId: participants[safeIdx],
      nextTurnRoommateId: participants[nextIdx],
      history: existing.history,
    );

    notifyListeners();
    await _persist();
  }

  Future<void> markChoreDone(String choreId) async {
    await _ensureCloudReady();
    if (room != null && authenticated && _cloud != null) {
      final existing = chores.where((c) => c.id == choreId).isNotEmpty ? chores.firstWhere((c) => c.id == choreId) : null;
      if (existing == null) return;
      await _cloud!.markChoreDone(roomId: room!.id, choreId: choreId, expectedCurrentId: existing.currentTurnRoommateId);
      return;
    }

    chores = chores.map((c) {
      if (c.id != choreId) return c;

      final entry = ChoreHistoryEntry(
        id: _uuid.v4(),
        completedByRoommateId: c.currentTurnRoommateId,
        completedAtIso: DateTime.now().toIso8601String(),
      );
      final participants = c.participantRoommateIds.isNotEmpty
          ? c.participantRoommateIds
          : roommates.map((r) => r.id).toList();

      if (participants.isEmpty) {
        final fallback = _pickInitialTurnId();
        return Chore(
          id: c.id,
          title: c.title,
          createdAtIso: c.createdAtIso,
          participantRoommateIds: [fallback],
          repeatText: c.repeatText,
          currentTurnRoommateId: fallback,
          nextTurnRoommateId: fallback,
          history: [entry, ...c.history].take(20).toList(),
        );
      }

      final idx = participants.indexOf(c.currentTurnRoommateId);
      final safeIdx = idx >= 0 ? idx : 0;
      final nextIdx = (safeIdx + 1) % participants.length;
      final next2Idx = (nextIdx + 1) % participants.length;

      return Chore(
        id: c.id,
        title: c.title,
        createdAtIso: c.createdAtIso,
        participantRoommateIds: participants,
        repeatText: c.repeatText,
        currentTurnRoommateId: participants[nextIdx],
        nextTurnRoommateId: participants[next2Idx],
        history: [entry, ...c.history].take(20).toList(),
      );
    }).toList();

    notifyListeners();
    await _persist();
  }

  Future<void> setOnboardingComplete(bool value) async {
    onboardingComplete = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setProUnlocked(bool value) async {
    proUnlocked = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setPreferences({bool? pushNotificationsEnabled, String? reminderFrequency, bool? doNotDisturbEnabled}) async {
    preferences = Preferences(
      pushNotificationsEnabled: pushNotificationsEnabled ?? preferences.pushNotificationsEnabled,
      reminderFrequency: reminderFrequency ?? preferences.reminderFrequency,
      doNotDisturbEnabled: doNotDisturbEnabled ?? preferences.doNotDisturbEnabled,
    );
    notifyListeners();
    await _persist();
  }

  Roommate? roommateById(String id) {
    try {
      return roommates.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
