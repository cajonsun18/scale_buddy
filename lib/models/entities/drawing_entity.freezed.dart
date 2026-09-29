// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DrawingEntity {

 String get id; Offset? get p1; Offset? get p2; double? get enteredDistance; String get selectedUnit; bool get isConfirmed; double get labelPosition;
/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingEntityCopyWith<DrawingEntity> get copyWith => _$DrawingEntityCopyWithImpl<DrawingEntity>(this as DrawingEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DrawingEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingEntity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.p1, _this.p1) || other.p1 == _this.p1)&&(identical(other.p2, _this.p2) || other.p2 == _this.p2)&&(identical(other.enteredDistance, _this.enteredDistance) || other.enteredDistance == _this.enteredDistance)&&(identical(other.selectedUnit, _this.selectedUnit) || other.selectedUnit == _this.selectedUnit)&&(identical(other.isConfirmed, _this.isConfirmed) || other.isConfirmed == _this.isConfirmed)&&(identical(other.labelPosition, _this.labelPosition) || other.labelPosition == _this.labelPosition));
}


@override
int get hashCode {
  final _this = this as DrawingEntity;
  return Object.hash(runtimeType,_this.id,_this.p1,_this.p2,_this.enteredDistance,_this.selectedUnit,_this.isConfirmed,_this.labelPosition);
}

@override
String toString() {
  final _this = this as DrawingEntity;
  return 'DrawingEntity(id: ${_this.id}, p1: ${_this.p1}, p2: ${_this.p2}, enteredDistance: ${_this.enteredDistance}, selectedUnit: ${_this.selectedUnit}, isConfirmed: ${_this.isConfirmed}, labelPosition: ${_this.labelPosition})';
}


}

/// @nodoc
abstract mixin class $DrawingEntityCopyWith<$Res>  {
  factory $DrawingEntityCopyWith(DrawingEntity value, $Res Function(DrawingEntity) _then) = _$DrawingEntityCopyWithImpl;
@useResult
$Res call({
 String id, Offset? p1, Offset? p2, double? enteredDistance, String selectedUnit, bool isConfirmed, double labelPosition
});




}
/// @nodoc
class _$DrawingEntityCopyWithImpl<$Res>
    implements $DrawingEntityCopyWith<$Res> {
  _$DrawingEntityCopyWithImpl(this._self, this._then);

  final DrawingEntity _self;
  final $Res Function(DrawingEntity) _then;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? p1 = freezed,Object? p2 = freezed,Object? enteredDistance = freezed,Object? selectedUnit = null,Object? isConfirmed = null,Object? labelPosition = null,}) {
  return _then(DrawingEntity.calibration(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,p1: freezed == p1 ? _self.p1 : p1 // ignore: cast_nullable_to_non_nullable
as Offset?,p2: freezed == p2 ? _self.p2 : p2 // ignore: cast_nullable_to_non_nullable
as Offset?,enteredDistance: freezed == enteredDistance ? _self.enteredDistance : enteredDistance // ignore: cast_nullable_to_non_nullable
as double?,selectedUnit: null == selectedUnit ? _self.selectedUnit : selectedUnit // ignore: cast_nullable_to_non_nullable
as String,isConfirmed: null == isConfirmed ? _self.isConfirmed : isConfirmed // ignore: cast_nullable_to_non_nullable
as bool,labelPosition: null == labelPosition ? _self.labelPosition : labelPosition // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DrawingEntity].
extension DrawingEntityPatterns on DrawingEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CalibrationEntity value)?  calibration,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CalibrationEntity value)  calibration,}){
final _that = this;
switch (_that) {
case CalibrationEntity():
return calibration(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CalibrationEntity value)?  calibration,}){
final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  Offset? p1,  Offset? p2,  double? enteredDistance,  String selectedUnit,  bool isConfirmed,  double labelPosition)?  calibration,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that.id,_that.p1,_that.p2,_that.enteredDistance,_that.selectedUnit,_that.isConfirmed,_that.labelPosition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  Offset? p1,  Offset? p2,  double? enteredDistance,  String selectedUnit,  bool isConfirmed,  double labelPosition)  calibration,}) {final _that = this;
switch (_that) {
case CalibrationEntity():
return calibration(_that.id,_that.p1,_that.p2,_that.enteredDistance,_that.selectedUnit,_that.isConfirmed,_that.labelPosition);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  Offset? p1,  Offset? p2,  double? enteredDistance,  String selectedUnit,  bool isConfirmed,  double labelPosition)?  calibration,}) {final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that.id,_that.p1,_that.p2,_that.enteredDistance,_that.selectedUnit,_that.isConfirmed,_that.labelPosition);case _:
  return null;

}
}

}

/// @nodoc


class CalibrationEntity implements DrawingEntity {
  const CalibrationEntity({required this.id, this.p1, this.p2, this.enteredDistance, this.selectedUnit = 'm', this.isConfirmed = false, this.labelPosition = 0.5});
  

@override final  String id;
@override final  Offset? p1;
@override final  Offset? p2;
@override final  double? enteredDistance;
@override@JsonKey() final  String selectedUnit;
@override@JsonKey() final  bool isConfirmed;
@override@JsonKey() final  double labelPosition;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalibrationEntityCopyWith<CalibrationEntity> get copyWith => _$CalibrationEntityCopyWithImpl<CalibrationEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CalibrationEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.p1, p1) || other.p1 == p1)&&(identical(other.p2, p2) || other.p2 == p2)&&(identical(other.enteredDistance, enteredDistance) || other.enteredDistance == enteredDistance)&&(identical(other.selectedUnit, selectedUnit) || other.selectedUnit == selectedUnit)&&(identical(other.isConfirmed, isConfirmed) || other.isConfirmed == isConfirmed)&&(identical(other.labelPosition, labelPosition) || other.labelPosition == labelPosition));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,p1,p2,enteredDistance,selectedUnit,isConfirmed,labelPosition);
}

@override
String toString() {
    return 'DrawingEntity.calibration(id: $id, p1: $p1, p2: $p2, enteredDistance: $enteredDistance, selectedUnit: $selectedUnit, isConfirmed: $isConfirmed, labelPosition: $labelPosition)';
}


}

/// @nodoc
abstract mixin class $CalibrationEntityCopyWith<$Res> implements $DrawingEntityCopyWith<$Res> {
  factory $CalibrationEntityCopyWith(CalibrationEntity value, $Res Function(CalibrationEntity) _then) = _$CalibrationEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, Offset? p1, Offset? p2, double? enteredDistance, String selectedUnit, bool isConfirmed, double labelPosition
});




}
/// @nodoc
class _$CalibrationEntityCopyWithImpl<$Res>
    implements $CalibrationEntityCopyWith<$Res> {
  _$CalibrationEntityCopyWithImpl(this._self, this._then);

  final CalibrationEntity _self;
  final $Res Function(CalibrationEntity) _then;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? p1 = freezed,Object? p2 = freezed,Object? enteredDistance = freezed,Object? selectedUnit = null,Object? isConfirmed = null,Object? labelPosition = null,}) {
  return _then(CalibrationEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,p1: freezed == p1 ? _self.p1 : p1 // ignore: cast_nullable_to_non_nullable
as Offset?,p2: freezed == p2 ? _self.p2 : p2 // ignore: cast_nullable_to_non_nullable
as Offset?,enteredDistance: freezed == enteredDistance ? _self.enteredDistance : enteredDistance // ignore: cast_nullable_to_non_nullable
as double?,selectedUnit: null == selectedUnit ? _self.selectedUnit : selectedUnit // ignore: cast_nullable_to_non_nullable
as String,isConfirmed: null == isConfirmed ? _self.isConfirmed : isConfirmed // ignore: cast_nullable_to_non_nullable
as bool,labelPosition: null == labelPosition ? _self.labelPosition : labelPosition // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
