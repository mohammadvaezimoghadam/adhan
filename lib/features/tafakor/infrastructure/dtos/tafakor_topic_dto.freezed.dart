// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tafakor_topic_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TafakorTopicDto {

 int get id; String get name; String? get image; String? get description;@JsonKey(name: 'post_badge') String? get postBadge;@JsonKey(name: 'created_by') int? get createdBy;@JsonKey(name: 'created_by_phone') String? get createdByPhone;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'telegram_bot_active') bool get telegramBotActive;@JsonKey(name: 'bale_bot_active') bool get baleBotActive;@JsonKey(name: 'post_count') int get postCount;
/// Create a copy of TafakorTopicDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TafakorTopicDtoCopyWith<TafakorTopicDto> get copyWith => _$TafakorTopicDtoCopyWithImpl<TafakorTopicDto>(this as TafakorTopicDto, _$identity);

  /// Serializes this TafakorTopicDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TafakorTopicDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.description, description) || other.description == description)&&(identical(other.postBadge, postBadge) || other.postBadge == postBadge)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByPhone, createdByPhone) || other.createdByPhone == createdByPhone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.telegramBotActive, telegramBotActive) || other.telegramBotActive == telegramBotActive)&&(identical(other.baleBotActive, baleBotActive) || other.baleBotActive == baleBotActive)&&(identical(other.postCount, postCount) || other.postCount == postCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,image,description,postBadge,createdBy,createdByPhone,createdAt,telegramBotActive,baleBotActive,postCount);

@override
String toString() {
  return 'TafakorTopicDto(id: $id, name: $name, image: $image, description: $description, postBadge: $postBadge, createdBy: $createdBy, createdByPhone: $createdByPhone, createdAt: $createdAt, telegramBotActive: $telegramBotActive, baleBotActive: $baleBotActive, postCount: $postCount)';
}


}

/// @nodoc
abstract mixin class $TafakorTopicDtoCopyWith<$Res>  {
  factory $TafakorTopicDtoCopyWith(TafakorTopicDto value, $Res Function(TafakorTopicDto) _then) = _$TafakorTopicDtoCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? image, String? description,@JsonKey(name: 'post_badge') String? postBadge,@JsonKey(name: 'created_by') int? createdBy,@JsonKey(name: 'created_by_phone') String? createdByPhone,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'telegram_bot_active') bool telegramBotActive,@JsonKey(name: 'bale_bot_active') bool baleBotActive,@JsonKey(name: 'post_count') int postCount
});




}
/// @nodoc
class _$TafakorTopicDtoCopyWithImpl<$Res>
    implements $TafakorTopicDtoCopyWith<$Res> {
  _$TafakorTopicDtoCopyWithImpl(this._self, this._then);

  final TafakorTopicDto _self;
  final $Res Function(TafakorTopicDto) _then;

/// Create a copy of TafakorTopicDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? image = freezed,Object? description = freezed,Object? postBadge = freezed,Object? createdBy = freezed,Object? createdByPhone = freezed,Object? createdAt = freezed,Object? telegramBotActive = null,Object? baleBotActive = null,Object? postCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,postBadge: freezed == postBadge ? _self.postBadge : postBadge // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,createdByPhone: freezed == createdByPhone ? _self.createdByPhone : createdByPhone // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,telegramBotActive: null == telegramBotActive ? _self.telegramBotActive : telegramBotActive // ignore: cast_nullable_to_non_nullable
as bool,baleBotActive: null == baleBotActive ? _self.baleBotActive : baleBotActive // ignore: cast_nullable_to_non_nullable
as bool,postCount: null == postCount ? _self.postCount : postCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TafakorTopicDto].
extension TafakorTopicDtoPatterns on TafakorTopicDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TafakorTopicDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TafakorTopicDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TafakorTopicDto value)  $default,){
final _that = this;
switch (_that) {
case _TafakorTopicDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TafakorTopicDto value)?  $default,){
final _that = this;
switch (_that) {
case _TafakorTopicDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? image,  String? description, @JsonKey(name: 'post_badge')  String? postBadge, @JsonKey(name: 'created_by')  int? createdBy, @JsonKey(name: 'created_by_phone')  String? createdByPhone, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'telegram_bot_active')  bool telegramBotActive, @JsonKey(name: 'bale_bot_active')  bool baleBotActive, @JsonKey(name: 'post_count')  int postCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TafakorTopicDto() when $default != null:
return $default(_that.id,_that.name,_that.image,_that.description,_that.postBadge,_that.createdBy,_that.createdByPhone,_that.createdAt,_that.telegramBotActive,_that.baleBotActive,_that.postCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? image,  String? description, @JsonKey(name: 'post_badge')  String? postBadge, @JsonKey(name: 'created_by')  int? createdBy, @JsonKey(name: 'created_by_phone')  String? createdByPhone, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'telegram_bot_active')  bool telegramBotActive, @JsonKey(name: 'bale_bot_active')  bool baleBotActive, @JsonKey(name: 'post_count')  int postCount)  $default,) {final _that = this;
switch (_that) {
case _TafakorTopicDto():
return $default(_that.id,_that.name,_that.image,_that.description,_that.postBadge,_that.createdBy,_that.createdByPhone,_that.createdAt,_that.telegramBotActive,_that.baleBotActive,_that.postCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? image,  String? description, @JsonKey(name: 'post_badge')  String? postBadge, @JsonKey(name: 'created_by')  int? createdBy, @JsonKey(name: 'created_by_phone')  String? createdByPhone, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'telegram_bot_active')  bool telegramBotActive, @JsonKey(name: 'bale_bot_active')  bool baleBotActive, @JsonKey(name: 'post_count')  int postCount)?  $default,) {final _that = this;
switch (_that) {
case _TafakorTopicDto() when $default != null:
return $default(_that.id,_that.name,_that.image,_that.description,_that.postBadge,_that.createdBy,_that.createdByPhone,_that.createdAt,_that.telegramBotActive,_that.baleBotActive,_that.postCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TafakorTopicDto extends TafakorTopicDto {
  const _TafakorTopicDto({required this.id, required this.name, this.image, this.description, @JsonKey(name: 'post_badge') this.postBadge, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'created_by_phone') this.createdByPhone, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'telegram_bot_active') this.telegramBotActive = false, @JsonKey(name: 'bale_bot_active') this.baleBotActive = false, @JsonKey(name: 'post_count') this.postCount = 0}): super._();
  factory _TafakorTopicDto.fromJson(Map<String, dynamic> json) => _$TafakorTopicDtoFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? image;
@override final  String? description;
@override@JsonKey(name: 'post_badge') final  String? postBadge;
@override@JsonKey(name: 'created_by') final  int? createdBy;
@override@JsonKey(name: 'created_by_phone') final  String? createdByPhone;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'telegram_bot_active') final  bool telegramBotActive;
@override@JsonKey(name: 'bale_bot_active') final  bool baleBotActive;
@override@JsonKey(name: 'post_count') final  int postCount;

/// Create a copy of TafakorTopicDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TafakorTopicDtoCopyWith<_TafakorTopicDto> get copyWith => __$TafakorTopicDtoCopyWithImpl<_TafakorTopicDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TafakorTopicDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TafakorTopicDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.description, description) || other.description == description)&&(identical(other.postBadge, postBadge) || other.postBadge == postBadge)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByPhone, createdByPhone) || other.createdByPhone == createdByPhone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.telegramBotActive, telegramBotActive) || other.telegramBotActive == telegramBotActive)&&(identical(other.baleBotActive, baleBotActive) || other.baleBotActive == baleBotActive)&&(identical(other.postCount, postCount) || other.postCount == postCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,image,description,postBadge,createdBy,createdByPhone,createdAt,telegramBotActive,baleBotActive,postCount);

@override
String toString() {
  return 'TafakorTopicDto(id: $id, name: $name, image: $image, description: $description, postBadge: $postBadge, createdBy: $createdBy, createdByPhone: $createdByPhone, createdAt: $createdAt, telegramBotActive: $telegramBotActive, baleBotActive: $baleBotActive, postCount: $postCount)';
}


}

/// @nodoc
abstract mixin class _$TafakorTopicDtoCopyWith<$Res> implements $TafakorTopicDtoCopyWith<$Res> {
  factory _$TafakorTopicDtoCopyWith(_TafakorTopicDto value, $Res Function(_TafakorTopicDto) _then) = __$TafakorTopicDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? image, String? description,@JsonKey(name: 'post_badge') String? postBadge,@JsonKey(name: 'created_by') int? createdBy,@JsonKey(name: 'created_by_phone') String? createdByPhone,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'telegram_bot_active') bool telegramBotActive,@JsonKey(name: 'bale_bot_active') bool baleBotActive,@JsonKey(name: 'post_count') int postCount
});




}
/// @nodoc
class __$TafakorTopicDtoCopyWithImpl<$Res>
    implements _$TafakorTopicDtoCopyWith<$Res> {
  __$TafakorTopicDtoCopyWithImpl(this._self, this._then);

  final _TafakorTopicDto _self;
  final $Res Function(_TafakorTopicDto) _then;

/// Create a copy of TafakorTopicDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? image = freezed,Object? description = freezed,Object? postBadge = freezed,Object? createdBy = freezed,Object? createdByPhone = freezed,Object? createdAt = freezed,Object? telegramBotActive = null,Object? baleBotActive = null,Object? postCount = null,}) {
  return _then(_TafakorTopicDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,postBadge: freezed == postBadge ? _self.postBadge : postBadge // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,createdByPhone: freezed == createdByPhone ? _self.createdByPhone : createdByPhone // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,telegramBotActive: null == telegramBotActive ? _self.telegramBotActive : telegramBotActive // ignore: cast_nullable_to_non_nullable
as bool,baleBotActive: null == baleBotActive ? _self.baleBotActive : baleBotActive // ignore: cast_nullable_to_non_nullable
as bool,postCount: null == postCount ? _self.postCount : postCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
