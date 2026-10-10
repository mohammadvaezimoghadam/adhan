// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tafakor_auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TafakorAuthState {

 bool get isLoading; bool get isCodeSent; String? get phone; TafakorUser? get user; Failure? get error; int get resendCountdown;
/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TafakorAuthStateCopyWith<TafakorAuthState> get copyWith => _$TafakorAuthStateCopyWithImpl<TafakorAuthState>(this as TafakorAuthState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TafakorAuthState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isCodeSent, isCodeSent) || other.isCodeSent == isCodeSent)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.user, user) || other.user == user)&&(identical(other.error, error) || other.error == error)&&(identical(other.resendCountdown, resendCountdown) || other.resendCountdown == resendCountdown));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isCodeSent,phone,user,error,resendCountdown);

@override
String toString() {
  return 'TafakorAuthState(isLoading: $isLoading, isCodeSent: $isCodeSent, phone: $phone, user: $user, error: $error, resendCountdown: $resendCountdown)';
}


}

/// @nodoc
abstract mixin class $TafakorAuthStateCopyWith<$Res>  {
  factory $TafakorAuthStateCopyWith(TafakorAuthState value, $Res Function(TafakorAuthState) _then) = _$TafakorAuthStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isCodeSent, String? phone, TafakorUser? user, Failure? error, int resendCountdown
});


$TafakorUserCopyWith<$Res>? get user;$FailureCopyWith<$Res>? get error;

}
/// @nodoc
class _$TafakorAuthStateCopyWithImpl<$Res>
    implements $TafakorAuthStateCopyWith<$Res> {
  _$TafakorAuthStateCopyWithImpl(this._self, this._then);

  final TafakorAuthState _self;
  final $Res Function(TafakorAuthState) _then;

/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isCodeSent = null,Object? phone = freezed,Object? user = freezed,Object? error = freezed,Object? resendCountdown = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isCodeSent: null == isCodeSent ? _self.isCodeSent : isCodeSent // ignore: cast_nullable_to_non_nullable
as bool,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as TafakorUser?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,resendCountdown: null == resendCountdown ? _self.resendCountdown : resendCountdown // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TafakorUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $TafakorUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// Adds pattern-matching-related methods to [TafakorAuthState].
extension TafakorAuthStatePatterns on TafakorAuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TafakorAuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TafakorAuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TafakorAuthState value)  $default,){
final _that = this;
switch (_that) {
case _TafakorAuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TafakorAuthState value)?  $default,){
final _that = this;
switch (_that) {
case _TafakorAuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isCodeSent,  String? phone,  TafakorUser? user,  Failure? error,  int resendCountdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TafakorAuthState() when $default != null:
return $default(_that.isLoading,_that.isCodeSent,_that.phone,_that.user,_that.error,_that.resendCountdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isCodeSent,  String? phone,  TafakorUser? user,  Failure? error,  int resendCountdown)  $default,) {final _that = this;
switch (_that) {
case _TafakorAuthState():
return $default(_that.isLoading,_that.isCodeSent,_that.phone,_that.user,_that.error,_that.resendCountdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isCodeSent,  String? phone,  TafakorUser? user,  Failure? error,  int resendCountdown)?  $default,) {final _that = this;
switch (_that) {
case _TafakorAuthState() when $default != null:
return $default(_that.isLoading,_that.isCodeSent,_that.phone,_that.user,_that.error,_that.resendCountdown);case _:
  return null;

}
}

}

/// @nodoc


class _TafakorAuthState extends TafakorAuthState {
  const _TafakorAuthState({this.isLoading = false, this.isCodeSent = false, this.phone, this.user, this.error, this.resendCountdown = 0}): super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isCodeSent;
@override final  String? phone;
@override final  TafakorUser? user;
@override final  Failure? error;
@override@JsonKey() final  int resendCountdown;

/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TafakorAuthStateCopyWith<_TafakorAuthState> get copyWith => __$TafakorAuthStateCopyWithImpl<_TafakorAuthState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TafakorAuthState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isCodeSent, isCodeSent) || other.isCodeSent == isCodeSent)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.user, user) || other.user == user)&&(identical(other.error, error) || other.error == error)&&(identical(other.resendCountdown, resendCountdown) || other.resendCountdown == resendCountdown));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isCodeSent,phone,user,error,resendCountdown);

@override
String toString() {
  return 'TafakorAuthState(isLoading: $isLoading, isCodeSent: $isCodeSent, phone: $phone, user: $user, error: $error, resendCountdown: $resendCountdown)';
}


}

/// @nodoc
abstract mixin class _$TafakorAuthStateCopyWith<$Res> implements $TafakorAuthStateCopyWith<$Res> {
  factory _$TafakorAuthStateCopyWith(_TafakorAuthState value, $Res Function(_TafakorAuthState) _then) = __$TafakorAuthStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isCodeSent, String? phone, TafakorUser? user, Failure? error, int resendCountdown
});


@override $TafakorUserCopyWith<$Res>? get user;@override $FailureCopyWith<$Res>? get error;

}
/// @nodoc
class __$TafakorAuthStateCopyWithImpl<$Res>
    implements _$TafakorAuthStateCopyWith<$Res> {
  __$TafakorAuthStateCopyWithImpl(this._self, this._then);

  final _TafakorAuthState _self;
  final $Res Function(_TafakorAuthState) _then;

/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isCodeSent = null,Object? phone = freezed,Object? user = freezed,Object? error = freezed,Object? resendCountdown = null,}) {
  return _then(_TafakorAuthState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isCodeSent: null == isCodeSent ? _self.isCodeSent : isCodeSent // ignore: cast_nullable_to_non_nullable
as bool,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as TafakorUser?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Failure?,resendCountdown: null == resendCountdown ? _self.resendCountdown : resendCountdown // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TafakorUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $TafakorUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of TafakorAuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

// dart format on
