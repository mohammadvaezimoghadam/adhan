// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tafakor_topic_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TafakorTopicDto _$TafakorTopicDtoFromJson(Map<String, dynamic> json) =>
    _TafakorTopicDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      image: json['image'] as String?,
      description: json['description'] as String?,
      postBadge: json['post_badge'] as String?,
      createdBy: (json['created_by'] as num?)?.toInt(),
      createdByPhone: json['created_by_phone'] as String?,
      createdAt: json['created_at'] as String?,
      telegramBotActive: json['telegram_bot_active'] as bool? ?? false,
      baleBotActive: json['bale_bot_active'] as bool? ?? false,
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TafakorTopicDtoToJson(_TafakorTopicDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image': instance.image,
      'description': instance.description,
      'post_badge': instance.postBadge,
      'created_by': instance.createdBy,
      'created_by_phone': instance.createdByPhone,
      'created_at': instance.createdAt,
      'telegram_bot_active': instance.telegramBotActive,
      'bale_bot_active': instance.baleBotActive,
      'post_count': instance.postCount,
    };
