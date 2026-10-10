// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tafakor_user_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TafakorUserDto {

 String get phone;@JsonKey(name: 'is_telegram_connected') bool get isTelegramConnected;@JsonKey(name: 'is_bale_connected') bool get isBaleConnected;
/// Create a copy of TafakorUserDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TafakorUserDtoCopyWith<TafakorUserDto> get copyWith => _$TafakorUserDtoCopyWithImpl<TafakorUserDto>(this as TafakorUserDto, _$identity);

  /// Serializes this TafakorUserDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TafakorUserDto&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isTelegramConnected, isTelegramConnected) || other.isTelegramConnected == isTelegramConnected)&&(identical(other.isBaleConnected, isBaleConnected) || other.isBaleConnected == isBaleConnected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phone,isTelegramConnected,isBaleConnected);

@override
String toString() {
  return 'TafakorUserDto(phone: $phone, isTelegramConnected: $isTelegramConnected, isBaleConnected: $isBaleConnected)';
}


}

/// @nodoc
abstract mixin class $TafakorUserDtoCopyWith<$Res>  {
  factory $TafakorUserDtoCopyWith(TafakorUserDto value, $Res Function(TafakorUserDto) _then) = _$TafakorUserDtoCopyWithImpl;
@useResult
$Res call({
 String phone,@JsonKey(name: 'is_telegram_connected') bool isTelegramConnected,@JsonKey(name: 'is_bale_connected') bool isBaleConnected
});




}
/// @nodoc
class _$TafakorUserDtoCopyWithImpl<$Res>
    implements $TafakorUserDtoCopyWith<$Res> {
  _$TafakorUserDtoCopyWithImpl(this._self, this._then);

  final TafakorUserDto _self;
  final $Res Function(TafakorUserDto) _then;

/// Create a copy of TafakorUserDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,Object? isTelegramConnected = null,Object? isBaleConnected = null,}) {
  return _then(_self.copyWith(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isTelegramConnected: null == isTelegramConnected ? _self.isTelegramConnected : isTelegramConnected // ignore: cast_nullable_to_non_nullable
as bool,isBaleConnected: null == isBaleConnected ? _self.isBaleConnected : isBaleConnected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TafakorUserDto].
extension TafakorUserDtoPatterns on TafakorUserDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TafakorUserDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TafakorUserDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TafakorUserDto value)  $default,){
final _that = this;
switch (_that) {
case _TafakorUserDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TafakorUserDto value)?  $default,){
final _that = this;
switch (_that) {
case _TafakorUserDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone, @JsonKey(name: 'is_telegram_connected')  bool isTelegramConnected, @JsonKey(name: 'is_bale_connected')  bool isBaleConnected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TafakorUserDto() when $default != null:
return $default(_that.phone,_that.isTelegramConnected,_that.isBaleConnected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone, @JsonKey(name: 'is_telegram_connected')  bool isTelegramConnected, @JsonKey(name: 'is_bale_connected')  bool isBaleConnected)  $default,) {final _that = this;
switch (_that) {
case _TafakorUserDto():
return $default(_that.phone,_that.isTelegramConnected,_that.isBaleConnected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone, @JsonKey(name: 'is_telegram_connected')  bool isTelegramConnected, @JsonKey(name: 'is_bale_connected')  bool isBaleConnected)?  $default,) {final _that = this;
switch (_that) {
case _TafakorUserDto() when $default != null:
return $default(_that.phone,_that.isTelegramConnected,_that.isBaleConnected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TafakorUserDto extends TafakorUserDto {
  const _TafakorUserDto({required this.phone, @JsonKey(name: 'is_telegram_connected') this.isTelegramConnected = false, @JsonKey(name: 'is_bale_connected') this.isBaleConnected = false}): super._();
  factory _TafakorUserDto.fromJson(Map<String, dynamic> json) => _$TafakorUserDtoFromJson(json);

@override final  String phone;
@override@JsonKey(name: 'is_telegram_connected') final  bool isTelegramConnected;
@override@JsonKey(name: 'is_bale_connected') final  bool isBaleConnected;

/// Create a copy of TafakorUserDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TafakorUserDtoCopyWith<_TafakorUserDto> get copyWith => __$TafakorUserDtoCopyWithImpl<_TafakorUserDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TafakorUserDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TafakorUserDto&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isTelegramConnected, isTelegramConnected) || other.isTelegramConnected == isTelegramConnected)&&(identical(other.isBaleConnected, isBaleConnected) || other.isBaleConnected == isBaleConnected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phone,isTelegramConnected,isBaleConnected);

@override
String toString() {
  return 'TafakorUserDto(phone: $phone, isTelegramConnected: $isTelegramConnected, isBaleConnected: $isBaleConnected)';
}


}

/// @nodoc
abstract mixin class _$TafakorUserDtoCopyWith<$Res> implements $TafakorUserDtoCopyWith<$Res> {
  factory _$TafakorUserDtoCopyWith(_TafakorUserDto value, $Res Function(_TafakorUserDto) _then) = __$TafakorUserDtoCopyWithImpl;
@override @useResult
$Res call({
 String phone,@JsonKey(name: 'is_telegram_connected') bool isTelegramConnected,@JsonKey(name: 'is_bale_connected') bool isBaleConnected
});




}
/// @nodoc
class __$TafakorUserDtoCopyWithImpl<$Res>
    implements _$TafakorUserDtoCopyWith<$Res> {
  __$TafakorUserDtoCopyWithImpl(this._self, this._then);

  final _TafakorUserDto _self;
  final $Res Function(_TafakorUserDto) _then;

/// Create a copy of TafakorUserDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? isTelegramConnected = null,Object? isBaleConnected = null,}) {
  return _then(_TafakorUserDto(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isTelegramConnected: null == isTelegramConnected ? _self.isTelegramConnected : isTelegramConnected // ignore: cast_nullable_to_non_nullable
as bool,isBaleConnected: null == isBaleConnected ? _self.isBaleConnected : isBaleConnected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
