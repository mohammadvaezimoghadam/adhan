import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/tafakor_topic.dart';

part 'tafakor_topic_dto.freezed.dart';
part 'tafakor_topic_dto.g.dart';

@freezed
abstract class TafakorTopicDto with _$TafakorTopicDto {
  const TafakorTopicDto._();

  const factory TafakorTopicDto({
    required int id,
    required String name,
    String? image,
    String? description,
    @JsonKey(name: 'post_badge') String? postBadge,
    @JsonKey(name: 'created_by') int? createdBy,
    @JsonKey(name: 'created_by_phone') String? createdByPhone,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'telegram_bot_active') @Default(false) bool telegramBotActive,
    @JsonKey(name: 'bale_bot_active') @Default(false) bool baleBotActive,
    @JsonKey(name: 'post_count') @Default(0) int postCount,
  }) = _TafakorTopicDto;

  factory TafakorTopicDto.fromJson(Map<String, dynamic> json) =>
      _$TafakorTopicDtoFromJson(json);

  TafakorTopic toDomain() => TafakorTopic(
        id: id,
        name: name,
        image: image,
        description: description,
        postBadge: postBadge,
        createdBy: createdBy,
        createdByPhone: createdByPhone,
        createdAt: createdAt,
        telegramBotActive: telegramBotActive,
        baleBotActive: baleBotActive,
        postCount: postCount,
      );
}
