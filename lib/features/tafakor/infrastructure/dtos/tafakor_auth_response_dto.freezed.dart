// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tafakor_auth_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TafakorAuthResponseDto {

 String get token; TafakorUserDto get user;
/// Create a copy of TafakorAuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TafakorAuthResponseDtoCopyWith<TafakorAuthResponseDto> get copyWith => _$TafakorAuthResponseDtoCopyWithImpl<TafakorAuthResponseDto>(this as TafakorAuthResponseDto, _$identity);

  /// Serializes this TafakorAuthResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TafakorAuthResponseDto&&(identical(other.token, token) || other.token == token)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,user);

@override
String toString() {
  return 'TafakorAuthResponseDto(token: $token, user: $user)';
}


}

/// @nodoc
abstract mixin class $TafakorAuthResponseDtoCopyWith<$Res>  {
  factory $TafakorAuthResponseDtoCopyWith(TafakorAuthResponseDto value, $Res Function(TafakorAuthResponseDto) _then) = _$TafakorAuthResponseDtoCopyWithImpl;
@useResult
$Res call({
 String token, TafakorUserDto user
});


$TafakorUserDtoCopyWith<$Res> get user;

}
/// @nodoc
class _$TafakorAuthResponseDtoCopyWithImpl<$Res>
    implements $TafakorAuthResponseDtoCopyWith<$Res> {
  _$TafakorAuthResponseDtoCopyWithImpl(this._self, this._then);

  final TafakorAuthResponseDto _self;
  final $Res Function(TafakorAuthResponseDto) _then;

/// Create a copy of TafakorAuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? user = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as TafakorUserDto,
  ));
}
/// Create a copy of TafakorAuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TafakorUserDtoCopyWith<$Res> get user {
  
  return $TafakorUserDtoCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [TafakorAuthResponseDto].
extension TafakorAuthResponseDtoPatterns on TafakorAuthResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TafakorAuthResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TafakorAuthResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TafakorAuthResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _TafakorAuthResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TafakorAuthResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _TafakorAuthResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  TafakorUserDto user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TafakorAuthResponseDto() when $default != null:
return $default(_that.token,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  TafakorUserDto user)  $default,) {final _that = this;
switch (_that) {
case _TafakorAuthResponseDto():
return $default(_that.token,_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  TafakorUserDto user)?  $default,) {final _that = this;
switch (_that) {
case _TafakorAuthResponseDto() when $default != null:
return $default(_that.token,_that.user);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TafakorAuthResponseDto extends TafakorAuthResponseDto {
  const _TafakorAuthResponseDto({required this.token, required this.user}): super._();
  factory _TafakorAuthResponseDto.fromJson(Map<String, dynamic> json) => _$TafakorAuthResponseDtoFromJson(json);

@override final  String token;
@override final  TafakorUserDto user;

/// Create a copy of TafakorAuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TafakorAuthResponseDtoCopyWith<_TafakorAuthResponseDto> get copyWith => __$TafakorAuthResponseDtoCopyWithImpl<_TafakorAuthResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TafakorAuthResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TafakorAuthResponseDto&&(identical(other.token, token) || other.token == token)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,user);

@override
String toString() {
  return 'TafakorAuthResponseDto(token: $token, user: $user)';
}


}

/// @nodoc
abstract mixin class _$TafakorAuthResponseDtoCopyWith<$Res> implements $TafakorAuthResponseDtoCopyWith<$Res> {
  factory _$TafakorAuthResponseDtoCopyWith(_TafakorAuthResponseDto value, $Res Function(_TafakorAuthResponseDto) _then) = __$TafakorAuthResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String token, TafakorUserDto user
});


@override $TafakorUserDtoCopyWith<$Res> get user;

}
/// @nodoc
class __$TafakorAuthResponseDtoCopyWithImpl<$Res>
    implements _$TafakorAuthResponseDtoCopyWith<$Res> {
  __$TafakorAuthResponseDtoCopyWithImpl(this._self, this._then);

  final _TafakorAuthResponseDto _self;
  final $Res Function(_TafakorAuthResponseDto) _then;

/// Create a copy of TafakorAuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? user = null,}) {
  return _then(_TafakorAuthResponseDto(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as TafakorUserDto,
  ));
}

/// Create a copy of TafakorAuthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TafakorUserDtoCopyWith<$Res> get user {
  
  return $TafakorUserDtoCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
