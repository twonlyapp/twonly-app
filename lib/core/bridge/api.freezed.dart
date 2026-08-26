// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServerResultEmpty {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ServerResultEmpty()';
}


}

/// @nodoc
class $ServerResultEmptyCopyWith<$Res>  {
$ServerResultEmptyCopyWith(ServerResultEmpty _, $Res Function(ServerResultEmpty) __);
}


/// Adds pattern-matching-related methods to [ServerResultEmpty].
extension ServerResultEmptyPatterns on ServerResultEmpty {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ServerResultEmpty_Ok value)?  ok,TResult Function( ServerResultEmpty_ErrorCode value)?  errorCode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ServerResultEmpty_Ok() when ok != null:
return ok(_that);case ServerResultEmpty_ErrorCode() when errorCode != null:
return errorCode(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ServerResultEmpty_Ok value)  ok,required TResult Function( ServerResultEmpty_ErrorCode value)  errorCode,}){
final _that = this;
switch (_that) {
case ServerResultEmpty_Ok():
return ok(_that);case ServerResultEmpty_ErrorCode():
return errorCode(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ServerResultEmpty_Ok value)?  ok,TResult? Function( ServerResultEmpty_ErrorCode value)?  errorCode,}){
final _that = this;
switch (_that) {
case ServerResultEmpty_Ok() when ok != null:
return ok(_that);case ServerResultEmpty_ErrorCode() when errorCode != null:
return errorCode(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function( int field0)?  errorCode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ServerResultEmpty_Ok() when ok != null:
return ok();case ServerResultEmpty_ErrorCode() when errorCode != null:
return errorCode(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function( int field0)  errorCode,}) {final _that = this;
switch (_that) {
case ServerResultEmpty_Ok():
return ok();case ServerResultEmpty_ErrorCode():
return errorCode(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function( int field0)?  errorCode,}) {final _that = this;
switch (_that) {
case ServerResultEmpty_Ok() when ok != null:
return ok();case ServerResultEmpty_ErrorCode() when errorCode != null:
return errorCode(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class ServerResultEmpty_Ok extends ServerResultEmpty {
  const ServerResultEmpty_Ok(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultEmpty_Ok);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ServerResultEmpty.ok()';
}


}




/// @nodoc


class ServerResultEmpty_ErrorCode extends ServerResultEmpty {
  const ServerResultEmpty_ErrorCode(this.field0): super._();
  

 final  int field0;

/// Create a copy of ServerResultEmpty
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerResultEmpty_ErrorCodeCopyWith<ServerResultEmpty_ErrorCode> get copyWith => _$ServerResultEmpty_ErrorCodeCopyWithImpl<ServerResultEmpty_ErrorCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultEmpty_ErrorCode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ServerResultEmpty.errorCode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ServerResultEmpty_ErrorCodeCopyWith<$Res> implements $ServerResultEmptyCopyWith<$Res> {
  factory $ServerResultEmpty_ErrorCodeCopyWith(ServerResultEmpty_ErrorCode value, $Res Function(ServerResultEmpty_ErrorCode) _then) = _$ServerResultEmpty_ErrorCodeCopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$ServerResultEmpty_ErrorCodeCopyWithImpl<$Res>
    implements $ServerResultEmpty_ErrorCodeCopyWith<$Res> {
  _$ServerResultEmpty_ErrorCodeCopyWithImpl(this._self, this._then);

  final ServerResultEmpty_ErrorCode _self;
  final $Res Function(ServerResultEmpty_ErrorCode) _then;

/// Create a copy of ServerResultEmpty
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ServerResultEmpty_ErrorCode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ServerResultI64 {

 int get field0;
/// Create a copy of ServerResultI64
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerResultI64CopyWith<ServerResultI64> get copyWith => _$ServerResultI64CopyWithImpl<ServerResultI64>(this as ServerResultI64, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultI64&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ServerResultI64(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ServerResultI64CopyWith<$Res>  {
  factory $ServerResultI64CopyWith(ServerResultI64 value, $Res Function(ServerResultI64) _then) = _$ServerResultI64CopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$ServerResultI64CopyWithImpl<$Res>
    implements $ServerResultI64CopyWith<$Res> {
  _$ServerResultI64CopyWithImpl(this._self, this._then);

  final ServerResultI64 _self;
  final $Res Function(ServerResultI64) _then;

/// Create a copy of ServerResultI64
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field0 = null,}) {
  return _then(_self.copyWith(
field0: null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ServerResultI64].
extension ServerResultI64Patterns on ServerResultI64 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ServerResultI64_Ok value)?  ok,TResult Function( ServerResultI64_ErrorCode value)?  errorCode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ServerResultI64_Ok() when ok != null:
return ok(_that);case ServerResultI64_ErrorCode() when errorCode != null:
return errorCode(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ServerResultI64_Ok value)  ok,required TResult Function( ServerResultI64_ErrorCode value)  errorCode,}){
final _that = this;
switch (_that) {
case ServerResultI64_Ok():
return ok(_that);case ServerResultI64_ErrorCode():
return errorCode(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ServerResultI64_Ok value)?  ok,TResult? Function( ServerResultI64_ErrorCode value)?  errorCode,}){
final _that = this;
switch (_that) {
case ServerResultI64_Ok() when ok != null:
return ok(_that);case ServerResultI64_ErrorCode() when errorCode != null:
return errorCode(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PlatformInt64 field0)?  ok,TResult Function( int field0)?  errorCode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ServerResultI64_Ok() when ok != null:
return ok(_that.field0);case ServerResultI64_ErrorCode() when errorCode != null:
return errorCode(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PlatformInt64 field0)  ok,required TResult Function( int field0)  errorCode,}) {final _that = this;
switch (_that) {
case ServerResultI64_Ok():
return ok(_that.field0);case ServerResultI64_ErrorCode():
return errorCode(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PlatformInt64 field0)?  ok,TResult? Function( int field0)?  errorCode,}) {final _that = this;
switch (_that) {
case ServerResultI64_Ok() when ok != null:
return ok(_that.field0);case ServerResultI64_ErrorCode() when errorCode != null:
return errorCode(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class ServerResultI64_Ok extends ServerResultI64 {
  const ServerResultI64_Ok(this.field0): super._();
  

@override final  PlatformInt64 field0;

/// Create a copy of ServerResultI64
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerResultI64_OkCopyWith<ServerResultI64_Ok> get copyWith => _$ServerResultI64_OkCopyWithImpl<ServerResultI64_Ok>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultI64_Ok&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ServerResultI64.ok(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ServerResultI64_OkCopyWith<$Res> implements $ServerResultI64CopyWith<$Res> {
  factory $ServerResultI64_OkCopyWith(ServerResultI64_Ok value, $Res Function(ServerResultI64_Ok) _then) = _$ServerResultI64_OkCopyWithImpl;
@override @useResult
$Res call({
 PlatformInt64 field0
});




}
/// @nodoc
class _$ServerResultI64_OkCopyWithImpl<$Res>
    implements $ServerResultI64_OkCopyWith<$Res> {
  _$ServerResultI64_OkCopyWithImpl(this._self, this._then);

  final ServerResultI64_Ok _self;
  final $Res Function(ServerResultI64_Ok) _then;

/// Create a copy of ServerResultI64
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ServerResultI64_Ok(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as PlatformInt64,
  ));
}


}

/// @nodoc


class ServerResultI64_ErrorCode extends ServerResultI64 {
  const ServerResultI64_ErrorCode(this.field0): super._();
  

@override final  int field0;

/// Create a copy of ServerResultI64
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerResultI64_ErrorCodeCopyWith<ServerResultI64_ErrorCode> get copyWith => _$ServerResultI64_ErrorCodeCopyWithImpl<ServerResultI64_ErrorCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultI64_ErrorCode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ServerResultI64.errorCode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ServerResultI64_ErrorCodeCopyWith<$Res> implements $ServerResultI64CopyWith<$Res> {
  factory $ServerResultI64_ErrorCodeCopyWith(ServerResultI64_ErrorCode value, $Res Function(ServerResultI64_ErrorCode) _then) = _$ServerResultI64_ErrorCodeCopyWithImpl;
@override @useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$ServerResultI64_ErrorCodeCopyWithImpl<$Res>
    implements $ServerResultI64_ErrorCodeCopyWith<$Res> {
  _$ServerResultI64_ErrorCodeCopyWithImpl(this._self, this._then);

  final ServerResultI64_ErrorCode _self;
  final $Res Function(ServerResultI64_ErrorCode) _then;

/// Create a copy of ServerResultI64
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ServerResultI64_ErrorCode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ServerResultVecU8 {

 Object get field0;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultVecU8&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'ServerResultVecU8(field0: $field0)';
}


}

/// @nodoc
class $ServerResultVecU8CopyWith<$Res>  {
$ServerResultVecU8CopyWith(ServerResultVecU8 _, $Res Function(ServerResultVecU8) __);
}


/// Adds pattern-matching-related methods to [ServerResultVecU8].
extension ServerResultVecU8Patterns on ServerResultVecU8 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ServerResultVecU8_Ok value)?  ok,TResult Function( ServerResultVecU8_ErrorCode value)?  errorCode,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ServerResultVecU8_Ok() when ok != null:
return ok(_that);case ServerResultVecU8_ErrorCode() when errorCode != null:
return errorCode(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ServerResultVecU8_Ok value)  ok,required TResult Function( ServerResultVecU8_ErrorCode value)  errorCode,}){
final _that = this;
switch (_that) {
case ServerResultVecU8_Ok():
return ok(_that);case ServerResultVecU8_ErrorCode():
return errorCode(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ServerResultVecU8_Ok value)?  ok,TResult? Function( ServerResultVecU8_ErrorCode value)?  errorCode,}){
final _that = this;
switch (_that) {
case ServerResultVecU8_Ok() when ok != null:
return ok(_that);case ServerResultVecU8_ErrorCode() when errorCode != null:
return errorCode(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Uint8List field0)?  ok,TResult Function( int field0)?  errorCode,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ServerResultVecU8_Ok() when ok != null:
return ok(_that.field0);case ServerResultVecU8_ErrorCode() when errorCode != null:
return errorCode(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Uint8List field0)  ok,required TResult Function( int field0)  errorCode,}) {final _that = this;
switch (_that) {
case ServerResultVecU8_Ok():
return ok(_that.field0);case ServerResultVecU8_ErrorCode():
return errorCode(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Uint8List field0)?  ok,TResult? Function( int field0)?  errorCode,}) {final _that = this;
switch (_that) {
case ServerResultVecU8_Ok() when ok != null:
return ok(_that.field0);case ServerResultVecU8_ErrorCode() when errorCode != null:
return errorCode(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class ServerResultVecU8_Ok extends ServerResultVecU8 {
  const ServerResultVecU8_Ok(this.field0): super._();
  

@override final  Uint8List field0;

/// Create a copy of ServerResultVecU8
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerResultVecU8_OkCopyWith<ServerResultVecU8_Ok> get copyWith => _$ServerResultVecU8_OkCopyWithImpl<ServerResultVecU8_Ok>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultVecU8_Ok&&const DeepCollectionEquality().equals(other.field0, field0));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(field0));

@override
String toString() {
  return 'ServerResultVecU8.ok(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ServerResultVecU8_OkCopyWith<$Res> implements $ServerResultVecU8CopyWith<$Res> {
  factory $ServerResultVecU8_OkCopyWith(ServerResultVecU8_Ok value, $Res Function(ServerResultVecU8_Ok) _then) = _$ServerResultVecU8_OkCopyWithImpl;
@useResult
$Res call({
 Uint8List field0
});




}
/// @nodoc
class _$ServerResultVecU8_OkCopyWithImpl<$Res>
    implements $ServerResultVecU8_OkCopyWith<$Res> {
  _$ServerResultVecU8_OkCopyWithImpl(this._self, this._then);

  final ServerResultVecU8_Ok _self;
  final $Res Function(ServerResultVecU8_Ok) _then;

/// Create a copy of ServerResultVecU8
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ServerResultVecU8_Ok(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

/// @nodoc


class ServerResultVecU8_ErrorCode extends ServerResultVecU8 {
  const ServerResultVecU8_ErrorCode(this.field0): super._();
  

@override final  int field0;

/// Create a copy of ServerResultVecU8
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerResultVecU8_ErrorCodeCopyWith<ServerResultVecU8_ErrorCode> get copyWith => _$ServerResultVecU8_ErrorCodeCopyWithImpl<ServerResultVecU8_ErrorCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerResultVecU8_ErrorCode&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'ServerResultVecU8.errorCode(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $ServerResultVecU8_ErrorCodeCopyWith<$Res> implements $ServerResultVecU8CopyWith<$Res> {
  factory $ServerResultVecU8_ErrorCodeCopyWith(ServerResultVecU8_ErrorCode value, $Res Function(ServerResultVecU8_ErrorCode) _then) = _$ServerResultVecU8_ErrorCodeCopyWithImpl;
@useResult
$Res call({
 int field0
});




}
/// @nodoc
class _$ServerResultVecU8_ErrorCodeCopyWithImpl<$Res>
    implements $ServerResultVecU8_ErrorCodeCopyWith<$Res> {
  _$ServerResultVecU8_ErrorCodeCopyWithImpl(this._self, this._then);

  final ServerResultVecU8_ErrorCode _self;
  final $Res Function(ServerResultVecU8_ErrorCode) _then;

/// Create a copy of ServerResultVecU8
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(ServerResultVecU8_ErrorCode(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
