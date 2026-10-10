import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/tafakor_user.dart';
import 'tafakor_user_dto.dart';

part 'tafakor_auth_response_dto.freezed.dart';
part 'tafakor_auth_response_dto.g.dart';

@freezed
abstract class TafakorAuthResponseDto with _$TafakorAuthResponseDto {
  const TafakorAuthResponseDto._();

  const factory TafakorAuthResponseDto({
    required String token,
    required TafakorUserDto user,
  }) = _TafakorAuthResponseDto;

  factory TafakorAuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TafakorAuthResponseDtoFromJson(json);

  TafakorUser toDomain() => user.toDomain(token: token);
}
