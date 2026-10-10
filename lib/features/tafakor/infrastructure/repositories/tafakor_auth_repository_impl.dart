import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/exceptions/failure.dart';
import '../../../../common/mixins/dio_exception_mapper.dart';
import '../../domain/entities/tafakor_user.dart';
import '../../domain/repositories/i_tafakor_auth_repository.dart';
import '../datasources/tafakor_local_data_source.dart';
import '../datasources/tafakor_remote_data_source.dart';

final tafakorAuthRepositoryProvider = Provider<ITafakorAuthRepository>((ref) {
  final remote = ref.watch(tafakorRemoteDataSourceProvider);
  final local = ref.watch(tafakorLocalDataSourceProvider);
  return TafakorAuthRepositoryImpl(remote, local);
});

class TafakorAuthRepositoryImpl
    with DioExceptionMapper
    implements ITafakorAuthRepository {
  final TafakorRemoteDataSource _remote;
  final TafakorLocalDataSource _local;

  TafakorAuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Result<bool, Failure>> requestOtp(String phone) async {
    try {
      debugPrint('[TafakorAuth] Requesting OTP for phone: $phone');
      final success = await _remote.requestOtp(phone);
      debugPrint('[TafakorAuth] OTP requested successfully: $success');
      return Success(success);
    } on DioException catch (e, stackTrace) {
      debugPrint('[TafakorAuth] DioException type: ${e.type}, msg: ${e.message}, status: ${e.response?.statusCode}, data: ${e.response?.data}, error: ${e.error}');
      return Error(_extractBackendErrorOrMap(e, stackTrace));
    } catch (e, stackTrace) {
      debugPrint('[TafakorAuth] Unexpected error during requestOtp: $e');
      return Error(Failure(
        message: AppConstants.unexpectedError,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<TafakorUser, Failure>> verifyOtp(
      String phone, String otp) async {
    try {
      debugPrint('[TafakorAuth] Verifying OTP: $otp for phone: $phone');
      final dto = await _remote.verifyOtp(phone, otp);
      final user = dto.toDomain();
      await _local.saveUser(user);
      debugPrint('[TafakorAuth] Verified successfully, user: ${user.phone}');
      return Success(user);
    } on DioException catch (e, stackTrace) {
      debugPrint('[TafakorAuth] DioException during verifyOtp: ${e.message}, status: ${e.response?.statusCode}, data: ${e.response?.data}');
      return Error(_extractBackendErrorOrMap(e, stackTrace));
    } catch (e, stackTrace) {
      debugPrint('[TafakorAuth] Unexpected error during verifyOtp: $e');
      return Error(Failure(
        message: AppConstants.unexpectedError,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  TafakorUser? getCurrentUserSync() {
    return _local.getUserSync();
  }

  @override
  Future<Result<TafakorUser?, Failure>> getCurrentUser() async {
    try {
      final user = await _local.getUser();
      return Success(user);
    } catch (e, stackTrace) {
      return Error(Failure(
        message: AppConstants.tafakorUserFetchError,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<TafakorUser, Failure>> refreshProfile() async {
    try {
      final token = await _local.getToken();
      if (token == null || token.isEmpty) {
        return const Error(Failure(message: AppConstants.tafakorUserNotLoggedIn));
      }
      debugPrint('[TafakorAuth] Refreshing profile from server (GET /api/auth/profile/)...');
      final dto = await _remote.getProfile();
      final updatedUser = dto.toDomain(token: token);
      await _local.saveUser(updatedUser);
      debugPrint(
        '[TafakorAuth] Profile refreshed: phone=${updatedUser.phone}, telegram=${updatedUser.isTelegramConnected}, bale=${updatedUser.isBaleConnected}',
      );
      return Success(updatedUser);
    } on DioException catch (e, stackTrace) {
      debugPrint(
        '[TafakorAuth] DioException during refreshProfile: ${e.message}, status: ${e.response?.statusCode}, data: ${e.response?.data}',
      );
      return Error(_extractBackendErrorOrMap(e, stackTrace));
    } catch (e, stackTrace) {
      debugPrint('[TafakorAuth] Unexpected error during refreshProfile: $e');
      return Error(Failure(
        message: AppConstants.tafakorProfileFetchError,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> logout() async {
    try {
      await _local.clear();
      return const Success(null);
    } catch (e, stackTrace) {
      return Error(Failure(
        message: AppConstants.tafakorLogoutError,
        stackTrace: stackTrace,
      ));
    }
  }

  Failure _extractBackendErrorOrMap(DioException e, StackTrace stackTrace) {
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      const prioritizedKeys = [
        'error',
        'otp',
        'phone',
        'detail',
        'message',
        'non_field_errors',
      ];
      for (final key in prioritizedKeys) {
        if (responseData.containsKey(key) && responseData[key] != null) {
          final val = responseData[key];
          final msg = val is List ? val.join('، ') : val.toString();
          return Failure(
            message: msg,
            statusCode: e.response?.statusCode,
            exception: e,
            stackTrace: stackTrace,
          );
        }
      }

      final firstEntry = responseData.entries.firstOrNull;
      if (firstEntry != null && firstEntry.value != null) {
        final val = firstEntry.value;
        final msg = val is List ? val.join('، ') : val.toString();
        return Failure(
          message: msg,
          statusCode: e.response?.statusCode,
          exception: e,
          stackTrace: stackTrace,
        );
      }
    }
    return mapDioExceptionToFailure(e, stackTrace);
  }
}
