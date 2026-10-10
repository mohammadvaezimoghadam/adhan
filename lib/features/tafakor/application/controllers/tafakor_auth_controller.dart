import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/exceptions/failure.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../domain/entities/tafakor_auth_state.dart';
import '../../domain/entities/tafakor_user.dart';
import '../../domain/repositories/i_tafakor_auth_repository.dart';
import '../../infrastructure/repositories/tafakor_auth_repository_impl.dart';

final tafakorAuthControllerProvider =
    NotifierProvider<TafakorAuthController, TafakorAuthState>(
  TafakorAuthController.new,
);

final isTafakorAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(tafakorAuthControllerProvider).isAuthenticated;
});

final tafakorUserProvider = Provider<TafakorUser?>((ref) {
  return ref.watch(tafakorAuthControllerProvider).user;
});

final tafakorTokenProvider = Provider<String?>((ref) {
  return ref.watch(tafakorUserProvider)?.token;
});

class TafakorAuthController extends Notifier<TafakorAuthState> {
  late final ITafakorAuthRepository _repository;
  Timer? _countdownTimer;

  @override
  TafakorAuthState build() {
    _repository = ref.watch(tafakorAuthRepositoryProvider);
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });

    // 1. Immediately read synchronous state (guarantees zero-latency auth on startup / hot restart)
    final initialUser = _repository.getCurrentUserSync();
    if (initialUser != null) {
      _checkInitialAuth();
      return TafakorAuthState(user: initialUser);
    }

    // 2. Check initial persistent authentication state
    _checkInitialAuth();
    return const TafakorAuthState();
  }

  Future<void> _checkInitialAuth() async {
    final result = await _repository.getCurrentUser();
    result.when(
      (user) {
        if (user != null) {
          state = state.copyWith(user: user);
          // Sync live bot connection status from server in background
          refreshProfile();
        }
      },
      (failure) {
        // Silently keep unauthenticated
      },
    );
  }

  /// Refreshes user profile and bot connection statuses from server (GET /api/auth/profile/)
  Future<bool> refreshProfile() async {
    final result = await _repository.refreshProfile();
    return result.when(
      (updatedUser) {
        state = state.copyWith(user: updatedUser);
        return true;
      },
      (failure) {
        if (failure.statusCode == 401) {
          debugPrint('[TafakorAuthController] Token expired on refreshProfile (401). Resetting auth state.');
          logout();
        }
        return false;
      },
    );
  }

  /// Converts Persian and Arabic digits to English
  String normalizeDigits(String input) {
    return input.toEnglishDigit().trim();
  }

  /// Request OTP verification code for mobile number
  Future<bool> requestOtp(String inputPhone) async {
    final phone = normalizeDigits(inputPhone);
    debugPrint('[TafakorAuthController] requestOtp: input="$inputPhone", normalized="$phone"');
    final phoneRegex = RegExp(r'^09\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      state = state.copyWith(
        error: const Failure(message: 'شماره موبایل باید ۱۱ رقم و با ۰۹ شروع شود.'),
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.requestOtp(phone);

    return result.when(
      (success) {
        state = state.copyWith(
          isLoading: false,
          isCodeSent: true,
          phone: phone,
          error: null,
          resendCountdown: 120,
        );
        _startCountdown();
        return true;
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
        return false;
      },
    );
  }

  /// Verify entered 4-digit OTP
  Future<bool> verifyOtp(String inputOtp) async {
    final phone = state.phone;
    if (phone == null || phone.isEmpty) {
      state = state.copyWith(
        error: const Failure(message: 'شماره موبایل مشخص نیست. لطفاً مجدداً شماره را وارد کنید.'),
      );
      return false;
    }

    final otp = normalizeDigits(inputOtp);
    if (otp.length != 4) {
      state = state.copyWith(
        error: const Failure(message: 'کد تأیید باید ۴ رقم باشد.'),
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.verifyOtp(phone, otp);

    return result.when(
      (user) {
        _countdownTimer?.cancel();
        state = state.copyWith(
          isLoading: false,
          isCodeSent: false,
          user: user,
          error: null,
          resendCountdown: 0,
        );
        return true;
      },
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
        return false;
      },
    );
  }

  /// Resends OTP if timer has expired
  Future<bool> resendOtp() async {
    if (state.resendCountdown > 0 || state.phone == null) return false;
    return requestOtp(state.phone!);
  }

  /// Back to change phone number
  void resetToPhoneInput() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      isCodeSent: false,
      error: null,
      resendCountdown: 0,
    );
  }

  /// Clears any active error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Logout and clear storage
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    _countdownTimer?.cancel();
    state = const TafakorAuthState();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.resendCountdown > 1) {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      } else {
        timer.cancel();
        state = state.copyWith(resendCountdown: 0);
      }
    });
  }
}
