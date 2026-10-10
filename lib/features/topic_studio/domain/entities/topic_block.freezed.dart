// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopicBlock {

 String get id; TopicBlockType get type; String get content; int? get surahId; String? get surahName; int? get ayahNumber; String? get sourceTitle; int get createdAt;
/// Create a copy of TopicBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopicBlockCopyWith<TopicBlock> get copyWith => _$TopicBlockCopyWithImpl<TopicBlock>(this as TopicBlock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopicBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.content, content) || other.content == content)&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.surahName, surahName) || other.surahName == surahName)&&(identical(other.ayahNumber, ayahNumber) || other.ayahNumber == ayahNumber)&&(identical(other.sourceTitle, sourceTitle) || other.sourceTitle == sourceTitle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,content,surahId,surahName,ayahNumber,sourceTitle,createdAt);

@override
String toString() {
  return 'TopicBlock(id: $id, type: $type, content: $content, surahId: $surahId, surahName: $surahName, ayahNumber: $ayahNumber, sourceTitle: $sourceTitle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TopicBlockCopyWith<$Res>  {
  factory $TopicBlockCopyWith(TopicBlock value, $Res Function(TopicBlock) _then) = _$TopicBlockCopyWithImpl;
@useResult
$Res call({
 String id, TopicBlockType type, String content, int? surahId, String? surahName, int? ayahNumber, String? sourceTitle, int createdAt
});




}
/// @nodoc
class _$TopicBlockCopyWithImpl<$Res>
    implements $TopicBlockCopyWith<$Res> {
  _$TopicBlockCopyWithImpl(this._self, this._then);

  final TopicBlock _self;
  final $Res Function(TopicBlock) _then;

/// Create a copy of TopicBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? content = null,Object? surahId = freezed,Object? surahName = freezed,Object? ayahNumber = freezed,Object? sourceTitle = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TopicBlockType,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,surahId: freezed == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as int?,surahName: freezed == surahName ? _self.surahName : surahName // ignore: cast_nullable_to_non_nullable
as String?,ayahNumber: freezed == ayahNumber ? _self.ayahNumber : ayahNumber // ignore: cast_nullable_to_non_nullable
as int?,sourceTitle: freezed == sourceTitle ? _self.sourceTitle : sourceTitle // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TopicBlock].
extension TopicBlockPatterns on TopicBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopicBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopicBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopicBlock value)  $default,){
final _that = this;
switch (_that) {
case _TopicBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopicBlock value)?  $default,){
final _that = this;
switch (_that) {
case _TopicBlock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TopicBlockType type,  String content,  int? surahId,  String? surahName,  int? ayahNumber,  String? sourceTitle,  int createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopicBlock() when $default != null:
return $default(_that.id,_that.type,_that.content,_that.surahId,_that.surahName,_that.ayahNumber,_that.sourceTitle,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TopicBlockType type,  String content,  int? surahId,  String? surahName,  int? ayahNumber,  String? sourceTitle,  int createdAt)  $default,) {final _that = this;
switch (_that) {
case _TopicBlock():
return $default(_that.id,_that.type,_that.content,_that.surahId,_that.surahName,_that.ayahNumber,_that.sourceTitle,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TopicBlockType type,  String content,  int? surahId,  String? surahName,  int? ayahNumber,  String? sourceTitle,  int createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TopicBlock() when $default != null:
return $default(_that.id,_that.type,_that.content,_that.surahId,_that.surahName,_that.ayahNumber,_that.sourceTitle,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _TopicBlock extends TopicBlock {
  const _TopicBlock({required this.id, required this.type, required this.content, this.surahId, this.surahName, this.ayahNumber, this.sourceTitle, required this.createdAt}): super._();
  

@override final  String id;
@override final  TopicBlockType type;
@override final  String content;
@override final  int? surahId;
@override final  String? surahName;
@override final  int? ayahNumber;
@override final  String? sourceTitle;
@override final  int createdAt;

/// Create a copy of TopicBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopicBlockCopyWith<_TopicBlock> get copyWith => __$TopicBlockCopyWithImpl<_TopicBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopicBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.content, content) || other.content == content)&&(identical(other.surahId, surahId) || other.surahId == surahId)&&(identical(other.surahName, surahName) || other.surahName == surahName)&&(identical(other.ayahNumber, ayahNumber) || other.ayahNumber == ayahNumber)&&(identical(other.sourceTitle, sourceTitle) || other.sourceTitle == sourceTitle)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,content,surahId,surahName,ayahNumber,sourceTitle,createdAt);

@override
String toString() {
  return 'TopicBlock(id: $id, type: $type, content: $content, surahId: $surahId, surahName: $surahName, ayahNumber: $ayahNumber, sourceTitle: $sourceTitle, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TopicBlockCopyWith<$Res> implements $TopicBlockCopyWith<$Res> {
  factory _$TopicBlockCopyWith(_TopicBlock value, $Res Function(_TopicBlock) _then) = __$TopicBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, TopicBlockType type, String content, int? surahId, String? surahName, int? ayahNumber, String? sourceTitle, int createdAt
});




}
/// @nodoc
class __$TopicBlockCopyWithImpl<$Res>
    implements _$TopicBlockCopyWith<$Res> {
  __$TopicBlockCopyWithImpl(this._self, this._then);

  final _TopicBlock _self;
  final $Res Function(_TopicBlock) _then;

/// Create a copy of TopicBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? content = null,Object? surahId = freezed,Object? surahName = freezed,Object? ayahNumber = freezed,Object? sourceTitle = freezed,Object? createdAt = null,}) {
  return _then(_TopicBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TopicBlockType,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,surahId: freezed == surahId ? _self.surahId : surahId // ignore: cast_nullable_to_non_nullable
as int?,surahName: freezed == surahName ? _self.surahName : surahName // ignore: cast_nullable_to_non_nullable
as String?,ayahNumber: freezed == ayahNumber ? _self.ayahNumber : ayahNumber // ignore: cast_nullable_to_non_nullable
as int?,sourceTitle: freezed == sourceTitle ? _self.sourceTitle : sourceTitle // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
