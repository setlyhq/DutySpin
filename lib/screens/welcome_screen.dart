import 'package:flutter/material.dart';
import '../theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.welcomeBgTop, Colors.white, AppTheme.welcomeBgBottom],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final heroHeight = 260.0;
              final canCenter = constraints.maxHeight >= 720;

              Widget header() {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Image.asset(
                      'assets/app_name.png',
                      height: 38,
                      fit: BoxFit.contain,
                      semanticLabel: 'DutySpin',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'For the things you share in life.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: AppTheme.textMuted, height: 1.45, fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              }

              Widget footer() {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.welcomeCta.withValues(alpha: 0.32),
                              blurRadius: 22,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.welcomeCta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/continue');
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Get Started'),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/continue');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.welcomeCta,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }

              if (canCenter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      header(),
                      Expanded(
                        child: Center(
                          child: _WelcomeHeroCards(height: heroHeight),
                        ),
                      ),
                      footer(),
                    ],
                  ),
                );
              }

              // Small screens: keep it scrollable.
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: Column(
                    children: [
                      header(),
                      const SizedBox(height: 44),
                      _WelcomeHeroCards(height: heroHeight),
                      const SizedBox(height: 56),
                      footer(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeroCards extends StatefulWidget {
  const _WelcomeHeroCards({required this.height});

  final double height;

  @override
  State<_WelcomeHeroCards> createState() => _WelcomeHeroCardsState();
}

class _WelcomeHeroCardsState extends State<_WelcomeHeroCards> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _float = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              // Responsive sizing so all three cards remain visible on narrow screens.
              final baseCardW = (w - 44) / 3;
              final cardW = baseCardW.clamp(78.0, 160.0);
              final cardH = (cardW * 1.15).clamp(120.0, 200.0);

              final sideDx = (cardW * 0.95).clamp(86.0, 170.0);

              return AnimatedBuilder(
                animation: _float,
                builder: (context, child) {
                  final t = _float.value; // 0..1
                  final wave = (t - 0.5) * 2; // -1..1

                  final leftDy = 6.0 * wave;
                  final rightDy = -5.0 * wave;
                  final centerDy = 8.0 * wave;
                  final centerScale = 1.0 + (0.02 * t);

                  return SizedBox(
                    width: w,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Transform.translate(
                          offset: Offset(-sideDx, 10 + leftDy),
                          child: _HeroCard(
                            width: cardW,
                            height: cardH,
                            icon: Icons.shopping_cart_rounded,
                            iconColor: const Color(0xFF22C55E),
                            label: 'Groceries',
                            cornerIcon: Icons.check_circle,
                            cornerColor: const Color(0xFF22C55E),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(sideDx, 10 + rightDy),
                          child: _HeroCard(
                            width: cardW,
                            height: cardH,
                            icon: Icons.pets_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'Pet Care',
                            cornerIcon: Icons.refresh_rounded,
                            cornerColor: AppTheme.textMuted,
                          ),
                        ),
                        // Draw the center card last so it appears on top (matches reference).
                        Transform.translate(
                          offset: Offset(0, 24 + centerDy),
                          child: Transform.scale(
                            scale: centerScale,
                            child: _HeroCard(
                              width: cardW + 22,
                              height: cardH + 22,
                              icon: Icons.delete_rounded,
                              iconColor: const Color(0xFFF97316),
                              label: 'Trash',
                              cornerIcon: Icons.refresh_rounded,
                              cornerColor: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.width,
    required this.height,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.cornerIcon,
    required this.cornerColor,
  });

  final double width;
  final double height;
  final IconData icon;
  final Color iconColor;
  final String label;
  final IconData cornerIcon;
  final Color cornerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppTheme.text.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 18,
            child: Icon(cornerIcon, size: 22, color: cornerColor.withValues(alpha: 0.65)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 54, color: iconColor),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
