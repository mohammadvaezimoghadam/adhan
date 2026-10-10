import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/constants/app_constants.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ota_update/application/controllers/ota_update_controller.dart';
import '../../../ota_update/presentation/widgets/ota_update_dialog.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _shimmerController;
  bool _isForceUpdating = false;

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

    debugPrint('🚀 [Splash/OTA] Checking update...');
    final splashMinWait = Future.delayed(const Duration(milliseconds: 1200));
    final updateFuture = ref
        .read(otaUpdateControllerProvider.notifier)
        .checkForUpdate()
        .timeout(const Duration(milliseconds: 2500), onTimeout: () => false);

    // Parallel wait for splash animation and update check
    await Future.wait([splashMinWait, updateFuture]);
    if (!mounted) return;

    final otaState = ref.read(otaUpdateControllerProvider);
    // If force update detected, show loading text and apply update
    if (otaState.hasUpdate && otaState.patch?.isForce == true) {
      debugPrint('🛑 [Splash/OTA] Force update detected!');
      if (mounted) {
        setState(() {
          _isForceUpdating = true;
        });
      }

      if (otaState.patch!.isNativeApk) {
        // برای نسخه نصبی APK، دیالوگ مستقیم را نشان می‌دهیم
        await OtaUpdateDialog.show(context, isForce: true);
        return;
      }

      // برای پچ دارت اجباری: دانلود و اعمال مستقیم در اسپلش با متن «در حال به‌روزرسانی...»
      final success = await ref
          .read(otaUpdateControllerProvider.notifier)
          .startDownloadAndApply();

      if (success) {
        debugPrint('🔄 [Splash/OTA] Force patch downloaded and ready. Restarting app...');
        await OtaUpdateController.restartApp();
        return;
      } else {
        if (mounted) {
          await OtaUpdateDialog.show(context, isForce: true);
        }
        return;
      }
    }

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
                        _isForceUpdating ? 'در حال به‌روزرسانی...' : 'گروه تفکر',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: _isForceUpdating ? 14 : 13,
                          fontWeight: _isForceUpdating
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: _isForceUpdating
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.85),
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
