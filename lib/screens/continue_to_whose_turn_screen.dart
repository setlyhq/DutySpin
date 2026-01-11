import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../state/app_state.dart';
import '../services/auth_service.dart';
import '../utils/e2e_config.dart';

enum AuthMethod { google, phone }

class ContinueToWhoseTurnScreen extends StatefulWidget {
  const ContinueToWhoseTurnScreen({super.key});

  @override
  State<ContinueToWhoseTurnScreen> createState() => _ContinueToWhoseTurnScreenState();
}

class _ContinueToWhoseTurnScreenState extends State<ContinueToWhoseTurnScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.signInWithGoogle();
      
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.setAuthenticated(true);
      appState.setOnboardingComplete(true);

      // Kick off post-login room/space resolution in the background so
      // navigation feels instant. The main shell will react as state
      // (room, joinedRooms) is hydrated.
      // ignore: discarded_futures
      appState.decidePostLoginDestination();

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAsTestUser() async {
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      await appState.seedForE2eTests();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main',
        (r) => false,
        arguments: 0,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.text),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMuted,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Image.asset(
                        'assets/app_name.png',
                        height: 22,
                        fit: BoxFit.contain,
                        semanticLabel: 'DutySpin',
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Continue to DutySpin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Choose your sign-in method",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textMuted,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.text,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          icon: Image.asset(
                            'assets/google_logo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 32),
                          ),
                          label: const Text('Continue with Google'),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.text,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          icon: const Icon(Icons.phone_iphone_rounded),
                          label: const Text('Continue with Phone number'),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pushNamed(
                                    '/otpRequest',
                                    arguments: AuthMethod.phone,
                                  );
                                },
                        ),
                      ),
                      if (kE2eTests) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            key: const ValueKey('e2e-test-login'),
                            onPressed: _isLoading ? null : _signInAsTestUser,
                            child: const Text(
                              'Continue as Test user',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ],
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
