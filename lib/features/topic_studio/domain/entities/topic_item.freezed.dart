// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'topic_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopicItem {

 String get id; String get title; TopicStatus get status; List<TopicBlock> get blocks; int get createdAt; int get updatedAt;
/// Create a copy of TopicItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopicItemCopyWith<TopicItem> get copyWith => _$TopicItemCopyWithImpl<TopicItem>(this as TopicItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopicItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.blocks, blocks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,status,const DeepCollectionEquality().hash(blocks),createdAt,updatedAt);

@override
String toString() {
  return 'TopicItem(id: $id, title: $title, status: $status, blocks: $blocks, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TopicItemCopyWith<$Res>  {
  factory $TopicItemCopyWith(TopicItem value, $Res Function(TopicItem) _then) = _$TopicItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, TopicStatus status, List<TopicBlock> blocks, int createdAt, int updatedAt
});




}
/// @nodoc
class _$TopicItemCopyWithImpl<$Res>
    implements $TopicItemCopyWith<$Res> {
  _$TopicItemCopyWithImpl(this._self, this._then);

  final TopicItem _self;
  final $Res Function(TopicItem) _then;

/// Create a copy of TopicItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? status = null,Object? blocks = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopicStatus,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<TopicBlock>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TopicItem].
extension TopicItemPatterns on TopicItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopicItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopicItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopicItem value)  $default,){
final _that = this;
switch (_that) {
case _TopicItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopicItem value)?  $default,){
final _that = this;
switch (_that) {
case _TopicItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  TopicStatus status,  List<TopicBlock> blocks,  int createdAt,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopicItem() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.blocks,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  TopicStatus status,  List<TopicBlock> blocks,  int createdAt,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TopicItem():
return $default(_that.id,_that.title,_that.status,_that.blocks,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  TopicStatus status,  List<TopicBlock> blocks,  int createdAt,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TopicItem() when $default != null:
return $default(_that.id,_that.title,_that.status,_that.blocks,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TopicItem extends TopicItem {
  const _TopicItem({required this.id, required this.title, this.status = TopicStatus.open, final  List<TopicBlock> blocks = const [], required this.createdAt, required this.updatedAt}): _blocks = blocks,super._();
  

@override final  String id;
@override final  String title;
@override@JsonKey() final  TopicStatus status;
 final  List<TopicBlock> _blocks;
@override@JsonKey() List<TopicBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}

@override final  int createdAt;
@override final  int updatedAt;

/// Create a copy of TopicItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopicItemCopyWith<_TopicItem> get copyWith => __$TopicItemCopyWithImpl<_TopicItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopicItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._blocks, _blocks)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,status,const DeepCollectionEquality().hash(_blocks),createdAt,updatedAt);

@override
String toString() {
  return 'TopicItem(id: $id, title: $title, status: $status, blocks: $blocks, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TopicItemCopyWith<$Res> implements $TopicItemCopyWith<$Res> {
  factory _$TopicItemCopyWith(_TopicItem value, $Res Function(_TopicItem) _then) = __$TopicItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, TopicStatus status, List<TopicBlock> blocks, int createdAt, int updatedAt
});




}
/// @nodoc
class __$TopicItemCopyWithImpl<$Res>
    implements _$TopicItemCopyWith<$Res> {
  __$TopicItemCopyWithImpl(this._self, this._then);

  final _TopicItem _self;
  final $Res Function(_TopicItem) _then;

/// Create a copy of TopicItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? status = null,Object? blocks = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TopicItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TopicStatus,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<TopicBlock>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
