// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tafakor_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TafakorUserDto _$TafakorUserDtoFromJson(Map<String, dynamic> json) =>
    _TafakorUserDto(
      phone: json['phone'] as String,
      isTelegramConnected:
          _readTelegramConnected(json, 'is_telegram_connected') as bool? ??
              false,
      isBaleConnected:
          _readBaleConnected(json, 'is_bale_connected') as bool? ?? false,
    );

Map<String, dynamic> _$TafakorUserDtoToJson(_TafakorUserDto instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'is_telegram_connected': instance.isTelegramConnected,
      'is_bale_connected': instance.isBaleConnected,
    };
