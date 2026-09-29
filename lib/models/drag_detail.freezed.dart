// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drag_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DragDetail {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DragDetail);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DragDetail()';
}


}

/// @nodoc
class $DragDetailCopyWith<$Res>  {
$DragDetailCopyWith(DragDetail _, $Res Function(DragDetail) __);
}


/// Adds pattern-matching-related methods to [DragDetail].
extension DragDetailPatterns on DragDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DragDetailCalibrationPoint value)?  calibrationPoint,TResult Function( DragDetailLabel value)?  label,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DragDetailCalibrationPoint() when calibrationPoint != null:
return calibrationPoint(_that);case DragDetailLabel() when label != null:
return label(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DragDetailCalibrationPoint value)  calibrationPoint,required TResult Function( DragDetailLabel value)  label,}){
final _that = this;
switch (_that) {
case DragDetailCalibrationPoint():
return calibrationPoint(_that);case DragDetailLabel():
return label(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DragDetailCalibrationPoint value)?  calibrationPoint,TResult? Function( DragDetailLabel value)?  label,}){
final _that = this;
switch (_that) {
case DragDetailCalibrationPoint() when calibrationPoint != null:
return calibrationPoint(_that);case DragDetailLabel() when label != null:
return label(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( bool isP1)?  calibrationPoint,TResult Function()?  label,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DragDetailCalibrationPoint() when calibrationPoint != null:
return calibrationPoint(_that.isP1);case DragDetailLabel() when label != null:
return label();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( bool isP1)  calibrationPoint,required TResult Function()  label,}) {final _that = this;
switch (_that) {
case DragDetailCalibrationPoint():
return calibrationPoint(_that.isP1);case DragDetailLabel():
return label();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( bool isP1)?  calibrationPoint,TResult? Function()?  label,}) {final _that = this;
switch (_that) {
case DragDetailCalibrationPoint() when calibrationPoint != null:
return calibrationPoint(_that.isP1);case DragDetailLabel() when label != null:
return label();case _:
  return null;

}
}

}

/// @nodoc


class DragDetailCalibrationPoint implements DragDetail {
  const DragDetailCalibrationPoint({required this.isP1});
  

 final  bool isP1;

/// Create a copy of DragDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DragDetailCalibrationPointCopyWith<DragDetailCalibrationPoint> get copyWith => _$DragDetailCalibrationPointCopyWithImpl<DragDetailCalibrationPoint>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DragDetailCalibrationPoint&&(identical(other.isP1, isP1) || other.isP1 == isP1));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isP1);
}

@override
String toString() {
    return 'DragDetail.calibrationPoint(isP1: $isP1)';
}


}

/// @nodoc
abstract mixin class $DragDetailCalibrationPointCopyWith<$Res> implements $DragDetailCopyWith<$Res> {
  factory $DragDetailCalibrationPointCopyWith(DragDetailCalibrationPoint value, $Res Function(DragDetailCalibrationPoint) _then) = _$DragDetailCalibrationPointCopyWithImpl;
@useResult
$Res call({
 bool isP1
});




}
/// @nodoc
class _$DragDetailCalibrationPointCopyWithImpl<$Res>
    implements $DragDetailCalibrationPointCopyWith<$Res> {
  _$DragDetailCalibrationPointCopyWithImpl(this._self, this._then);

  final DragDetailCalibrationPoint _self;
  final $Res Function(DragDetailCalibrationPoint) _then;

/// Create a copy of DragDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isP1 = null,}) {
  return _then(DragDetailCalibrationPoint(
isP1: null == isP1 ? _self.isP1 : isP1 // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class DragDetailLabel implements DragDetail {
  const DragDetailLabel();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DragDetailLabel);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'DragDetail.label()';
}


}




// dart format on
