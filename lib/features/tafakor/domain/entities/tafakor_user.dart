import 'package:freezed_annotation/freezed_annotation.dart';

part 'tafakor_user.freezed.dart';

@freezed
abstract class TafakorUser with _$TafakorUser {
  const factory TafakorUser({
    required String phone,
    @Default(false) bool isTelegramConnected,
    @Default(false) bool isBaleConnected,
    String? token,
  }) = _TafakorUser;
}
