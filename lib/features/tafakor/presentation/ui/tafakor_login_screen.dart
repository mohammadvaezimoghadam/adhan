import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/tafakor_auth_controller.dart';
import '../../domain/entities/tafakor_auth_state.dart';

class TafakorLoginScreen extends ConsumerStatefulWidget {
  const TafakorLoginScreen({super.key});

  @override
  ConsumerState<TafakorLoginScreen> createState() => _TafakorLoginScreenState();
}

class _TafakorLoginScreenState extends ConsumerState<TafakorLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  final _smartAuth = SmartAuth.instance;

  @override
  void dispose() {
    _smartAuth.removeUserConsentApiListener();
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _listenForSms() async {
    try {
      final res = await _smartAuth.getSmsWithUserConsentApi();
      if (res.hasData && res.data?.code != null) {
        if (mounted) {
          final code = res.data!.code!;
          _otpController.text = code;
          // Pinput triggers onCompleted automatically upon setting text
        }
      }
    } catch (e) {
      debugPrint('[SmartAuth] Error listening for SMS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final authState = ref.watch(tafakorAuthControllerProvider);
    final controller = ref.read(tafakorAuthControllerProvider.notifier);

    ref.listen<TafakorAuthState>(tafakorAuthControllerProvider, (prev, next) {
      if (prev?.isCodeSent != true && next.isCodeSent) {
        _listenForSms();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _otpFocus.requestFocus();
        });
      }

      if (next.error != null && next.error != prev?.error) {
        HapticFeedback.heavyImpact();
        AppSnackBar.showError(context, next.error!.message);
      }

      if (prev?.user == null && next.user != null) {
        HapticFeedback.mediumImpact();
        AppSnackBar.showSuccess(context, 'ورود با موفقیت انجام شد');
        Navigator.of(context).pop(true);
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'بازگشت',
            icon: Icon(
              CupertinoIcons.chevron_forward,
              size: 22,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background calligraphy image
            Positioned.fill(
              child: Image.asset(
                AppConstants.splashBgAsset,
                fit: BoxFit.cover,
              ),
            ),
            // Soft subtle blur and gentle translucent tint so the background is clearly visible
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.20),
                ),
              ),
            ),
            // Foreground Content
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        !authState.isCodeSent ? 'ورود به تفکر' : 'کد تأیید',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      8.vSpace,
                      if (!authState.isCodeSent)
                        Text(
                          'شماره موبایل خود را وارد کنید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ارسال‌شده به ${(authState.phone ?? "").toPersianDigit()}',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            8.hSpace,
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _smartAuth.removeUserConsentApiListener();
                                _otpController.clear();
                                controller.resetToPhoneInput();
                              },
                              child: Text(
                                'ویرایش',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      32.vSpace,

                      // Step 1: Phone input
                      if (!authState.isCodeSent) ...[
                        _buildPhoneStep(context, authState, controller, colorScheme, colors, isDark),
                      ] else ...[
                        // Step 2: OTP input
                        _buildOtpStep(context, authState, controller, colorScheme, colors, isDark),
                      ],
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

  Widget _buildPhoneStep(
    BuildContext context,
    TafakorAuthState state,
    TafakorAuthController controller,
    ColorScheme colorScheme,
    dynamic colors,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '۰۹xxxxxxxxx',
            hintStyle: TextStyle(
              fontFamily: AppTypography.fontFamily,
              letterSpacing: 1.0,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.40),
            ),
            filled: true,
            fillColor: colors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
          onSubmitted: (_) {
            if (!state.isLoading) {
              controller.requestOtp(_phoneController.text);
            }
          },
        ),
        20.vSpace,
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: state.isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  controller.requestOtp(_phoneController.text);
                },
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'دریافت کد',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(
    BuildContext context,
    TafakorAuthState state,
    TafakorAuthController controller,
    ColorScheme colorScheme,
    dynamic colors,
    bool isDark,
  ) {
    final minutes = (state.resendCountdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.resendCountdown % 60).toString().padLeft(2, '0');
    final formattedTimer = '$minutes:$seconds'.toPersianDigit();

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder, width: 1),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary, width: 1.8),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            controller: _otpController,
            focusNode: _otpFocus,
            length: 4,
            autofocus: true,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            keyboardType: TextInputType.number,
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            onCompleted: (pin) {
              if (!state.isLoading) {
                HapticFeedback.mediumImpact();
                controller.verifyOtp(pin);
              }
            },
          ),
        ),
        20.vSpace,
        Center(
          child: state.resendCountdown > 0
              ? Text(
                  '$formattedTimer تا ارسال مجدد',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _smartAuth.removeUserConsentApiListener();
                          controller.resendOtp();
                          _listenForSms();
                        },
                  child: Text(
                    'ارسال مجدد کد',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
        ),
        20.vSpace,
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: state.isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  controller.verifyOtp(_otpController.text);
                },
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'ورود',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
