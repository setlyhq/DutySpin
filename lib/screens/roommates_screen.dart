import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../components/avatar_chip.dart';
import '../state/app_state.dart';
import '../state/models.dart';
import '../theme.dart';
import 'create_or_join_screen.dart';

class RoommatesScreen extends StatefulWidget {
  const RoommatesScreen({super.key});

  @override
  State<RoommatesScreen> createState() => _RoommatesScreenState();
}

class _RoommatesScreenState extends State<RoommatesScreen> {
  bool _refreshedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_refreshedOnce) return;
    _refreshedOnce = true;

    // Ensure we always have an up-to-date view of spaces
    // whenever the Spaces tab is first shown after login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshJoinedRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final List<Room> joinedRooms = state.joinedRooms.isNotEmpty
        ? state.joinedRooms
        : (state.room == null ? <Room>[] : <Room>[state.room!]);
    final room = state.room ?? (joinedRooms.isNotEmpty ? joinedRooms.first : null);
    final roommates = state.roommates;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ListView(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Spaces',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (state.roommates.isNotEmpty)
                AvatarChip(
                  name: state.roommates.firstWhere((r) => r.isYou, orElse: () => state.roommates.first).name,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (joinedRooms.isEmpty)
            const Text(
              'Create a space to start sharing duties.',
              style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            )
          else if (joinedRooms.length == 1)
            Text(
              room?.name ?? joinedRooms.first.name,
              style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            )
          else
            const Text(
              'Pick a space to view duties and members.',
              style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 32),
          if (joinedRooms.isEmpty)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'No spaces yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Create or join a space to start sharing responsibilities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.5,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.welcomeCta.withValues(alpha: 0.35),
                                  blurRadius: 22,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.welcomeCta,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              onPressed: () => Navigator.of(context).pushNamed('/setupRoom', arguments: const SetupRoomArgs.create()),
                              child: const Text('Create a space'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pushNamed('/joinRoom'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              side: const BorderSide(color: AppTheme.border, width: 1.6),
                            ),
                            child: const Text(
                              'Join with invite code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.text,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            if (room != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Current space',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Invite code',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.text,
                              ),
                            ),
                          ),
                          if (room.inviteCode != null && room.inviteCode!.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await Clipboard.setData(ClipboardData(text: room.inviteCode!));
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Invite code copied')),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textMuted),
                              label: const Text(
                                'Copy',
                                style: TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        room.inviteCode ?? '—',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Builder(
                        builder: (_) {
                          final display = roommates.take(3).toList();
                          final extra = roommates.length - display.length;
                          return Row(
                            children: [
                              ...display.map(
                                (rm) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: AvatarChip(name: rm.name, size: 40),
                                ),
                              ),
                              if (extra > 0)
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceMuted,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+$extra',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.welcomeCta),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/setupRoom', arguments: const SetupRoomArgs.create());
                          },
                          child: const Text('Manage members'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (joinedRooms.length > 1) ...[
              const Text(
                'Other spaces',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              ...joinedRooms
                  .where((r) => room == null || r.id != room.id)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            r.name,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.text),
                          ),
                          subtitle: const Text(
                            'Tap to switch to this space',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            await state.switchToRoom(r.id);
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false, arguments: 0);
                          },
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
            ],
            // CTA row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.welcomeCta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/setupRoom', arguments: const SetupRoomArgs.create()),
                      child: const Text('Create a space'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        side: const BorderSide(color: AppTheme.border, width: 1.4),
                      ),
                      onPressed: () => Navigator.of(context).pushNamed('/joinRoom'),
                      child: const Text('Join with code'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
