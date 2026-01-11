import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'continue_to_whose_turn_screen.dart';
import '../services/auth_service.dart';

class OtpVerifyArgs {
  const OtpVerifyArgs({
    required this.method,
    required this.destination,
    required this.verificationId,
    this.resendToken,
    this.webConfirmationResult,
  });

  final AuthMethod method;
  final String destination;
  final String verificationId;
  final int? resendToken;
  final ConfirmationResult? webConfirmationResult;
}

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key, required this.args});

  final OtpVerifyArgs args;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final TextEditingController code = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  String? error;
  bool _isVerifying = false;
  DateTime? _lastResendAt;

  bool get _canResend {
    final last = _lastResendAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= const Duration(seconds: 30);
  }

  Future<void> _resendCode() async {
    setState(() => _lastResendAt = DateTime.now());

    try {
      if (kIsWeb) {
        // Web platform - resend via signInWithPhoneNumber
        final auth = FirebaseAuth.instance;
        final confirmationResult = await auth.signInWithPhoneNumber(widget.args.destination);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent')),
        );
        // Update the confirmation result
        Navigator.of(context).pushReplacementNamed(
          '/otpVerify',
          arguments: ({
            'method': widget.args.method,
            'destination': widget.args.destination,
            'verificationId': 'web',
            'webConfirmationResult': confirmationResult,
          }),
        );
      } else {
        // Mobile platforms
        final authService = AuthService();
        await authService.verifyPhoneNumber(
          phoneNumber: widget.args.destination,
          verificationCompleted: (credential) async {
            if (!mounted) return;
            final appState = context.read<AppState>();
            appState.setAuthenticated(true);
            appState.setOnboardingComplete(true);

            // Resolve spaces/rooms in the background; navigate immediately
            // so the user doesn't sit on the OTP screen.
            // ignore: discarded_futures
            appState.decidePostLoginDestination();

            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (r) => false,
            );
          },
          verificationFailed: (exception) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Verification failed: ${exception.message}')),
            );
          },
          codeSent: (verificationId, resendToken) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New code sent')),
            );
            // Update the verification ID
            Navigator.of(context).pushReplacementNamed(
              '/otpVerify',
              arguments: ({
                'method': widget.args.method,
                'destination': widget.args.destination,
                'verificationId': verificationId,
                'resendToken': resendToken,
              }),
            );
          },
          codeAutoRetrievalTimeout: (verificationId) {},
          timeout: const Duration(seconds: 60),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _verifyCode() async {
    final smsCode = code.text.trim();
    if (smsCode.length != 6) return;

    setState(() {
      _isVerifying = true;
      error = null;
    });

    try {
      if (kIsWeb && widget.args.webConfirmationResult != null) {
        // Web platform - use ConfirmationResult
        await widget.args.webConfirmationResult!.confirm(smsCode);
      } else {
        // Mobile platforms - use AuthService
        final authService = AuthService();
        await authService.signInWithPhoneOtp(
          verificationId: widget.args.verificationId,
          smsCode: smsCode,
        );
      }

      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.setAuthenticated(true);
      appState.setOnboardingComplete(true);

      // Run the heavier post-login work (room discovery, joined spaces)
      // without blocking navigation so landing feels snappy.
      // ignore: discarded_futures
      appState.decidePostLoginDestination();

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString();
      String friendly;
      if (msg.contains('too-many-requests')) {
        friendly = 'Too many attempts. Please wait a bit before trying again.';
      } else if (msg.contains('invalid-verification-code') || msg.contains('invalid-verification')) {
        friendly = 'That code doesn\'t look right. Double-check and try again.';
      } else if (msg.contains('invalid-app-credential') ||
          msg.contains('reCAPTCHA') ||
          msg.contains('unauthorized')) {
        // Common on web when reCAPTCHA / phone auth is not fully configured.
        friendly =
            'We couldn\'t verify this code because phone sign-in needs configuration in Firebase (reCAPTCHA).\nFor now, try a different login method or use a Firebase test phone number.';
      } else {
        friendly = 'We couldn\'t verify that code. Please try again.';
      }

      setState(() {
        _isVerifying = false;
        error = friendly;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendly),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeFocusNode.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = code.text.trim();
    final canVerify = c.length == 6 && !_isVerifying;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.text),
                  onPressed: _isVerifying ? null : () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We sent a 6-digit code to ${widget.args.destination}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Custom 6-digit code row matching the design.
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            final scope = FocusScope.of(context);
                            scope.requestFocus(_codeFocusNode);
                          },
                          child: SizedBox(
                            height: 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                final digit = index < c.length ? c[index] : '';
                                return Container(
                                  width: 32,
                                  margin: EdgeInsets.only(right: index == 5 ? 0 : 12),
                                  alignment: Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        digit,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.text,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 2,
                                        color: index == c.length && c.length < 6
                                            ? AppTheme.text
                                            : const Color(0xFFE0E5F0),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        // Hidden TextField that actually captures input.
                        Offstage(
                          child: TextField(
                            controller: code,
                            focusNode: _codeFocusNode,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            autofocus: true,
                            enabled: !_isVerifying,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {
                              error = null;
                            }),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _canResend ? _resendCode : null,
                          child: Text(
                            _canResend ? 'Resend code' : 'Resend in 30s',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.welcomeCta,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF374155),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            onPressed: canVerify ? _verifyCode : null,
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify'),
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
