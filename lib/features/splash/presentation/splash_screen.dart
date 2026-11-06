import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_providers.dart';
import '../../../app/branding/daram_logo.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/localization/fa_strings.dart';

/// Animated branded launch screen that also waits for settings to load.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), _next);
  }

  Future<void> _next() async {
    if (!mounted) return;
    final settings = await ref.read(settingsControllerProvider.future);
    if (!mounted) return;
    context.go(settings.onboardingComplete ? '/chat' : '/onboarding');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Scaffold(
      backgroundColor: const Color(0xFF070B13),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DaramAura(intensity: 1.1),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.1,
                colors: [Color(0x22322A7A), Color(0x00070B13)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                DaramMark(size: 104)
                    .animate()
                    .fadeIn(duration: 520.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.82, 0.82),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),
                Text(
                      'دارام',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                    )
                    .animate()
                    .fadeIn(delay: 220.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                Text(
                  FaStrings.tagline,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.68)),
                ).animate().fadeIn(delay: 380.ms, duration: 500.ms),
                const Spacer(flex: 5),
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.gradientEnd,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 28),
                Text(
                  'DARAM',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.35),
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
