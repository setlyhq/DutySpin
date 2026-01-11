import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/avatar_chip.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'create_or_join_screen.dart';

class SetupRoomScreen extends StatefulWidget {
  const SetupRoomScreen({super.key, required this.args});

  final SetupRoomArgs args;

  @override
  State<SetupRoomScreen> createState() => _SetupRoomScreenState();
}

class _SetupRoomScreenState extends State<SetupRoomScreen> {
  final TextEditingController roomName = TextEditingController();
  final TextEditingController roommateName = TextEditingController();
  final TextEditingController roommateEmail = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    roomName.dispose();
    roommateName.dispose();
    roommateEmail.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // Avoid notifying listeners during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<AppState>();

      // This screen is used both during onboarding and later from Settings.
      // Avoid unintentionally recreating/joining a room if one already exists.
      if (state.room == null) {
        if (widget.args.mode == 'create') {
          await state.createRoom(state.room?.name ?? 'My Home');
        } else {
          await state.joinRoom(widget.args.inviteCode ?? '');
        }
      }

      if (!mounted) return;
      roomName.text = state.room?.name ?? '';
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roommates = state.roommates;
    final canContinue = roomName.text.trim().isNotEmpty && roommates.isNotEmpty;

    return Scaffold
    (
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Top bar: back arrow and step indicator
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.text),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: AppTheme.welcomeCta,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'STEP 1 OF 3',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        "Let's name your space",
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                          height: 1.1,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Give your home a nickname and invite your roommates.',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textMuted,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'ROOM NAME',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: roomName,
                        decoration: InputDecoration(
                          hintText: 'Highland View',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: const BorderSide(color: AppTheme.border, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: const BorderSide(color: AppTheme.welcomeCta, width: 2),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (t) => context.read<AppState>().setRoomName(t),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'WHO LIVES HERE?',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: roommates.length + 1,
                          separatorBuilder: (context, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            if (index == roommates.length) {
                              // Add placeholder chip
                              return Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(Icons.group_add_rounded, color: AppTheme.textMuted),
                              );
                            }
                            final rm = roommates[index];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AvatarChip(name: rm.name, size: 64, imageUrl: rm.avatarUrl),
                                if (!rm.isYou)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: GestureDetector(
                                      onTap: () => context.read<AppState>().removeRoommate(rm.id),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        // Avoid stretching to infinite height inside the scroll view on web.
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  controller: roommateName,
                                  decoration: InputDecoration(
                                    hintText: 'Full Name',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      borderSide: const BorderSide(color: AppTheme.border, width: 1.3),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      borderSide: const BorderSide(color: AppTheme.welcomeCta, width: 2),
                                    ),
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: roommateEmail,
                                  decoration: InputDecoration(
                                    hintText: 'Email (optional)',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      borderSide: const BorderSide(color: AppTheme.border, width: 1.3),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(28),
                                      borderSide: const BorderSide(color: AppTheme.welcomeCta, width: 2),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  textCapitalization: TextCapitalization.none,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 88,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.welcomeCta,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 24),
                              ),
                              onPressed: () async {
                                final name = roommateName.text.trim();
                                final email = roommateEmail.text.trim();
                                if (name.isEmpty) return;
                                await context
                                    .read<AppState>()
                                    .addRoommate(name: name, email: email.isEmpty ? null : email);
                                roommateName.clear();
                                roommateEmail.clear();
                                setState(() {});
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add_rounded, size: 28),
                                  SizedBox(height: 6),
                                  Text(
                                    'ADD',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  onPressed: canContinue
                      ? () {
                          Navigator.of(context).pushNamed('/addChores');
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
