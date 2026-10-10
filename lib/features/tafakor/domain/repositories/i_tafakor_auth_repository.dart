import 'package:multiple_result/multiple_result.dart';
import '../../../../common/exceptions/failure.dart';
import '../entities/tafakor_user.dart';

abstract class ITafakorAuthRepository {
  Future<Result<bool, Failure>> requestOtp(String phone);
  Future<Result<TafakorUser, Failure>> verifyOtp(String phone, String otp);
  Future<Result<TafakorUser?, Failure>> getCurrentUser();
  TafakorUser? getCurrentUserSync();
  Future<Result<TafakorUser, Failure>> refreshProfile();
  Future<Result<void, Failure>> logout();
}
