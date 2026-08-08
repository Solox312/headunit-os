import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../services/settings_storage_service.dart';
import 'onboarding_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  double _bootProgress = 0.0;
  String _bootStatus = "INITIALIZING SYSTEM KERNEL...";
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.4, 0.9, curve: Curves.easeInOut)),
    );

    _animController.forward();
    _startBootSequence();
  }

  void _startBootSequence() {
    const totalTicks = 50;
    int currentTick = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      currentTick++;
      setState(() {
        _bootProgress = currentTick / totalTicks;

        if (_bootProgress < 0.30) {
          _bootStatus = "INITIALIZING SYSTEM KERNEL...";
        } else if (_bootProgress < 0.60) {
          _bootStatus = "LOADING AUDIO & BLUETOOTH DRIVERS...";
        } else if (_bootProgress < 0.85) {
          _bootStatus = "CONNECTING VEHICLE TELEMETRY...";
        } else {
          _bootStatus = "HEADUNIT OS READY • LAUNCHING DASHBOARD";
        }
      });

      if (currentTick >= totalTicks) {
        timer.cancel();
        _onBootFinished();
      }
    });
  }

  void _onBootFinished() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      final bool onboardingCompleted = await SettingsStorageService().loadOnboardingCompleted();
      if (!mounted) return;

      final targetWidget = onboardingCompleted ? const MainNavigationScreen() : const OnboardingScreen();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secondaryAnim) => targetWidget,
          transitionsBuilder: (context, anim, secondaryAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF04070C),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ambient Glow
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: [
                      const Color(0xFF101826).withOpacity(_glowAnimation.value),
                      const Color(0xFF0A0F18),
                      const Color(0xFF04070C),
                    ],
                  ),
                ),
              );
            },
          ),

          // Main SVG Vector Emblem & Wordmark Animation
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: SvgPicture.asset(
                      'assets/images/headunit_os_splash.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),

          // Dynamic Boot Progress Bar Overlay
          Positioned(
            bottom: size.height * 0.12,
            child: Column(
              children: [
                // Custom Progress Bar Track
                Container(
                  width: 320,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF182233),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      width: 320 * _bootProgress,
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AutomotiveColors.electricCyan,
                            AutomotiveColors.dongleViolet,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AutomotiveColors.electricCyan.withOpacity(0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Boot Status Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _bootStatus,
                    key: ValueKey<String>(_bootStatus),
                    style: GoogleFonts.inter(
                      color: AutomotiveColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
