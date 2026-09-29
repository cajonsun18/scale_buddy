// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkspaceState {

 LoadedImageInfo? get loadedImage; LoadingStatus get status; WorkspaceError get statusMessage; List<DrawingEntity> get entities; String? get selectedEntityId; DragDetail? get activeDragDetail;
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkspaceStateCopyWith<WorkspaceState> get copyWith => _$WorkspaceStateCopyWithImpl<WorkspaceState>(this as WorkspaceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WorkspaceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkspaceState&&(identical(other.loadedImage, _this.loadedImage) || other.loadedImage == _this.loadedImage)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.statusMessage, _this.statusMessage) || other.statusMessage == _this.statusMessage)&&const DeepCollectionEquality().equals(other.entities, _this.entities)&&(identical(other.selectedEntityId, _this.selectedEntityId) || other.selectedEntityId == _this.selectedEntityId)&&(identical(other.activeDragDetail, _this.activeDragDetail) || other.activeDragDetail == _this.activeDragDetail));
}


@override
int get hashCode {
  final _this = this as WorkspaceState;
  return Object.hash(runtimeType,_this.loadedImage,_this.status,_this.statusMessage,const DeepCollectionEquality().hash(_this.entities),_this.selectedEntityId,_this.activeDragDetail);
}

@override
String toString() {
  final _this = this as WorkspaceState;
  return 'WorkspaceState(loadedImage: ${_this.loadedImage}, status: ${_this.status}, statusMessage: ${_this.statusMessage}, entities: ${_this.entities}, selectedEntityId: ${_this.selectedEntityId}, activeDragDetail: ${_this.activeDragDetail})';
}


}

/// @nodoc
abstract mixin class $WorkspaceStateCopyWith<$Res>  {
  factory $WorkspaceStateCopyWith(WorkspaceState value, $Res Function(WorkspaceState) _then) = _$WorkspaceStateCopyWithImpl;
@useResult
$Res call({
 LoadedImageInfo? loadedImage, LoadingStatus status, WorkspaceError statusMessage, List<DrawingEntity> entities, String? selectedEntityId, DragDetail? activeDragDetail
});


$DragDetailCopyWith<$Res>? get activeDragDetail;

}
/// @nodoc
class _$WorkspaceStateCopyWithImpl<$Res>
    implements $WorkspaceStateCopyWith<$Res> {
  _$WorkspaceStateCopyWithImpl(this._self, this._then);

  final WorkspaceState _self;
  final $Res Function(WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadedImage = freezed,Object? status = null,Object? statusMessage = null,Object? entities = null,Object? selectedEntityId = freezed,Object? activeDragDetail = freezed,}) {
  return _then(WorkspaceState(
loadedImage: freezed == loadedImage ? _self.loadedImage : loadedImage // ignore: cast_nullable_to_non_nullable
as LoadedImageInfo?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LoadingStatus,statusMessage: null == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as WorkspaceError,entities: null == entities ? _self.entities : entities // ignore: cast_nullable_to_non_nullable
as List<DrawingEntity>,selectedEntityId: freezed == selectedEntityId ? _self.selectedEntityId : selectedEntityId // ignore: cast_nullable_to_non_nullable
as String?,activeDragDetail: freezed == activeDragDetail ? _self.activeDragDetail : activeDragDetail // ignore: cast_nullable_to_non_nullable
as DragDetail?,
  ));
}
/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DragDetailCopyWith<$Res>? get activeDragDetail {
    if (_self.activeDragDetail == null) {
    return null;
  }

  return $DragDetailCopyWith<$Res>(_self.activeDragDetail!, (value) {
    return _then(_self.copyWith(activeDragDetail: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkspaceState].
extension WorkspaceStatePatterns on WorkspaceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkspaceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkspaceState value)  $default,){
final _that = this;
switch (_that) {
case _WorkspaceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkspaceState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LoadedImageInfo? loadedImage,  LoadingStatus status,  WorkspaceError statusMessage,  List<DrawingEntity> entities,  String? selectedEntityId,  DragDetail? activeDragDetail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.loadedImage,_that.status,_that.statusMessage,_that.entities,_that.selectedEntityId,_that.activeDragDetail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LoadedImageInfo? loadedImage,  LoadingStatus status,  WorkspaceError statusMessage,  List<DrawingEntity> entities,  String? selectedEntityId,  DragDetail? activeDragDetail)  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState():
return $default(_that.loadedImage,_that.status,_that.statusMessage,_that.entities,_that.selectedEntityId,_that.activeDragDetail);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LoadedImageInfo? loadedImage,  LoadingStatus status,  WorkspaceError statusMessage,  List<DrawingEntity> entities,  String? selectedEntityId,  DragDetail? activeDragDetail)?  $default,) {final _that = this;
switch (_that) {
case _WorkspaceState() when $default != null:
return $default(_that.loadedImage,_that.status,_that.statusMessage,_that.entities,_that.selectedEntityId,_that.activeDragDetail);case _:
  return null;

}
}

}

/// @nodoc


class _WorkspaceState implements WorkspaceState {
  const _WorkspaceState({this.loadedImage, this.status = LoadingStatus.initial, this.statusMessage = WorkspaceError.none,  List<DrawingEntity> entities = const [], this.selectedEntityId, this.activeDragDetail}): _entities = entities;
  

@override final  LoadedImageInfo? loadedImage;
@override@JsonKey() final  LoadingStatus status;
@override@JsonKey() final  WorkspaceError statusMessage;
 final  List<DrawingEntity> _entities;
@override@JsonKey() List<DrawingEntity> get entities {
  if (_entities is EqualUnmodifiableListView) return _entities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entities);
}

@override final  String? selectedEntityId;
@override final  DragDetail? activeDragDetail;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkspaceStateCopyWith<_WorkspaceState> get copyWith => __$WorkspaceStateCopyWithImpl<_WorkspaceState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkspaceState&&(identical(other.loadedImage, loadedImage) || other.loadedImage == loadedImage)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusMessage, statusMessage) || other.statusMessage == statusMessage)&&const DeepCollectionEquality().equals(other.entities, _entities)&&(identical(other.selectedEntityId, selectedEntityId) || other.selectedEntityId == selectedEntityId)&&(identical(other.activeDragDetail, activeDragDetail) || other.activeDragDetail == activeDragDetail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,loadedImage,status,statusMessage,const DeepCollectionEquality().hash(_entities),selectedEntityId,activeDragDetail);
}

@override
String toString() {
    return 'WorkspaceState(loadedImage: $loadedImage, status: $status, statusMessage: $statusMessage, entities: $entities, selectedEntityId: $selectedEntityId, activeDragDetail: $activeDragDetail)';
}


}

/// @nodoc
abstract mixin class _$WorkspaceStateCopyWith<$Res> implements $WorkspaceStateCopyWith<$Res> {
  factory _$WorkspaceStateCopyWith(_WorkspaceState value, $Res Function(_WorkspaceState) _then) = __$WorkspaceStateCopyWithImpl;
@override @useResult
$Res call({
 LoadedImageInfo? loadedImage, LoadingStatus status, WorkspaceError statusMessage, List<DrawingEntity> entities, String? selectedEntityId, DragDetail? activeDragDetail
});


@override $DragDetailCopyWith<$Res>? get activeDragDetail;

}
/// @nodoc
class __$WorkspaceStateCopyWithImpl<$Res>
    implements _$WorkspaceStateCopyWith<$Res> {
  __$WorkspaceStateCopyWithImpl(this._self, this._then);

  final _WorkspaceState _self;
  final $Res Function(_WorkspaceState) _then;

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadedImage = freezed,Object? status = null,Object? statusMessage = null,Object? entities = null,Object? selectedEntityId = freezed,Object? activeDragDetail = freezed,}) {
  return _then(_WorkspaceState(
loadedImage: freezed == loadedImage ? _self.loadedImage : loadedImage // ignore: cast_nullable_to_non_nullable
as LoadedImageInfo?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LoadingStatus,statusMessage: null == statusMessage ? _self.statusMessage : statusMessage // ignore: cast_nullable_to_non_nullable
as WorkspaceError,entities: null == entities ? _self._entities : entities // ignore: cast_nullable_to_non_nullable
as List<DrawingEntity>,selectedEntityId: freezed == selectedEntityId ? _self.selectedEntityId : selectedEntityId // ignore: cast_nullable_to_non_nullable
as String?,activeDragDetail: freezed == activeDragDetail ? _self.activeDragDetail : activeDragDetail // ignore: cast_nullable_to_non_nullable
as DragDetail?,
  ));
}

/// Create a copy of WorkspaceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DragDetailCopyWith<$Res>? get activeDragDetail {
    if (_self.activeDragDetail == null) {
    return null;
  }

  return $DragDetailCopyWith<$Res>(_self.activeDragDetail!, (value) {
    return _then(_self.copyWith(activeDragDetail: value));
  });
}
}

// dart format on
