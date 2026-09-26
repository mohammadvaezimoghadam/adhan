import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/constants/app_constants.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _shimmerController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final curvedAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entryController.forward().then((_) {
      if (mounted) {
        _shimmerController.repeat(reverse: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToHome();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _navigateToHome() async {
    if (mounted) {
      try {
        precacheImage(const AssetImage(AppConstants.ayahCardBgAsset), context);
        precacheImage(const AssetImage(AppConstants.splashBgAsset), context);
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      try {
        context.goNamed(mainNavigationRoute);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Calligraphy Background Image
          Image.asset(
            AppConstants.splashBgAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 44,
                                vertical: 22,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                gradient: RadialGradient(
                                  radius: 1.15,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.95), // White in center
                                    Colors.white.withValues(alpha: 0.85),
                                    Colors.white.withValues(alpha: 0.45),
                                    Colors.white.withValues(alpha: 0.08), // Fades to transparent at edges
                                  ],
                                  stops: const [0.0, 0.45, 0.80, 1.0],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    blurRadius: 32,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF0A3C30).withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  return ShaderMask(
                                    blendMode: BlendMode.srcATop,
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        begin: Alignment(_shimmerAnimation.value - 1.0, 0),
                                        end: Alignment(_shimmerAnimation.value, 0),
                                        colors: const [
                                          Color(0xFF0A3C30), // Deep Royal Emerald
                                          Color(0xFF0A3C30),
                                          Color(0xFFC5A059), // Radiant Gold Sheen
                                          Color(0xFF0A3C30),
                                          Color(0xFF0A3C30),
                                        ],
                                        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      AppConstants.appTitle,
                                      style: AppTypography.splashAppTitle.copyWith(
                                        color: const Color(0xFF0A3C30),
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFF0A3C30).withValues(alpha: 0.15),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Progress Indicator at Bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0F5A47),
                          ),
                        ),
                      ),
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

