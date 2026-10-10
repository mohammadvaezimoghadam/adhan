// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tafakor_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TafakorUser {

 String get phone; bool get isTelegramConnected; bool get isBaleConnected; String? get token;
/// Create a copy of TafakorUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TafakorUserCopyWith<TafakorUser> get copyWith => _$TafakorUserCopyWithImpl<TafakorUser>(this as TafakorUser, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TafakorUser&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isTelegramConnected, isTelegramConnected) || other.isTelegramConnected == isTelegramConnected)&&(identical(other.isBaleConnected, isBaleConnected) || other.isBaleConnected == isBaleConnected)&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,phone,isTelegramConnected,isBaleConnected,token);

@override
String toString() {
  return 'TafakorUser(phone: $phone, isTelegramConnected: $isTelegramConnected, isBaleConnected: $isBaleConnected, token: $token)';
}


}

/// @nodoc
abstract mixin class $TafakorUserCopyWith<$Res>  {
  factory $TafakorUserCopyWith(TafakorUser value, $Res Function(TafakorUser) _then) = _$TafakorUserCopyWithImpl;
@useResult
$Res call({
 String phone, bool isTelegramConnected, bool isBaleConnected, String? token
});




}
/// @nodoc
class _$TafakorUserCopyWithImpl<$Res>
    implements $TafakorUserCopyWith<$Res> {
  _$TafakorUserCopyWithImpl(this._self, this._then);

  final TafakorUser _self;
  final $Res Function(TafakorUser) _then;

/// Create a copy of TafakorUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,Object? isTelegramConnected = null,Object? isBaleConnected = null,Object? token = freezed,}) {
  return _then(_self.copyWith(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isTelegramConnected: null == isTelegramConnected ? _self.isTelegramConnected : isTelegramConnected // ignore: cast_nullable_to_non_nullable
as bool,isBaleConnected: null == isBaleConnected ? _self.isBaleConnected : isBaleConnected // ignore: cast_nullable_to_non_nullable
as bool,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TafakorUser].
extension TafakorUserPatterns on TafakorUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TafakorUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TafakorUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TafakorUser value)  $default,){
final _that = this;
switch (_that) {
case _TafakorUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TafakorUser value)?  $default,){
final _that = this;
switch (_that) {
case _TafakorUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone,  bool isTelegramConnected,  bool isBaleConnected,  String? token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TafakorUser() when $default != null:
return $default(_that.phone,_that.isTelegramConnected,_that.isBaleConnected,_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone,  bool isTelegramConnected,  bool isBaleConnected,  String? token)  $default,) {final _that = this;
switch (_that) {
case _TafakorUser():
return $default(_that.phone,_that.isTelegramConnected,_that.isBaleConnected,_that.token);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone,  bool isTelegramConnected,  bool isBaleConnected,  String? token)?  $default,) {final _that = this;
switch (_that) {
case _TafakorUser() when $default != null:
return $default(_that.phone,_that.isTelegramConnected,_that.isBaleConnected,_that.token);case _:
  return null;

}
}

}

/// @nodoc


class _TafakorUser implements TafakorUser {
  const _TafakorUser({required this.phone, this.isTelegramConnected = false, this.isBaleConnected = false, this.token});
  

@override final  String phone;
@override@JsonKey() final  bool isTelegramConnected;
@override@JsonKey() final  bool isBaleConnected;
@override final  String? token;

/// Create a copy of TafakorUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TafakorUserCopyWith<_TafakorUser> get copyWith => __$TafakorUserCopyWithImpl<_TafakorUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TafakorUser&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isTelegramConnected, isTelegramConnected) || other.isTelegramConnected == isTelegramConnected)&&(identical(other.isBaleConnected, isBaleConnected) || other.isBaleConnected == isBaleConnected)&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,phone,isTelegramConnected,isBaleConnected,token);

@override
String toString() {
  return 'TafakorUser(phone: $phone, isTelegramConnected: $isTelegramConnected, isBaleConnected: $isBaleConnected, token: $token)';
}


}

/// @nodoc
abstract mixin class _$TafakorUserCopyWith<$Res> implements $TafakorUserCopyWith<$Res> {
  factory _$TafakorUserCopyWith(_TafakorUser value, $Res Function(_TafakorUser) _then) = __$TafakorUserCopyWithImpl;
@override @useResult
$Res call({
 String phone, bool isTelegramConnected, bool isBaleConnected, String? token
});




}
/// @nodoc
class __$TafakorUserCopyWithImpl<$Res>
    implements _$TafakorUserCopyWith<$Res> {
  __$TafakorUserCopyWithImpl(this._self, this._then);

  final _TafakorUser _self;
  final $Res Function(_TafakorUser) _then;

/// Create a copy of TafakorUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? isTelegramConnected = null,Object? isBaleConnected = null,Object? token = freezed,}) {
  return _then(_TafakorUser(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isTelegramConnected: null == isTelegramConnected ? _self.isTelegramConnected : isTelegramConnected // ignore: cast_nullable_to_non_nullable
as bool,isBaleConnected: null == isBaleConnected ? _self.isBaleConnected : isBaleConnected // ignore: cast_nullable_to_non_nullable
as bool,token: freezed == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
