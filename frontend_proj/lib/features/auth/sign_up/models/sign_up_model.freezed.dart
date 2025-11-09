// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_up_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignUpState {

 bool get checkPolitics; String? get emailError; String? get passwordError; String? get checkPoliticsError; String? get confirmPasswordError; bool get isPasswordVisible; bool get isConfirmPasswordVisible; bool get isLoading;
/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpStateCopyWith<SignUpState> get copyWith => _$SignUpStateCopyWithImpl<SignUpState>(this as SignUpState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpState&&(identical(other.checkPolitics, checkPolitics) || other.checkPolitics == checkPolitics)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.checkPoliticsError, checkPoliticsError) || other.checkPoliticsError == checkPoliticsError)&&(identical(other.confirmPasswordError, confirmPasswordError) || other.confirmPasswordError == confirmPasswordError)&&(identical(other.isPasswordVisible, isPasswordVisible) || other.isPasswordVisible == isPasswordVisible)&&(identical(other.isConfirmPasswordVisible, isConfirmPasswordVisible) || other.isConfirmPasswordVisible == isConfirmPasswordVisible)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,checkPolitics,emailError,passwordError,checkPoliticsError,confirmPasswordError,isPasswordVisible,isConfirmPasswordVisible,isLoading);

@override
String toString() {
  return 'SignUpState(checkPolitics: $checkPolitics, emailError: $emailError, passwordError: $passwordError, checkPoliticsError: $checkPoliticsError, confirmPasswordError: $confirmPasswordError, isPasswordVisible: $isPasswordVisible, isConfirmPasswordVisible: $isConfirmPasswordVisible, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $SignUpStateCopyWith<$Res>  {
  factory $SignUpStateCopyWith(SignUpState value, $Res Function(SignUpState) _then) = _$SignUpStateCopyWithImpl;
@useResult
$Res call({
 bool checkPolitics, String? emailError, String? passwordError, String? checkPoliticsError, String? confirmPasswordError, bool isPasswordVisible, bool isConfirmPasswordVisible, bool isLoading
});




}
/// @nodoc
class _$SignUpStateCopyWithImpl<$Res>
    implements $SignUpStateCopyWith<$Res> {
  _$SignUpStateCopyWithImpl(this._self, this._then);

  final SignUpState _self;
  final $Res Function(SignUpState) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? checkPolitics = null,Object? emailError = freezed,Object? passwordError = freezed,Object? checkPoliticsError = freezed,Object? confirmPasswordError = freezed,Object? isPasswordVisible = null,Object? isConfirmPasswordVisible = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
checkPolitics: null == checkPolitics ? _self.checkPolitics : checkPolitics // ignore: cast_nullable_to_non_nullable
as bool,emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String?,passwordError: freezed == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as String?,checkPoliticsError: freezed == checkPoliticsError ? _self.checkPoliticsError : checkPoliticsError // ignore: cast_nullable_to_non_nullable
as String?,confirmPasswordError: freezed == confirmPasswordError ? _self.confirmPasswordError : confirmPasswordError // ignore: cast_nullable_to_non_nullable
as String?,isPasswordVisible: null == isPasswordVisible ? _self.isPasswordVisible : isPasswordVisible // ignore: cast_nullable_to_non_nullable
as bool,isConfirmPasswordVisible: null == isConfirmPasswordVisible ? _self.isConfirmPasswordVisible : isConfirmPasswordVisible // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SignUpState].
extension SignUpStatePatterns on SignUpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignUpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignUpState value)  $default,){
final _that = this;
switch (_that) {
case _SignUpState():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignUpState value)?  $default,){
final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool checkPolitics,  String? emailError,  String? passwordError,  String? checkPoliticsError,  String? confirmPasswordError,  bool isPasswordVisible,  bool isConfirmPasswordVisible,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
return $default(_that.checkPolitics,_that.emailError,_that.passwordError,_that.checkPoliticsError,_that.confirmPasswordError,_that.isPasswordVisible,_that.isConfirmPasswordVisible,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool checkPolitics,  String? emailError,  String? passwordError,  String? checkPoliticsError,  String? confirmPasswordError,  bool isPasswordVisible,  bool isConfirmPasswordVisible,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _SignUpState():
return $default(_that.checkPolitics,_that.emailError,_that.passwordError,_that.checkPoliticsError,_that.confirmPasswordError,_that.isPasswordVisible,_that.isConfirmPasswordVisible,_that.isLoading);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool checkPolitics,  String? emailError,  String? passwordError,  String? checkPoliticsError,  String? confirmPasswordError,  bool isPasswordVisible,  bool isConfirmPasswordVisible,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
return $default(_that.checkPolitics,_that.emailError,_that.passwordError,_that.checkPoliticsError,_that.confirmPasswordError,_that.isPasswordVisible,_that.isConfirmPasswordVisible,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _SignUpState extends SignUpState {
  const _SignUpState({this.checkPolitics = false, this.emailError, this.passwordError, this.checkPoliticsError, this.confirmPasswordError, this.isPasswordVisible = false, this.isConfirmPasswordVisible = false, this.isLoading = false}): super._();
  

@override@JsonKey() final  bool checkPolitics;
@override final  String? emailError;
@override final  String? passwordError;
@override final  String? checkPoliticsError;
@override final  String? confirmPasswordError;
@override@JsonKey() final  bool isPasswordVisible;
@override@JsonKey() final  bool isConfirmPasswordVisible;
@override@JsonKey() final  bool isLoading;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignUpStateCopyWith<_SignUpState> get copyWith => __$SignUpStateCopyWithImpl<_SignUpState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignUpState&&(identical(other.checkPolitics, checkPolitics) || other.checkPolitics == checkPolitics)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.checkPoliticsError, checkPoliticsError) || other.checkPoliticsError == checkPoliticsError)&&(identical(other.confirmPasswordError, confirmPasswordError) || other.confirmPasswordError == confirmPasswordError)&&(identical(other.isPasswordVisible, isPasswordVisible) || other.isPasswordVisible == isPasswordVisible)&&(identical(other.isConfirmPasswordVisible, isConfirmPasswordVisible) || other.isConfirmPasswordVisible == isConfirmPasswordVisible)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,checkPolitics,emailError,passwordError,checkPoliticsError,confirmPasswordError,isPasswordVisible,isConfirmPasswordVisible,isLoading);

@override
String toString() {
  return 'SignUpState(checkPolitics: $checkPolitics, emailError: $emailError, passwordError: $passwordError, checkPoliticsError: $checkPoliticsError, confirmPasswordError: $confirmPasswordError, isPasswordVisible: $isPasswordVisible, isConfirmPasswordVisible: $isConfirmPasswordVisible, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$SignUpStateCopyWith<$Res> implements $SignUpStateCopyWith<$Res> {
  factory _$SignUpStateCopyWith(_SignUpState value, $Res Function(_SignUpState) _then) = __$SignUpStateCopyWithImpl;
@override @useResult
$Res call({
 bool checkPolitics, String? emailError, String? passwordError, String? checkPoliticsError, String? confirmPasswordError, bool isPasswordVisible, bool isConfirmPasswordVisible, bool isLoading
});




}
/// @nodoc
class __$SignUpStateCopyWithImpl<$Res>
    implements _$SignUpStateCopyWith<$Res> {
  __$SignUpStateCopyWithImpl(this._self, this._then);

  final _SignUpState _self;
  final $Res Function(_SignUpState) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? checkPolitics = null,Object? emailError = freezed,Object? passwordError = freezed,Object? checkPoliticsError = freezed,Object? confirmPasswordError = freezed,Object? isPasswordVisible = null,Object? isConfirmPasswordVisible = null,Object? isLoading = null,}) {
  return _then(_SignUpState(
checkPolitics: null == checkPolitics ? _self.checkPolitics : checkPolitics // ignore: cast_nullable_to_non_nullable
as bool,emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String?,passwordError: freezed == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as String?,checkPoliticsError: freezed == checkPoliticsError ? _self.checkPoliticsError : checkPoliticsError // ignore: cast_nullable_to_non_nullable
as String?,confirmPasswordError: freezed == confirmPasswordError ? _self.confirmPasswordError : confirmPasswordError // ignore: cast_nullable_to_non_nullable
as String?,isPasswordVisible: null == isPasswordVisible ? _self.isPasswordVisible : isPasswordVisible // ignore: cast_nullable_to_non_nullable
as bool,isConfirmPasswordVisible: null == isConfirmPasswordVisible ? _self.isConfirmPasswordVisible : isConfirmPasswordVisible // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
