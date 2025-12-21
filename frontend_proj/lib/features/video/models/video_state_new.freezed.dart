// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_state_new.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoState {

 String? get videoFromUserPath; String? get videoFromServerPath; String? get errorMessage; bool get isLoading; VideoStatus get status; Duration? get videoDuration; bool get showProcessingInfoDialog;// Данные с сервера
 String? get taskId;// === ДАННЫЕ ОТ МОДЕЛИ (реальные) ===
/// Тип упражнения: "pushup", "pullup", "unknown"
 String? get exercise;/// Уверенность модели (0-100%)
 double? get confidence;/// Список проблем с техникой от модели (может быть пустым = хорошая техника)
 List<String>? get techniqueIssues;/// Метрики углов от модели (elbow_angle, torso_angle, knee_angle, shoulders_high)
 Map<String, dynamic>? get metrics;/// Ошибка анализа от модели (если status == "error")
 String? get analysisError;// Для Web: байты файла
 Uint8List? get videoBytes;
/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoStateCopyWith<VideoState> get copyWith => _$VideoStateCopyWithImpl<VideoState>(this as VideoState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoState&&(identical(other.videoFromUserPath, videoFromUserPath) || other.videoFromUserPath == videoFromUserPath)&&(identical(other.videoFromServerPath, videoFromServerPath) || other.videoFromServerPath == videoFromServerPath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.status, status) || other.status == status)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration)&&(identical(other.showProcessingInfoDialog, showProcessingInfoDialog) || other.showProcessingInfoDialog == showProcessingInfoDialog)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.exercise, exercise) || other.exercise == exercise)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other.techniqueIssues, techniqueIssues)&&const DeepCollectionEquality().equals(other.metrics, metrics)&&(identical(other.analysisError, analysisError) || other.analysisError == analysisError)&&const DeepCollectionEquality().equals(other.videoBytes, videoBytes));
}


@override
int get hashCode => Object.hash(runtimeType,videoFromUserPath,videoFromServerPath,errorMessage,isLoading,status,videoDuration,showProcessingInfoDialog,taskId,exercise,confidence,const DeepCollectionEquality().hash(techniqueIssues),const DeepCollectionEquality().hash(metrics),analysisError,const DeepCollectionEquality().hash(videoBytes));

@override
String toString() {
  return 'VideoState(videoFromUserPath: $videoFromUserPath, videoFromServerPath: $videoFromServerPath, errorMessage: $errorMessage, isLoading: $isLoading, status: $status, videoDuration: $videoDuration, showProcessingInfoDialog: $showProcessingInfoDialog, taskId: $taskId, exercise: $exercise, confidence: $confidence, techniqueIssues: $techniqueIssues, metrics: $metrics, analysisError: $analysisError, videoBytes: $videoBytes)';
}


}

/// @nodoc
abstract mixin class $VideoStateCopyWith<$Res>  {
  factory $VideoStateCopyWith(VideoState value, $Res Function(VideoState) _then) = _$VideoStateCopyWithImpl;
@useResult
$Res call({
 String? videoFromUserPath, String? videoFromServerPath, String? errorMessage, bool isLoading, VideoStatus status, Duration? videoDuration, bool showProcessingInfoDialog, String? taskId, String? exercise, double? confidence, List<String>? techniqueIssues, Map<String, dynamic>? metrics, String? analysisError, Uint8List? videoBytes
});




}
/// @nodoc
class _$VideoStateCopyWithImpl<$Res>
    implements $VideoStateCopyWith<$Res> {
  _$VideoStateCopyWithImpl(this._self, this._then);

  final VideoState _self;
  final $Res Function(VideoState) _then;

/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoFromUserPath = freezed,Object? videoFromServerPath = freezed,Object? errorMessage = freezed,Object? isLoading = null,Object? status = null,Object? videoDuration = freezed,Object? showProcessingInfoDialog = null,Object? taskId = freezed,Object? exercise = freezed,Object? confidence = freezed,Object? techniqueIssues = freezed,Object? metrics = freezed,Object? analysisError = freezed,Object? videoBytes = freezed,}) {
  return _then(_self.copyWith(
videoFromUserPath: freezed == videoFromUserPath ? _self.videoFromUserPath : videoFromUserPath // ignore: cast_nullable_to_non_nullable
as String?,videoFromServerPath: freezed == videoFromServerPath ? _self.videoFromServerPath : videoFromServerPath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VideoStatus,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as Duration?,showProcessingInfoDialog: null == showProcessingInfoDialog ? _self.showProcessingInfoDialog : showProcessingInfoDialog // ignore: cast_nullable_to_non_nullable
as bool,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,exercise: freezed == exercise ? _self.exercise : exercise // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,techniqueIssues: freezed == techniqueIssues ? _self.techniqueIssues : techniqueIssues // ignore: cast_nullable_to_non_nullable
as List<String>?,metrics: freezed == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,analysisError: freezed == analysisError ? _self.analysisError : analysisError // ignore: cast_nullable_to_non_nullable
as String?,videoBytes: freezed == videoBytes ? _self.videoBytes : videoBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoState].
extension VideoStatePatterns on VideoState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoState value)  $default,){
final _that = this;
switch (_that) {
case _VideoState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoState value)?  $default,){
final _that = this;
switch (_that) {
case _VideoState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? videoFromUserPath,  String? videoFromServerPath,  String? errorMessage,  bool isLoading,  VideoStatus status,  Duration? videoDuration,  bool showProcessingInfoDialog,  String? taskId,  String? exercise,  double? confidence,  List<String>? techniqueIssues,  Map<String, dynamic>? metrics,  String? analysisError,  Uint8List? videoBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoState() when $default != null:
return $default(_that.videoFromUserPath,_that.videoFromServerPath,_that.errorMessage,_that.isLoading,_that.status,_that.videoDuration,_that.showProcessingInfoDialog,_that.taskId,_that.exercise,_that.confidence,_that.techniqueIssues,_that.metrics,_that.analysisError,_that.videoBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? videoFromUserPath,  String? videoFromServerPath,  String? errorMessage,  bool isLoading,  VideoStatus status,  Duration? videoDuration,  bool showProcessingInfoDialog,  String? taskId,  String? exercise,  double? confidence,  List<String>? techniqueIssues,  Map<String, dynamic>? metrics,  String? analysisError,  Uint8List? videoBytes)  $default,) {final _that = this;
switch (_that) {
case _VideoState():
return $default(_that.videoFromUserPath,_that.videoFromServerPath,_that.errorMessage,_that.isLoading,_that.status,_that.videoDuration,_that.showProcessingInfoDialog,_that.taskId,_that.exercise,_that.confidence,_that.techniqueIssues,_that.metrics,_that.analysisError,_that.videoBytes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? videoFromUserPath,  String? videoFromServerPath,  String? errorMessage,  bool isLoading,  VideoStatus status,  Duration? videoDuration,  bool showProcessingInfoDialog,  String? taskId,  String? exercise,  double? confidence,  List<String>? techniqueIssues,  Map<String, dynamic>? metrics,  String? analysisError,  Uint8List? videoBytes)?  $default,) {final _that = this;
switch (_that) {
case _VideoState() when $default != null:
return $default(_that.videoFromUserPath,_that.videoFromServerPath,_that.errorMessage,_that.isLoading,_that.status,_that.videoDuration,_that.showProcessingInfoDialog,_that.taskId,_that.exercise,_that.confidence,_that.techniqueIssues,_that.metrics,_that.analysisError,_that.videoBytes);case _:
  return null;

}
}

}

/// @nodoc


class _VideoState extends VideoState {
   _VideoState({this.videoFromUserPath, this.videoFromServerPath, this.errorMessage, this.isLoading = false, this.status = VideoStatus.getVideo, this.videoDuration, this.showProcessingInfoDialog = false, this.taskId, this.exercise, this.confidence, final  List<String>? techniqueIssues, final  Map<String, dynamic>? metrics, this.analysisError, this.videoBytes}): _techniqueIssues = techniqueIssues,_metrics = metrics,super._();
  

@override final  String? videoFromUserPath;
@override final  String? videoFromServerPath;
@override final  String? errorMessage;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  VideoStatus status;
@override final  Duration? videoDuration;
@override@JsonKey() final  bool showProcessingInfoDialog;
// Данные с сервера
@override final  String? taskId;
// === ДАННЫЕ ОТ МОДЕЛИ (реальные) ===
/// Тип упражнения: "pushup", "pullup", "unknown"
@override final  String? exercise;
/// Уверенность модели (0-100%)
@override final  double? confidence;
/// Список проблем с техникой от модели (может быть пустым = хорошая техника)
 final  List<String>? _techniqueIssues;
/// Список проблем с техникой от модели (может быть пустым = хорошая техника)
@override List<String>? get techniqueIssues {
  final value = _techniqueIssues;
  if (value == null) return null;
  if (_techniqueIssues is EqualUnmodifiableListView) return _techniqueIssues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Метрики углов от модели (elbow_angle, torso_angle, knee_angle, shoulders_high)
 final  Map<String, dynamic>? _metrics;
/// Метрики углов от модели (elbow_angle, torso_angle, knee_angle, shoulders_high)
@override Map<String, dynamic>? get metrics {
  final value = _metrics;
  if (value == null) return null;
  if (_metrics is EqualUnmodifiableMapView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Ошибка анализа от модели (если status == "error")
@override final  String? analysisError;
// Для Web: байты файла
@override final  Uint8List? videoBytes;

/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoStateCopyWith<_VideoState> get copyWith => __$VideoStateCopyWithImpl<_VideoState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoState&&(identical(other.videoFromUserPath, videoFromUserPath) || other.videoFromUserPath == videoFromUserPath)&&(identical(other.videoFromServerPath, videoFromServerPath) || other.videoFromServerPath == videoFromServerPath)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.status, status) || other.status == status)&&(identical(other.videoDuration, videoDuration) || other.videoDuration == videoDuration)&&(identical(other.showProcessingInfoDialog, showProcessingInfoDialog) || other.showProcessingInfoDialog == showProcessingInfoDialog)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.exercise, exercise) || other.exercise == exercise)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&const DeepCollectionEquality().equals(other._techniqueIssues, _techniqueIssues)&&const DeepCollectionEquality().equals(other._metrics, _metrics)&&(identical(other.analysisError, analysisError) || other.analysisError == analysisError)&&const DeepCollectionEquality().equals(other.videoBytes, videoBytes));
}


@override
int get hashCode => Object.hash(runtimeType,videoFromUserPath,videoFromServerPath,errorMessage,isLoading,status,videoDuration,showProcessingInfoDialog,taskId,exercise,confidence,const DeepCollectionEquality().hash(_techniqueIssues),const DeepCollectionEquality().hash(_metrics),analysisError,const DeepCollectionEquality().hash(videoBytes));

@override
String toString() {
  return 'VideoState(videoFromUserPath: $videoFromUserPath, videoFromServerPath: $videoFromServerPath, errorMessage: $errorMessage, isLoading: $isLoading, status: $status, videoDuration: $videoDuration, showProcessingInfoDialog: $showProcessingInfoDialog, taskId: $taskId, exercise: $exercise, confidence: $confidence, techniqueIssues: $techniqueIssues, metrics: $metrics, analysisError: $analysisError, videoBytes: $videoBytes)';
}


}

/// @nodoc
abstract mixin class _$VideoStateCopyWith<$Res> implements $VideoStateCopyWith<$Res> {
  factory _$VideoStateCopyWith(_VideoState value, $Res Function(_VideoState) _then) = __$VideoStateCopyWithImpl;
@override @useResult
$Res call({
 String? videoFromUserPath, String? videoFromServerPath, String? errorMessage, bool isLoading, VideoStatus status, Duration? videoDuration, bool showProcessingInfoDialog, String? taskId, String? exercise, double? confidence, List<String>? techniqueIssues, Map<String, dynamic>? metrics, String? analysisError, Uint8List? videoBytes
});




}
/// @nodoc
class __$VideoStateCopyWithImpl<$Res>
    implements _$VideoStateCopyWith<$Res> {
  __$VideoStateCopyWithImpl(this._self, this._then);

  final _VideoState _self;
  final $Res Function(_VideoState) _then;

/// Create a copy of VideoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoFromUserPath = freezed,Object? videoFromServerPath = freezed,Object? errorMessage = freezed,Object? isLoading = null,Object? status = null,Object? videoDuration = freezed,Object? showProcessingInfoDialog = null,Object? taskId = freezed,Object? exercise = freezed,Object? confidence = freezed,Object? techniqueIssues = freezed,Object? metrics = freezed,Object? analysisError = freezed,Object? videoBytes = freezed,}) {
  return _then(_VideoState(
videoFromUserPath: freezed == videoFromUserPath ? _self.videoFromUserPath : videoFromUserPath // ignore: cast_nullable_to_non_nullable
as String?,videoFromServerPath: freezed == videoFromServerPath ? _self.videoFromServerPath : videoFromServerPath // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VideoStatus,videoDuration: freezed == videoDuration ? _self.videoDuration : videoDuration // ignore: cast_nullable_to_non_nullable
as Duration?,showProcessingInfoDialog: null == showProcessingInfoDialog ? _self.showProcessingInfoDialog : showProcessingInfoDialog // ignore: cast_nullable_to_non_nullable
as bool,taskId: freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,exercise: freezed == exercise ? _self.exercise : exercise // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,techniqueIssues: freezed == techniqueIssues ? _self._techniqueIssues : techniqueIssues // ignore: cast_nullable_to_non_nullable
as List<String>?,metrics: freezed == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,analysisError: freezed == analysisError ? _self.analysisError : analysisError // ignore: cast_nullable_to_non_nullable
as String?,videoBytes: freezed == videoBytes ? _self.videoBytes : videoBytes // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}


}

// dart format on
