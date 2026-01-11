import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../components/avatar_chip.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _avatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameController.text.isNotEmpty) return;
    final state = context.read<AppState>();
    final you = state.roommates.where((r) => r.isYou).isNotEmpty
        ? state.roommates.firstWhere((r) => r.isYou)
        : null;
    if (_nameController.text.isEmpty) {
      _nameController.text = you?.name ?? '';
    }
    _avatarUrl ??= you?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final appState = context.read<AppState>();
    setState(() => _saving = true);
    final nav = Navigator.of(context);

    await appState.updateDisplayName(name);
    await appState.updateAvatarUrl(_avatarUrl);

    if (!context.mounted) return;
    setState(() => _saving = false);
    // Safe to use cached nav/messenger after async gap.
    nav.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final you = state.roommates.where((r) => r.isYou).isNotEmpty
        ? state.roommates.firstWhere((r) => r.isYou)
        : null;
    final user = FirebaseAuth.instance.currentUser;
    final contact = user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : (user?.phoneNumber?.trim().isNotEmpty == true ? user!.phoneNumber!.trim() : 'Not available');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding
          (padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ListView(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.text),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Profile picture',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.text,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.photo_library_rounded, color: AppTheme.text),
                                  title: const Text('Choose from gallery'),
                                  onTap: () async {
                                    Navigator.of(ctx).pop();
                                    final picker = ImagePicker();
                                    final messenger = ScaffoldMessenger.of(ctx);
                                    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
                                    if (picked == null) return;

                                    try {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user == null) return;
                                      final storageRef = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
                                      await storageRef.putData(await picked.readAsBytes());
                                      final url = await storageRef.getDownloadURL();
                                      if (!mounted) return;
                                      setState(() {
                                        _avatarUrl = url;
                                      });
                                    } catch (_) {
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Could not upload photo. Please try again.')),
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.person_off_rounded, color: AppTheme.text),
                                  title: const Text('Use initials avatar'),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    setState(() {
                                      _avatarUrl = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: AvatarChip(
                    name: _nameController.text.isNotEmpty ? _nameController.text : (you?.name ?? 'You'),
                    imageUrl: _avatarUrl,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppTheme.border, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppTheme.welcomeCta, width: 2.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: contact),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceMuted,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppTheme.border, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppTheme.border, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Used for login',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.welcomeCta,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
