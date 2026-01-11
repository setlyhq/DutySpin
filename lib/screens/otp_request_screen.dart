import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';

import '../theme.dart';
import 'continue_to_whose_turn_screen.dart';
import '../state/app_state.dart';
import '../services/auth_service.dart';

class OtpRequestScreen extends StatefulWidget {
  const OtpRequestScreen({super.key, required this.method});

  final AuthMethod method;

  @override
  State<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends State<OtpRequestScreen> {
  final TextEditingController controller = TextEditingController();
  bool _isLoading = false;

  // Selected country for dial code; defaults to US.
  String _dialCode = '+1';
  String _flagEmoji = '🇺🇸';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final value = controller.text.trim();
    if (value.isEmpty) return;

    // Format phone number with selected country dial code
    String raw = value.replaceAll(RegExp(r'[^0-9+]'), '');
    String phoneNumber;
    if (raw.startsWith('+')) {
      phoneNumber = raw;
    } else {
      // Remove any leading zeros for local part
      raw = raw.replaceFirst(RegExp(r'^0+'), '');
      phoneNumber = '$_dialCode$raw';
    }

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // Web platform - configure invisible reCAPTCHA
        final auth = FirebaseAuth.instance;
        
        try {
          final confirmationResult = await auth.signInWithPhoneNumber(phoneNumber);
          
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code sent - use 123456 for test number')),
          );
          Navigator.of(context).pushNamed(
            '/otpVerify',
            arguments: ({
              'method': widget.method,
              'destination': phoneNumber,
              'verificationId': 'web',
              'webConfirmationResult': confirmationResult,
            }),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          
          // If reCAPTCHA fails or rate limited, show helpful error
          final errorMessage = e.toString().contains('too-many-requests')
              ? 'Too many attempts. Please use test number +1 913-999-3300 with code 123456, or try again in 1 hour.'
              : e.toString().contains('auth/invalid-app-credential') ||
                      e.toString().contains('unauthorized') ||
                      e.toString().contains('reCAPTCHA')
                  ? 'Phone auth needs configuration. Use test number +1 913-999-3300 with code 123456 for now.'
                  : 'Error: ${e.toString()}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 8),
            ),
          );
        }
      } else {
        // Mobile platforms - use verifyPhoneNumber
        final authService = AuthService();
        
        await authService.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (credential) async {
            // Auto-resolved (Android only)
            if (!mounted) return;
            final appState = context.read<AppState>();
            appState.setAuthenticated(true);
            appState.setOnboardingComplete(true);

            // Resolve spaces/rooms without blocking navigation so the
            // transition after auto-verification feels instant.
            // ignore: discarded_futures
            appState.decidePostLoginDestination();

            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (r) => false,
            );
          },
          verificationFailed: (exception) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${exception.message}')),
            );
          },
          codeSent: (verificationId, resendToken) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code sent')),
            );
            Navigator.of(context).pushNamed(
              '/otpVerify',
              arguments: ({
                'method': widget.method,
                'destination': phoneNumber,
                'verificationId': verificationId,
                'resendToken': resendToken,
              }),
            );
          },
          codeAutoRetrievalTimeout: (verificationId) {
            // Timeout reached, user needs to manually enter code
          },
          timeout: const Duration(seconds: 60),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = controller.text.trim();
    final canContinue = value.length >= 7;
    final showError = value.isNotEmpty && !canContinue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.text),
                  onPressed: _isLoading ? null : () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMuted,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Enter your phone',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "We'll send you a quick code to log in.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textMuted,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Phone number row: flag + country code + input with bottom divider
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE1E7F0),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        showCountryPicker(
                                          context: context,
                                          showPhoneCode: true,
                                          onSelect: (Country country) {
                                            setState(() {
                                              _dialCode = '+${country.phoneCode}';
                                              _flagEmoji = country.flagEmoji;
                                            });
                                          },
                                        );
                                      },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _flagEmoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _dialCode,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Container(
                                width: 1,
                                height: 24,
                                color: const Color(0xFFE1E7F0),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  keyboardType: TextInputType.phone,
                                  textCapitalization: TextCapitalization.none,
                                  enabled: !_isLoading,
                                  decoration: const InputDecoration(
                                    isCollapsed: true,
                                    border: InputBorder.none,
                                    hintText: '555 000-0000',
                                    hintStyle: TextStyle(
                                      fontSize: 18,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppTheme.text,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showError) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'Enter a valid phone number.',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.welcomeCta,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shadowColor: AppTheme.welcomeCta.withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            onPressed: (canContinue && !_isLoading) ? _sendCode : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Send code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
