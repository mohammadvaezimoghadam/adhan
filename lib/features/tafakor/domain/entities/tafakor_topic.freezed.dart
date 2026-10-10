// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tafakor_topic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TafakorTopic {

 int get id; String get name; String? get image; String? get description; String? get postBadge; int? get createdBy; String? get createdByPhone; String? get createdAt; bool get telegramBotActive; bool get baleBotActive; int get postCount;
/// Create a copy of TafakorTopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TafakorTopicCopyWith<TafakorTopic> get copyWith => _$TafakorTopicCopyWithImpl<TafakorTopic>(this as TafakorTopic, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TafakorTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.description, description) || other.description == description)&&(identical(other.postBadge, postBadge) || other.postBadge == postBadge)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByPhone, createdByPhone) || other.createdByPhone == createdByPhone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.telegramBotActive, telegramBotActive) || other.telegramBotActive == telegramBotActive)&&(identical(other.baleBotActive, baleBotActive) || other.baleBotActive == baleBotActive)&&(identical(other.postCount, postCount) || other.postCount == postCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,image,description,postBadge,createdBy,createdByPhone,createdAt,telegramBotActive,baleBotActive,postCount);

@override
String toString() {
  return 'TafakorTopic(id: $id, name: $name, image: $image, description: $description, postBadge: $postBadge, createdBy: $createdBy, createdByPhone: $createdByPhone, createdAt: $createdAt, telegramBotActive: $telegramBotActive, baleBotActive: $baleBotActive, postCount: $postCount)';
}


}

/// @nodoc
abstract mixin class $TafakorTopicCopyWith<$Res>  {
  factory $TafakorTopicCopyWith(TafakorTopic value, $Res Function(TafakorTopic) _then) = _$TafakorTopicCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? image, String? description, String? postBadge, int? createdBy, String? createdByPhone, String? createdAt, bool telegramBotActive, bool baleBotActive, int postCount
});




}
/// @nodoc
class _$TafakorTopicCopyWithImpl<$Res>
    implements $TafakorTopicCopyWith<$Res> {
  _$TafakorTopicCopyWithImpl(this._self, this._then);

  final TafakorTopic _self;
  final $Res Function(TafakorTopic) _then;

/// Create a copy of TafakorTopic
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


/// Adds pattern-matching-related methods to [TafakorTopic].
extension TafakorTopicPatterns on TafakorTopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TafakorTopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TafakorTopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TafakorTopic value)  $default,){
final _that = this;
switch (_that) {
case _TafakorTopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TafakorTopic value)?  $default,){
final _that = this;
switch (_that) {
case _TafakorTopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? image,  String? description,  String? postBadge,  int? createdBy,  String? createdByPhone,  String? createdAt,  bool telegramBotActive,  bool baleBotActive,  int postCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TafakorTopic() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? image,  String? description,  String? postBadge,  int? createdBy,  String? createdByPhone,  String? createdAt,  bool telegramBotActive,  bool baleBotActive,  int postCount)  $default,) {final _that = this;
switch (_that) {
case _TafakorTopic():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? image,  String? description,  String? postBadge,  int? createdBy,  String? createdByPhone,  String? createdAt,  bool telegramBotActive,  bool baleBotActive,  int postCount)?  $default,) {final _that = this;
switch (_that) {
case _TafakorTopic() when $default != null:
return $default(_that.id,_that.name,_that.image,_that.description,_that.postBadge,_that.createdBy,_that.createdByPhone,_that.createdAt,_that.telegramBotActive,_that.baleBotActive,_that.postCount);case _:
  return null;

}
}

}

/// @nodoc


class _TafakorTopic extends TafakorTopic {
  const _TafakorTopic({required this.id, required this.name, this.image, this.description, this.postBadge, this.createdBy, this.createdByPhone, this.createdAt, this.telegramBotActive = false, this.baleBotActive = false, this.postCount = 0}): super._();
  

@override final  int id;
@override final  String name;
@override final  String? image;
@override final  String? description;
@override final  String? postBadge;
@override final  int? createdBy;
@override final  String? createdByPhone;
@override final  String? createdAt;
@override@JsonKey() final  bool telegramBotActive;
@override@JsonKey() final  bool baleBotActive;
@override@JsonKey() final  int postCount;

/// Create a copy of TafakorTopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TafakorTopicCopyWith<_TafakorTopic> get copyWith => __$TafakorTopicCopyWithImpl<_TafakorTopic>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TafakorTopic&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.description, description) || other.description == description)&&(identical(other.postBadge, postBadge) || other.postBadge == postBadge)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByPhone, createdByPhone) || other.createdByPhone == createdByPhone)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.telegramBotActive, telegramBotActive) || other.telegramBotActive == telegramBotActive)&&(identical(other.baleBotActive, baleBotActive) || other.baleBotActive == baleBotActive)&&(identical(other.postCount, postCount) || other.postCount == postCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,image,description,postBadge,createdBy,createdByPhone,createdAt,telegramBotActive,baleBotActive,postCount);

@override
String toString() {
  return 'TafakorTopic(id: $id, name: $name, image: $image, description: $description, postBadge: $postBadge, createdBy: $createdBy, createdByPhone: $createdByPhone, createdAt: $createdAt, telegramBotActive: $telegramBotActive, baleBotActive: $baleBotActive, postCount: $postCount)';
}


}

/// @nodoc
abstract mixin class _$TafakorTopicCopyWith<$Res> implements $TafakorTopicCopyWith<$Res> {
  factory _$TafakorTopicCopyWith(_TafakorTopic value, $Res Function(_TafakorTopic) _then) = __$TafakorTopicCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? image, String? description, String? postBadge, int? createdBy, String? createdByPhone, String? createdAt, bool telegramBotActive, bool baleBotActive, int postCount
});




}
/// @nodoc
class __$TafakorTopicCopyWithImpl<$Res>
    implements _$TafakorTopicCopyWith<$Res> {
  __$TafakorTopicCopyWithImpl(this._self, this._then);

  final _TafakorTopic _self;
  final $Res Function(_TafakorTopic) _then;

/// Create a copy of TafakorTopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? image = freezed,Object? description = freezed,Object? postBadge = freezed,Object? createdBy = freezed,Object? createdByPhone = freezed,Object? createdAt = freezed,Object? telegramBotActive = null,Object? baleBotActive = null,Object? postCount = null,}) {
  return _then(_TafakorTopic(
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
