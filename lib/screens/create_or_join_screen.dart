import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/avatar_chip.dart';
import '../state/app_state.dart';
import '../theme.dart';

class CreateOrJoinScreen extends StatefulWidget {
  const CreateOrJoinScreen({super.key});

  @override
  State<CreateOrJoinScreen> createState() => _CreateOrJoinScreenState();
}

class _CreateOrJoinScreenState extends State<CreateOrJoinScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final you = state.roommates.where((r) => r.isYou).isNotEmpty ? state.roommates.firstWhere((r) => r.isYou) : null;
    // Landing screen only; join flow handled on dedicated JoinRoom screen.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                  child: AvatarChip(name: you?.name ?? 'You', imageUrl: you?.avatarUrl, size: 44),
                ),
              ),
              const SizedBox(height: 72),
              const Text(
                'Welcome Home',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.text,
                  letterSpacing: -0.7,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'For the things you share in life.',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.textMuted,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              _ActionTile(
                variant: _ActionTileVariant.primary,
                title: 'Create a space',
                subtitle: 'Start sharing responsibilities',
                onTap: () {
                  Navigator.of(context).pushNamed('/setupRoom', arguments: const SetupRoomArgs.create());
                },
                trailing: const _CircleIcon(
                  background: Colors.white,
                  child: Icon(Icons.add_rounded, size: 28, color: AppTheme.welcomeCta),
                ),
              ),
              const SizedBox(height: 14),
              _ActionTile(
                variant: _ActionTileVariant.secondary,
                title: 'Join a shared space',
                subtitle: 'Use an invite code',
                onTap: () => Navigator.of(context).pushNamed('/joinRoom'),
                trailing: const _CircleIcon(
                  background: AppTheme.primaryMuted,
                  child: Icon(Icons.qr_code_rounded, size: 22, color: AppTheme.welcomeCta),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/settings');
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Need help? ',
                      style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                      children: [
                        TextSpan(
                          text: 'View Guide',
                          style: TextStyle(color: AppTheme.welcomeCta, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ActionTileVariant { primary, secondary }

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.variant,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final _ActionTileVariant variant;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == _ActionTileVariant.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.welcomeCta : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isPrimary ? Colors.transparent : AppTheme.border),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppTheme.welcomeCta.withValues(alpha: 0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isPrimary ? Colors.white : AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: isPrimary ? Colors.white.withValues(alpha: 0.92) : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Center(child: child),
    );
  }
}

class SetupRoomArgs {
  const SetupRoomArgs._({required this.mode, this.inviteCode});

  final String mode; // create | join
  final String? inviteCode;

  const SetupRoomArgs.create() : this._(mode: 'create');

  factory SetupRoomArgs.join(String code) => SetupRoomArgs._(mode: 'join', inviteCode: code);
}
