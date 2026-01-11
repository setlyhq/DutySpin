import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/avatar_chip.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'create_or_join_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _cycleReminder(String current) {
    if (current == 'Daily') return 'Weekly';
    if (current == 'Weekly') return 'Off';
    return 'Daily';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final you = state.roommates.where((r) => r.isYou).isNotEmpty ? state.roommates.firstWhere((r) => r.isYou) : null;
    final canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ListView(
        children: [
          Row(
            children: [
              if (canPop)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.text),
                  tooltip: 'Back',
                ),
              if (canPop) const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  AvatarChip(name: you?.name ?? 'You', imageUrl: you?.avatarUrl, size: 52),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          you?.name ?? 'You',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.text),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/editProfile'),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMuted,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      state.proUnlocked ? 'Unlocked' : 'Upgrade',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'MY HOUSEHOLD',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _Row(title: 'Manage Roommates', onTap: () => Navigator.of(context).pushNamed('/setupRoom', arguments: const SetupRoomArgs.create())),
                const _Divider(),
                _Row(title: 'Room Details', onTap: () => Navigator.of(context).pushNamed('/setupRoom', arguments: const SetupRoomArgs.create())),
                const _Divider(),
                _Row(title: 'Upgrade to Pro', onTap: () => Navigator.of(context).pushNamed('/upgrade')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'NOTIFICATIONS & PREFERENCES',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: state.preferences.pushNotificationsEnabled,
                  onChanged: (v) => context.read<AppState>().setPreferences(pushNotificationsEnabled: v),
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
                ),
                const _Divider(),
                _Row(
                  title: 'Reminder Frequency',
                  subtitle: state.preferences.reminderFrequency,
                  onTap: () => context.read<AppState>().setPreferences(reminderFrequency: _cycleReminder(state.preferences.reminderFrequency)),
                ),
                const _Divider(),
                SwitchListTile(
                  value: state.preferences.doNotDisturbEnabled,
                  onChanged: (v) => context.read<AppState>().setPreferences(doNotDisturbEnabled: v),
                  title: const Text('Do Not Disturb', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'SUPPORT',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w900,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _Row(
                  title: 'Help & Support',
                  onTap: () => _show(context, 'Help & Support', 'We’ll keep this simple for now.'),
                ),
                const _Divider(),
                _Row(
                  title: 'Privacy Policy',
                  onTap: () => _show(context, 'Privacy Policy', 'Local-only demo state in this build.'),
                ),
              ],
            ),
          ),
          if (state.room != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final appState = context.read<AppState>();

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Leave room?'),
                        content: const Text('You will need an invite code to rejoin.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave')),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    try {
                      await appState.leaveRoom();
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                      return;
                    }
                    // Stay within the main shell after leaving a room so
                    // the bottom navigation remains visible.
                    navigator.pushNamedAndRemoveUntil('/main', (r) => false);
                  },
                  child: const Text('Leave Room', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                onPressed: () async {
                  context.read<AppState>().setAuthenticated(false);
                  context.read<AppState>().clearOtpChallenge();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                },
                child: const Text('Log Out', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Version 1.0.0', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  void _show(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppTheme.border);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.onTap});

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.text)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: AppTheme.textMuted)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
