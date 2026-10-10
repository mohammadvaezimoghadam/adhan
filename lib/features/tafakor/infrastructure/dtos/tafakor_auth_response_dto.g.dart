// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tafakor_auth_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TafakorAuthResponseDto _$TafakorAuthResponseDtoFromJson(
  Map<String, dynamic> json,
) => _TafakorAuthResponseDto(
  token: json['token'] as String,
  user: TafakorUserDto.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TafakorAuthResponseDtoToJson(
  _TafakorAuthResponseDto instance,
) => <String, dynamic>{'token': instance.token, 'user': instance.user};
