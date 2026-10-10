import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../common/exceptions/failure.dart';
import 'tafakor_user.dart';

part 'tafakor_auth_state.freezed.dart';

@freezed
abstract class TafakorAuthState with _$TafakorAuthState {
  const factory TafakorAuthState({
    @Default(false) bool isLoading,
    @Default(false) bool isCodeSent,
    String? phone,
    TafakorUser? user,
    Failure? error,
    @Default(0) int resendCountdown,
  }) = _TafakorAuthState;

  const TafakorAuthState._();

  bool get isAuthenticated => user != null && (user?.token != null && user!.token!.isNotEmpty);
}
