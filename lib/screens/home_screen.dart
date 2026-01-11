import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/models.dart';
import '../theme.dart';
import 'create_or_join_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _headerDate() {
    final d = DateTime.now();
    final weekday = DateFormat('EEEE').format(d).toUpperCase();
    final rest = DateFormat('MMM d').format(d).toUpperCase();
    return '$weekday, $rest';
  }

  void _showNewRequestSheet(BuildContext context) {
    final state = context.read<AppState>();
    final chores = state.chores;
    final roommates = state.roommates.where((r) => !r.isYou).toList();

    if (chores.isEmpty || roommates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a duty and a roommate before sending a request.')),
      );
      return;
    }

    Chore selectedChore = chores.first;
    var selectedTo = roommates.first;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'New request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ask someone to cover a duty.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'DUTY',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Chore>(
                    initialValue: selectedChore,
                    items: chores
                        .map(
                          (c) => DropdownMenuItem<Chore>(
                            value: c,
                            child: Text(c.title),
                          ),
                        )
                        .toList(),
                    onChanged: (c) {
                      if (c == null) return;
                      setModalState(() => selectedChore = c);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ASKING',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Roommate>(
                    initialValue: selectedTo,
                    items: roommates
                        .map(
                          (r) => DropdownMenuItem<Roommate>(
                            value: r,
                            child: Text(r.name),
                          ),
                        )
                        .toList(),
                    onChanged: (r) {
                      if (r == null) return;
                      setModalState(() => selectedTo = r);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Optional note (e.g., “I’m out tonight, can you cover?”)',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        await state.createRequest(
                          choreId: selectedChore.id,
                          toRoommateId: selectedTo.id,
                          note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request sent.')),
                          );
                        }
                      },
                      child: const Text('Send request'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final you = state.roommates.where((r) => r.isYou).isNotEmpty ? state.roommates.firstWhere((r) => r.isYou) : null;
    final youId = you?.id;

    // Spaces / rooms context
    final spacesCount = state.joinedRooms.isNotEmpty
        ? state.joinedRooms.length
        : (state.room == null ? 0 : 1);
    final hasActiveSpace = state.room != null;

    // Split chores into "due today" vs "not due today" using a
    // simple rule: a chore is due today if it has not yet been
    // completed today. This keeps V1 lightweight while still
    // enabling the "No duties due today" state.
    final now = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final dueToday = <Chore>[];
    final notDueToday = <Chore>[];

    for (final c in state.chores) {
      final last = c.history.isNotEmpty ? c.history.first : null;
      if (last == null) {
        dueToday.add(c);
      } else {
        final when = DateTime.tryParse(last.completedAtIso)?.toLocal();
        if (when != null && isSameDay(when, now)) {
          notDueToday.add(c);
        } else {
          dueToday.add(c);
        }
      }
    }

    final totalChores = state.chores.length;
    final dueTodayCount = dueToday.length;

    String headerLine;
    String? secondaryLine;
    if (spacesCount == 0) {
      headerLine = 'Welcome Home';
      secondaryLine = 'Create or join a space to get started.';
    } else if (totalChores == 0 && hasActiveSpace) {
      headerLine = 'Your space is ready — add your first duty.';
    } else if (dueTodayCount == 0) {
      headerLine = 'No duties due today';
      secondaryLine = "You're all set for today.";
    } else if (dueTodayCount == 1) {
      headerLine = '1 duty due today';
    } else {
      headerLine = '$dueTodayCount duties due today';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ListView(
        children: [
          const Text(
            'Today',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            you?.name ?? 'You',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _headerDate(),
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (hasActiveSpace) ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    // Jump to the Spaces tab so the user can
                    // switch or manage spaces from Home.
                    Navigator.of(context).pushNamed('/main', arguments: 1);
                  },
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home_rounded, size: 18, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          state.room?.name ?? 'Active space',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/addChores'),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add duty'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showNewRequestSheet(context),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text('New request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.text,
                    side: const BorderSide(color: AppTheme.border),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            headerLine,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.text,
              letterSpacing: -0.3,
            ),
          ),
          if (secondaryLine != null) ...[
            const SizedBox(height: 6),
            Text(
              secondaryLine,
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 24),
          if (spacesCount == 0) ...[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Home',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a space or join with a code to get started.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.5,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/setupRoom',
                              arguments: const SetupRoomArgs.create(),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            ),
                            child: const Text('Create a space'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pushNamed('/joinRoom'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: const Text('Join with code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else if (state.chores.isEmpty)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your space is ready',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add your first duty to start sharing responsibilities.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.5,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pushNamed('/addChores'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            ),
                            child: const Text('Add your first duty'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            ...dueToday.map((c) {
              final current = state.roommateById(c.currentTurnRoommateId);
              final next = state.roommateById(c.nextTurnRoommateId);
              final yourTurn = youId != null && c.currentTurnRoommateId == youId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.text,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    yourTurn
                                        ? 'It’s your turn • Next: ${next?.name ?? '—'}'
                                        : "${current?.name ?? 'Someone'} is up • Next: ${next?.name ?? '—'}",
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: yourTurn
                                    ? () async {
                                        try {
                                          await context.read<AppState>().markChoreDone(c.id);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(112, 46),
                                  backgroundColor: yourTurn ? AppTheme.primary : AppTheme.surfaceMuted,
                                  foregroundColor: yourTurn ? Colors.white : AppTheme.textMuted,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    elevation: yourTurn ? 4 : 0,
                                    shadowColor: yourTurn
                                      ? AppTheme.primary.withValues(alpha: 0.25)
                                      : Colors.transparent,
                                ),
                                child: Text(yourTurn ? 'Done' : 'Waiting'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/choreDetail', arguments: c.id),
                          child: const Text(
                            'View details',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          if (dueTodayCount == 0 && notDueToday.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            ...notDueToday.take(3).map((c) {
              final current = state.roommateById(c.currentTurnRoommateId);
              final next = state.roommateById(c.nextTurnRoommateId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Next up: ${current?.name ?? '—'} • Then: ${next?.name ?? '—'}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
