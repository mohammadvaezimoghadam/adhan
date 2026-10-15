import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/constants/app_constants.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_colors.dart';
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
    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
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
      } catch (_) {}
    }

    // انیمیشن سریع اسپلش بدون توقف روی شبکه (بررسی آپدیت در هوم انجام می‌شود)
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (mounted) {
      try {
        context.goNamed(mainNavigationRoute);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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
                                  AppColors.primary,
                                  AppColors.primary,
                                  AppColors.primaryContainer,
                                  AppColors.primary,
                                  AppColors.primary,
                                ],
                                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                              ).createShader(bounds);
                            },
                            child: Text(
                              AppConstants.appTitle,
                              style: AppTypography.splashAppTitle.copyWith(
                                color: AppColors.primary,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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

            // Bottom Area: Progress Indicator & Group Brand
            Positioned(
              left: 0,
              right: 0,
              bottom: 34,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'گروه تفکر',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withValues(alpha: 0.85),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
