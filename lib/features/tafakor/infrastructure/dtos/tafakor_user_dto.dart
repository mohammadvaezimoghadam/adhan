import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/tafakor_user.dart';

part 'tafakor_user_dto.freezed.dart';
part 'tafakor_user_dto.g.dart';

Object? _readTelegramConnected(Map json, String key) {
  final bot = json['is_telegram_bot_connected'];
  if (bot is bool) return bot;
  final legacy = json['is_telegram_connected'];
  if (legacy is bool) return legacy;
  final otp = json['is_telegram_otp_connected'];
  if (otp is bool) return otp;
  return false;
}

Object? _readBaleConnected(Map json, String key) {
  final bot = json['is_bale_bot_connected'];
  if (bot is bool) return bot;
  final legacy = json['is_bale_connected'];
  if (legacy is bool) return legacy;
  final otp = json['is_bale_otp_connected'];
  if (otp is bool) return otp;
  return false;
}

@freezed
abstract class TafakorUserDto with _$TafakorUserDto {
  const TafakorUserDto._();

  const factory TafakorUserDto({
    required String phone,
    @JsonKey(readValue: _readTelegramConnected) @Default(false) bool isTelegramConnected,
    @JsonKey(readValue: _readBaleConnected) @Default(false) bool isBaleConnected,
  }) = _TafakorUserDto;

  factory TafakorUserDto.fromJson(Map<String, dynamic> json) =>
      _$TafakorUserDtoFromJson(json);

  TafakorUser toDomain({String? token}) => TafakorUser(
        phone: phone,
        isTelegramConnected: isTelegramConnected,
        isBaleConnected: isBaleConnected,
        token: token,
      );
}
