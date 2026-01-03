// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Sight {
  String get tripId => throw _privateConstructorUsedError;
  DateTime get day => throw _privateConstructorUsedError;
  Expense get expense => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Location? get location => throw _privateConstructorUsedError;
  DateTime? get visitTime => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)
        draft,
    required TResult Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)?
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)?
        draft,
    TResult Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)?
        strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SightDraft value) draft,
    required TResult Function(SightStrict value) strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SightDraft value)? draft,
    TResult? Function(SightStrict value)? strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SightDraft value)? draft,
    TResult Function(SightStrict value)? strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SightCopyWith<Sight> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SightCopyWith<$Res> {
  factory $SightCopyWith(Sight value, $Res Function(Sight) then) =
      _$SightCopyWithImpl<$Res, Sight>;
  @useResult
  $Res call(
      {String tripId,
      DateTime day,
      Expense expense,
      String id,
      String name,
      Location? location,
      DateTime? visitTime,
      String? description});

  $ExpenseCopyWith<$Res> get expense;
  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class _$SightCopyWithImpl<$Res, $Val extends Sight>
    implements $SightCopyWith<$Res> {
  _$SightCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? day = null,
    Object? expense = null,
    Object? id = null,
    Object? name = null,
    Object? location = freezed,
    Object? visitTime = freezed,
    Object? description = freezed,
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
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      id: null == id
          ? _value.id!
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
      visitTime: freezed == visitTime
          ? _value.visitTime
          : visitTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExpenseCopyWith<$Res> get expense {
    return $ExpenseCopyWith<$Res>(_value.expense, (value) {
      return _then(_value.copyWith(expense: value) as $Val);
    });
  }

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res>? get location {
    if (_value.location == null) {
      return null;
    }

    return $LocationCopyWith<$Res>(_value.location!, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SightDraftImplCopyWith<$Res> implements $SightCopyWith<$Res> {
  factory _$$SightDraftImplCopyWith(
          _$SightDraftImpl value, $Res Function(_$SightDraftImpl) then) =
      __$$SightDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      DateTime day,
      Expense expense,
      String? id,
      String name,
      Location? location,
      DateTime? visitTime,
      String? description});

  @override
  $ExpenseCopyWith<$Res> get expense;
  @override
  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class __$$SightDraftImplCopyWithImpl<$Res>
    extends _$SightCopyWithImpl<$Res, _$SightDraftImpl>
    implements _$$SightDraftImplCopyWith<$Res> {
  __$$SightDraftImplCopyWithImpl(
      _$SightDraftImpl _value, $Res Function(_$SightDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? day = null,
    Object? expense = null,
    Object? id = freezed,
    Object? name = null,
    Object? location = freezed,
    Object? visitTime = freezed,
    Object? description = freezed,
  }) {
    return _then(_$SightDraftImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
      visitTime: freezed == visitTime
          ? _value.visitTime
          : visitTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SightDraftImpl extends SightDraft {
  const _$SightDraftImpl(
      {required this.tripId,
      required this.day,
      required this.expense,
      this.id,
      this.name = '',
      this.location,
      this.visitTime,
      this.description})
      : super._();

  @override
  final String tripId;
  @override
  final DateTime day;
  @override
  final Expense expense;
  @override
  final String? id;
  @override
  @JsonKey()
  final String name;
  @override
  final Location? location;
  @override
  final DateTime? visitTime;
  @override
  final String? description;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SightDraftImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.expense, expense) || other.expense == expense) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.visitTime, visitTime) ||
                other.visitTime == visitTime) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tripId, day, expense, id, name,
      location, visitTime, description);

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SightDraftImplCopyWith<_$SightDraftImpl> get copyWith =>
      __$$SightDraftImplCopyWithImpl<_$SightDraftImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)
        draft,
    required TResult Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)
        strict,
  }) {
    return draft(
        tripId, day, expense, id, name, location, visitTime, description);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)?
        strict,
  }) {
    return draft?.call(
        tripId, day, expense, id, name, location, visitTime, description);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)?
        draft,
    TResult Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)?
        strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(
          tripId, day, expense, id, name, location, visitTime, description);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SightDraft value) draft,
    required TResult Function(SightStrict value) strict,
  }) {
    return draft(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SightDraft value)? draft,
    TResult? Function(SightStrict value)? strict,
  }) {
    return draft?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SightDraft value)? draft,
    TResult Function(SightStrict value)? strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(this);
    }
    return orElse();
  }
}

abstract class SightDraft extends Sight {
  const factory SightDraft(
      {required final String tripId,
      required final DateTime day,
      required final Expense expense,
      final String? id,
      final String name,
      final Location? location,
      final DateTime? visitTime,
      final String? description}) = _$SightDraftImpl;
  const SightDraft._() : super._();

  @override
  String get tripId;
  @override
  DateTime get day;
  @override
  Expense get expense;
  @override
  String? get id;
  @override
  String get name;
  @override
  Location? get location;
  @override
  DateTime? get visitTime;
  @override
  String? get description;

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SightDraftImplCopyWith<_$SightDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SightStrictImplCopyWith<$Res>
    implements $SightCopyWith<$Res> {
  factory _$$SightStrictImplCopyWith(
          _$SightStrictImpl value, $Res Function(_$SightStrictImpl) then) =
      __$$SightStrictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      String id,
      DateTime day,
      String name,
      Expense expense,
      Location? location,
      DateTime? visitTime,
      String? description});

  @override
  $ExpenseCopyWith<$Res> get expense;
  @override
  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class __$$SightStrictImplCopyWithImpl<$Res>
    extends _$SightCopyWithImpl<$Res, _$SightStrictImpl>
    implements _$$SightStrictImplCopyWith<$Res> {
  __$$SightStrictImplCopyWithImpl(
      _$SightStrictImpl _value, $Res Function(_$SightStrictImpl) _then)
      : super(_value, _then);

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? id = null,
    Object? day = null,
    Object? name = null,
    Object? expense = null,
    Object? location = freezed,
    Object? visitTime = freezed,
    Object? description = freezed,
  }) {
    return _then(_$SightStrictImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      day: null == day
          ? _value.day
          : day // ignore: cast_nullable_to_non_nullable
              as DateTime,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
      visitTime: freezed == visitTime
          ? _value.visitTime
          : visitTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SightStrictImpl extends SightStrict {
  const _$SightStrictImpl(
      {required this.tripId,
      required this.id,
      required this.day,
      required this.name,
      required this.expense,
      this.location,
      this.visitTime,
      this.description})
      : super._();

  @override
  final String tripId;
  @override
  final String id;
  @override
  final DateTime day;
  @override
  final String name;
  @override
  final Expense expense;
  @override
  final Location? location;
  @override
  final DateTime? visitTime;
  @override
  final String? description;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SightStrictImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.expense, expense) || other.expense == expense) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.visitTime, visitTime) ||
                other.visitTime == visitTime) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tripId, id, day, name, expense,
      location, visitTime, description);

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SightStrictImplCopyWith<_$SightStrictImpl> get copyWith =>
      __$$SightStrictImplCopyWithImpl<_$SightStrictImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)
        draft,
    required TResult Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)
        strict,
  }) {
    return strict(
        tripId, id, day, name, expense, location, visitTime, description);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)?
        strict,
  }) {
    return strict?.call(
        tripId, id, day, name, expense, location, visitTime, description);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            DateTime day,
            Expense expense,
            String? id,
            String name,
            Location? location,
            DateTime? visitTime,
            String? description)?
        draft,
    TResult Function(
            String tripId,
            String id,
            DateTime day,
            String name,
            Expense expense,
            Location? location,
            DateTime? visitTime,
            String? description)?
        strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(
          tripId, id, day, name, expense, location, visitTime, description);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SightDraft value) draft,
    required TResult Function(SightStrict value) strict,
  }) {
    return strict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SightDraft value)? draft,
    TResult? Function(SightStrict value)? strict,
  }) {
    return strict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SightDraft value)? draft,
    TResult Function(SightStrict value)? strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(this);
    }
    return orElse();
  }
}

abstract class SightStrict extends Sight {
  const factory SightStrict(
      {required final String tripId,
      required final String id,
      required final DateTime day,
      required final String name,
      required final Expense expense,
      final Location? location,
      final DateTime? visitTime,
      final String? description}) = _$SightStrictImpl;
  const SightStrict._() : super._();

  @override
  String get tripId;
  @override
  String get id;
  @override
  DateTime get day;
  @override
  String get name;
  @override
  Expense get expense;
  @override
  Location? get location;
  @override
  DateTime? get visitTime;
  @override
  String? get description;

  /// Create a copy of Sight
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SightStrictImplCopyWith<_$SightStrictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
