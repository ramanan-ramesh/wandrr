// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_plan_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ItineraryPlanData {
  String get tripId => throw _privateConstructorUsedError;
  DateTime get day => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  List<Sight> get sights => throw _privateConstructorUsedError;
  List<String> get notes => throw _privateConstructorUsedError;
  List<CheckList> get checkLists => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryPlanData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryPlanDataCopyWith<ItineraryPlanData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryPlanDataCopyWith<$Res> {
  factory $ItineraryPlanDataCopyWith(
          ItineraryPlanData value, $Res Function(ItineraryPlanData) then) =
      _$ItineraryPlanDataCopyWithImpl<$Res, ItineraryPlanData>;
  @useResult
  $Res call(
      {String tripId,
      DateTime day,
      String? id,
      List<Sight> sights,
      List<String> notes,
      List<CheckList> checkLists});
}

/// @nodoc
class _$ItineraryPlanDataCopyWithImpl<$Res, $Val extends ItineraryPlanData>
    implements $ItineraryPlanDataCopyWith<$Res> {
  _$ItineraryPlanDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryPlanData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? day = null,
    Object? id = freezed,
    Object? sights = null,
    Object? notes = null,
    Object? checkLists = null,
  }) {
    return _then(_value.copyWith(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      sights: null == sights
          ? _value.sights
          : sights // ignore: cast_nullable_to_non_nullable
              as List<Sight>,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      checkLists: null == checkLists
          ? _value.checkLists
          : checkLists // ignore: cast_nullable_to_non_nullable
              as List<CheckList>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryPlanDataImplCopyWith<$Res>
    implements $ItineraryPlanDataCopyWith<$Res> {
  factory _$$ItineraryPlanDataImplCopyWith(_$ItineraryPlanDataImpl value,
          $Res Function(_$ItineraryPlanDataImpl) then) =
      __$$ItineraryPlanDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      DateTime day,
      String? id,
      List<Sight> sights,
      List<String> notes,
      List<CheckList> checkLists});
}

/// @nodoc
class __$$ItineraryPlanDataImplCopyWithImpl<$Res>
    extends _$ItineraryPlanDataCopyWithImpl<$Res, _$ItineraryPlanDataImpl>
    implements _$$ItineraryPlanDataImplCopyWith<$Res> {
  __$$ItineraryPlanDataImplCopyWithImpl(_$ItineraryPlanDataImpl _value,
      $Res Function(_$ItineraryPlanDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItineraryPlanData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? day = null,
    Object? id = freezed,
    Object? sights = null,
    Object? notes = null,
    Object? checkLists = null,
  }) {
    return _then(_$ItineraryPlanDataImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as DateTime,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      sights: null == sights
          ? _value._sights
          : sights // ignore: cast_nullable_to_non_nullable
              as List<Sight>,
      notes: null == notes
          ? _value._notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      checkLists: null == checkLists
          ? _value._checkLists
          : checkLists // ignore: cast_nullable_to_non_nullable
              as List<CheckList>,
    ));
  }
}

/// @nodoc

class _$ItineraryPlanDataImpl extends _ItineraryPlanData {
  const _$ItineraryPlanDataImpl(
      {required this.tripId,
      required this.day,
      this.id,
      final List<Sight> sights = const [],
      final List<String> notes = const [],
      final List<CheckList> checkLists = const []})
      : _sights = sights,
        _notes = notes,
        _checkLists = checkLists,
        super._();

  @override
  final String tripId;
  @override
  final DateTime day;
  @override
  final String? id;
  final List<Sight> _sights;
  @override
  @JsonKey()
  List<Sight> get sights {
    if (_sights is EqualUnmodifiableListView) return _sights;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sights);
  }

  final List<String> _notes;
  @override
  @JsonKey()
  List<String> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  final List<CheckList> _checkLists;
  @override
  @JsonKey()
  List<CheckList> get checkLists {
    if (_checkLists is EqualUnmodifiableListView) return _checkLists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checkLists);
  }

  @override
  String toString() {
    return 'ItineraryPlanData(tripId: $tripId, day: $day, id: $id, sights: $sights, notes: $notes, checkLists: $checkLists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryPlanDataImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._sights, _sights) &&
            const DeepCollectionEquality().equals(other._notes, _notes) &&
            const DeepCollectionEquality()
                .equals(other._checkLists, _checkLists));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      tripId,
      day,
      id,
      const DeepCollectionEquality().hash(_sights),
      const DeepCollectionEquality().hash(_notes),
      const DeepCollectionEquality().hash(_checkLists));

  /// Create a copy of ItineraryPlanData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryPlanDataImplCopyWith<_$ItineraryPlanDataImpl> get copyWith =>
      __$$ItineraryPlanDataImplCopyWithImpl<_$ItineraryPlanDataImpl>(
          this, _$identity);
}

abstract class _ItineraryPlanData extends ItineraryPlanData {
  const factory _ItineraryPlanData(
      {required final String tripId,
      required final DateTime day,
      final String? id,
      final List<Sight> sights,
      final List<String> notes,
      final List<CheckList> checkLists}) = _$ItineraryPlanDataImpl;
  const _ItineraryPlanData._() : super._();

  @override
  String get tripId;
  @override
  DateTime get day;
  @override
  String? get id;
  @override
  List<Sight> get sights;
  @override
  List<String> get notes;
  @override
  List<CheckList> get checkLists;

  /// Create a copy of ItineraryPlanData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryPlanDataImplCopyWith<_$ItineraryPlanDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
