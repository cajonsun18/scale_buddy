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

 String get id;
/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingEntityCopyWith<DrawingEntity> get copyWith => _$DrawingEntityCopyWithImpl<DrawingEntity>(this as DrawingEntity, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DrawingEntity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingEntity&&(identical(other.id, _this.id) || other.id == _this.id));
}


@override
int get hashCode {
  final _this = this as DrawingEntity;
  return Object.hash(runtimeType,_this.id);
}

@override
String toString() {
  final _this = this as DrawingEntity;
  return 'DrawingEntity(id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $DrawingEntityCopyWith<$Res>  {
  factory $DrawingEntityCopyWith(DrawingEntity value, $Res Function(DrawingEntity) _then) = _$DrawingEntityCopyWithImpl;
@useResult
$Res call({
 String id
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CalibrationEntity value)?  calibration,TResult Function( LineEntity value)?  line,TResult Function( PolygonEntity value)?  polygon,TResult Function( RectangleEntity value)?  rectangle,TResult Function( AngleEntity value)?  angle,TResult Function( PerspectiveEntity value)?  perspective,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that);case LineEntity() when line != null:
return line(_that);case PolygonEntity() when polygon != null:
return polygon(_that);case RectangleEntity() when rectangle != null:
return rectangle(_that);case AngleEntity() when angle != null:
return angle(_that);case PerspectiveEntity() when perspective != null:
return perspective(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CalibrationEntity value)  calibration,required TResult Function( LineEntity value)  line,required TResult Function( PolygonEntity value)  polygon,required TResult Function( RectangleEntity value)  rectangle,required TResult Function( AngleEntity value)  angle,required TResult Function( PerspectiveEntity value)  perspective,}){
final _that = this;
switch (_that) {
case CalibrationEntity():
return calibration(_that);case LineEntity():
return line(_that);case PolygonEntity():
return polygon(_that);case RectangleEntity():
return rectangle(_that);case AngleEntity():
return angle(_that);case PerspectiveEntity():
return perspective(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CalibrationEntity value)?  calibration,TResult? Function( LineEntity value)?  line,TResult? Function( PolygonEntity value)?  polygon,TResult? Function( RectangleEntity value)?  rectangle,TResult? Function( AngleEntity value)?  angle,TResult? Function( PerspectiveEntity value)?  perspective,}){
final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that);case LineEntity() when line != null:
return line(_that);case PolygonEntity() when polygon != null:
return polygon(_that);case RectangleEntity() when rectangle != null:
return rectangle(_that);case AngleEntity() when angle != null:
return angle(_that);case PerspectiveEntity() when perspective != null:
return perspective(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  Offset? p1,  Offset? p2,  double? enteredDistance,  String selectedUnit,  bool isConfirmed,  double labelPosition)?  calibration,TResult Function( String id,  Offset? p1,  Offset? p2,  Color color)?  line,TResult Function( String id,  List<Offset> points,  Color color,  bool isClosed)?  polygon,TResult Function( String id,  Offset? p1,  Offset? p2,  Color color)?  rectangle,TResult Function( String id,  Offset? p1,  Offset? p2,  Color color)?  angle,TResult Function( String id,  List<Offset> points,  Color color)?  perspective,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that.id,_that.p1,_that.p2,_that.enteredDistance,_that.selectedUnit,_that.isConfirmed,_that.labelPosition);case LineEntity() when line != null:
return line(_that.id,_that.p1,_that.p2,_that.color);case PolygonEntity() when polygon != null:
return polygon(_that.id,_that.points,_that.color,_that.isClosed);case RectangleEntity() when rectangle != null:
return rectangle(_that.id,_that.p1,_that.p2,_that.color);case AngleEntity() when angle != null:
return angle(_that.id,_that.p1,_that.p2,_that.color);case PerspectiveEntity() when perspective != null:
return perspective(_that.id,_that.points,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  Offset? p1,  Offset? p2,  double? enteredDistance,  String selectedUnit,  bool isConfirmed,  double labelPosition)  calibration,required TResult Function( String id,  Offset? p1,  Offset? p2,  Color color)  line,required TResult Function( String id,  List<Offset> points,  Color color,  bool isClosed)  polygon,required TResult Function( String id,  Offset? p1,  Offset? p2,  Color color)  rectangle,required TResult Function( String id,  Offset? p1,  Offset? p2,  Color color)  angle,required TResult Function( String id,  List<Offset> points,  Color color)  perspective,}) {final _that = this;
switch (_that) {
case CalibrationEntity():
return calibration(_that.id,_that.p1,_that.p2,_that.enteredDistance,_that.selectedUnit,_that.isConfirmed,_that.labelPosition);case LineEntity():
return line(_that.id,_that.p1,_that.p2,_that.color);case PolygonEntity():
return polygon(_that.id,_that.points,_that.color,_that.isClosed);case RectangleEntity():
return rectangle(_that.id,_that.p1,_that.p2,_that.color);case AngleEntity():
return angle(_that.id,_that.p1,_that.p2,_that.color);case PerspectiveEntity():
return perspective(_that.id,_that.points,_that.color);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  Offset? p1,  Offset? p2,  double? enteredDistance,  String selectedUnit,  bool isConfirmed,  double labelPosition)?  calibration,TResult? Function( String id,  Offset? p1,  Offset? p2,  Color color)?  line,TResult? Function( String id,  List<Offset> points,  Color color,  bool isClosed)?  polygon,TResult? Function( String id,  Offset? p1,  Offset? p2,  Color color)?  rectangle,TResult? Function( String id,  Offset? p1,  Offset? p2,  Color color)?  angle,TResult? Function( String id,  List<Offset> points,  Color color)?  perspective,}) {final _that = this;
switch (_that) {
case CalibrationEntity() when calibration != null:
return calibration(_that.id,_that.p1,_that.p2,_that.enteredDistance,_that.selectedUnit,_that.isConfirmed,_that.labelPosition);case LineEntity() when line != null:
return line(_that.id,_that.p1,_that.p2,_that.color);case PolygonEntity() when polygon != null:
return polygon(_that.id,_that.points,_that.color,_that.isClosed);case RectangleEntity() when rectangle != null:
return rectangle(_that.id,_that.p1,_that.p2,_that.color);case AngleEntity() when angle != null:
return angle(_that.id,_that.p1,_that.p2,_that.color);case PerspectiveEntity() when perspective != null:
return perspective(_that.id,_that.points,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class CalibrationEntity implements DrawingEntity {
  const CalibrationEntity({required this.id, this.p1, this.p2, this.enteredDistance, this.selectedUnit = 'm', this.isConfirmed = false, this.labelPosition = 0.5});
  

@override final  String id;
 final  Offset? p1;
 final  Offset? p2;
 final  double? enteredDistance;
@JsonKey() final  String selectedUnit;
@JsonKey() final  bool isConfirmed;
@JsonKey() final  double labelPosition;

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

/// @nodoc


class LineEntity implements DrawingEntity {
  const LineEntity({required this.id, this.p1, this.p2, required this.color});
  

@override final  String id;
 final  Offset? p1;
 final  Offset? p2;
 final  Color color;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineEntityCopyWith<LineEntity> get copyWith => _$LineEntityCopyWithImpl<LineEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LineEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.p1, p1) || other.p1 == p1)&&(identical(other.p2, p2) || other.p2 == p2)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,p1,p2,color);
}

@override
String toString() {
    return 'DrawingEntity.line(id: $id, p1: $p1, p2: $p2, color: $color)';
}


}

/// @nodoc
abstract mixin class $LineEntityCopyWith<$Res> implements $DrawingEntityCopyWith<$Res> {
  factory $LineEntityCopyWith(LineEntity value, $Res Function(LineEntity) _then) = _$LineEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, Offset? p1, Offset? p2, Color color
});




}
/// @nodoc
class _$LineEntityCopyWithImpl<$Res>
    implements $LineEntityCopyWith<$Res> {
  _$LineEntityCopyWithImpl(this._self, this._then);

  final LineEntity _self;
  final $Res Function(LineEntity) _then;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? p1 = freezed,Object? p2 = freezed,Object? color = null,}) {
  return _then(LineEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,p1: freezed == p1 ? _self.p1 : p1 // ignore: cast_nullable_to_non_nullable
as Offset?,p2: freezed == p2 ? _self.p2 : p2 // ignore: cast_nullable_to_non_nullable
as Offset?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

/// @nodoc


class PolygonEntity implements DrawingEntity {
  const PolygonEntity({required this.id, required  List<Offset> points, required this.color, this.isClosed = false}): _points = points;
  

@override final  String id;
 final  List<Offset> _points;
 List<Offset> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

 final  Color color;
@JsonKey() final  bool isClosed;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolygonEntityCopyWith<PolygonEntity> get copyWith => _$PolygonEntityCopyWithImpl<PolygonEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PolygonEntity&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.points, _points)&&(identical(other.color, color) || other.color == color)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_points),color,isClosed);
}

@override
String toString() {
    return 'DrawingEntity.polygon(id: $id, points: $points, color: $color, isClosed: $isClosed)';
}


}

/// @nodoc
abstract mixin class $PolygonEntityCopyWith<$Res> implements $DrawingEntityCopyWith<$Res> {
  factory $PolygonEntityCopyWith(PolygonEntity value, $Res Function(PolygonEntity) _then) = _$PolygonEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, List<Offset> points, Color color, bool isClosed
});




}
/// @nodoc
class _$PolygonEntityCopyWithImpl<$Res>
    implements $PolygonEntityCopyWith<$Res> {
  _$PolygonEntityCopyWithImpl(this._self, this._then);

  final PolygonEntity _self;
  final $Res Function(PolygonEntity) _then;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? points = null,Object? color = null,Object? isClosed = null,}) {
  return _then(PolygonEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<Offset>,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class RectangleEntity implements DrawingEntity {
  const RectangleEntity({required this.id, this.p1, this.p2, required this.color});
  

@override final  String id;
 final  Offset? p1;
 final  Offset? p2;
 final  Color color;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RectangleEntityCopyWith<RectangleEntity> get copyWith => _$RectangleEntityCopyWithImpl<RectangleEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RectangleEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.p1, p1) || other.p1 == p1)&&(identical(other.p2, p2) || other.p2 == p2)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,p1,p2,color);
}

@override
String toString() {
    return 'DrawingEntity.rectangle(id: $id, p1: $p1, p2: $p2, color: $color)';
}


}

/// @nodoc
abstract mixin class $RectangleEntityCopyWith<$Res> implements $DrawingEntityCopyWith<$Res> {
  factory $RectangleEntityCopyWith(RectangleEntity value, $Res Function(RectangleEntity) _then) = _$RectangleEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, Offset? p1, Offset? p2, Color color
});




}
/// @nodoc
class _$RectangleEntityCopyWithImpl<$Res>
    implements $RectangleEntityCopyWith<$Res> {
  _$RectangleEntityCopyWithImpl(this._self, this._then);

  final RectangleEntity _self;
  final $Res Function(RectangleEntity) _then;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? p1 = freezed,Object? p2 = freezed,Object? color = null,}) {
  return _then(RectangleEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,p1: freezed == p1 ? _self.p1 : p1 // ignore: cast_nullable_to_non_nullable
as Offset?,p2: freezed == p2 ? _self.p2 : p2 // ignore: cast_nullable_to_non_nullable
as Offset?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

/// @nodoc


class AngleEntity implements DrawingEntity {
  const AngleEntity({required this.id, this.p1, this.p2, required this.color});
  

@override final  String id;
 final  Offset? p1;
 final  Offset? p2;
 final  Color color;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AngleEntityCopyWith<AngleEntity> get copyWith => _$AngleEntityCopyWithImpl<AngleEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AngleEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.p1, p1) || other.p1 == p1)&&(identical(other.p2, p2) || other.p2 == p2)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,p1,p2,color);
}

@override
String toString() {
    return 'DrawingEntity.angle(id: $id, p1: $p1, p2: $p2, color: $color)';
}


}

/// @nodoc
abstract mixin class $AngleEntityCopyWith<$Res> implements $DrawingEntityCopyWith<$Res> {
  factory $AngleEntityCopyWith(AngleEntity value, $Res Function(AngleEntity) _then) = _$AngleEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, Offset? p1, Offset? p2, Color color
});




}
/// @nodoc
class _$AngleEntityCopyWithImpl<$Res>
    implements $AngleEntityCopyWith<$Res> {
  _$AngleEntityCopyWithImpl(this._self, this._then);

  final AngleEntity _self;
  final $Res Function(AngleEntity) _then;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? p1 = freezed,Object? p2 = freezed,Object? color = null,}) {
  return _then(AngleEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,p1: freezed == p1 ? _self.p1 : p1 // ignore: cast_nullable_to_non_nullable
as Offset?,p2: freezed == p2 ? _self.p2 : p2 // ignore: cast_nullable_to_non_nullable
as Offset?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

/// @nodoc


class PerspectiveEntity implements DrawingEntity {
  const PerspectiveEntity({required this.id, required  List<Offset> points, required this.color}): _points = points;
  

@override final  String id;
 final  List<Offset> _points;
 List<Offset> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

 final  Color color;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerspectiveEntityCopyWith<PerspectiveEntity> get copyWith => _$PerspectiveEntityCopyWithImpl<PerspectiveEntity>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PerspectiveEntity&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.points, _points)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_points),color);
}

@override
String toString() {
    return 'DrawingEntity.perspective(id: $id, points: $points, color: $color)';
}


}

/// @nodoc
abstract mixin class $PerspectiveEntityCopyWith<$Res> implements $DrawingEntityCopyWith<$Res> {
  factory $PerspectiveEntityCopyWith(PerspectiveEntity value, $Res Function(PerspectiveEntity) _then) = _$PerspectiveEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, List<Offset> points, Color color
});




}
/// @nodoc
class _$PerspectiveEntityCopyWithImpl<$Res>
    implements $PerspectiveEntityCopyWith<$Res> {
  _$PerspectiveEntityCopyWithImpl(this._self, this._then);

  final PerspectiveEntity _self;
  final $Res Function(PerspectiveEntity) _then;

/// Create a copy of DrawingEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? points = null,Object? color = null,}) {
  return _then(PerspectiveEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<Offset>,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

// dart format on
