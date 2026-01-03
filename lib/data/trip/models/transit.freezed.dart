// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Transit {
  String get tripId => throw _privateConstructorUsedError;
  TransitOption get transitOption => throw _privateConstructorUsedError;
  Expense get expense => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  Location? get departureLocation => throw _privateConstructorUsedError;
  DateTime? get departureDateTime => throw _privateConstructorUsedError;
  Location? get arrivalLocation => throw _privateConstructorUsedError;
  DateTime? get arrivalDateTime => throw _privateConstructorUsedError;
  String? get operator => throw _privateConstructorUsedError;
  String? get confirmationId => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)
        draft,
    required TResult Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)?
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)?
        draft,
    TResult Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)?
        strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransitDraft value) draft,
    required TResult Function(TransitStrict value) strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransitDraft value)? draft,
    TResult? Function(TransitStrict value)? strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransitDraft value)? draft,
    TResult Function(TransitStrict value)? strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransitCopyWith<Transit> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransitCopyWith<$Res> {
  factory $TransitCopyWith(Transit value, $Res Function(Transit) then) =
      _$TransitCopyWithImpl<$Res, Transit>;
  @useResult
  $Res call(
      {String tripId,
      TransitOption transitOption,
      Expense expense,
      String id,
      Location departureLocation,
      DateTime departureDateTime,
      Location arrivalLocation,
      DateTime arrivalDateTime,
      String? operator,
      String? confirmationId,
      String notes});

  $ExpenseCopyWith<$Res> get expense;
  $LocationCopyWith<$Res>? get departureLocation;
  $LocationCopyWith<$Res>? get arrivalLocation;
}

/// @nodoc
class _$TransitCopyWithImpl<$Res, $Val extends Transit>
    implements $TransitCopyWith<$Res> {
  _$TransitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? transitOption = null,
    Object? expense = null,
    Object? id = null,
    Object? departureLocation = null,
    Object? departureDateTime = null,
    Object? arrivalLocation = null,
    Object? arrivalDateTime = null,
    Object? operator = freezed,
    Object? confirmationId = freezed,
    Object? notes = null,
  }) {
    return _then(_value.copyWith(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      transitOption: null == transitOption
          ? _value.transitOption
          : transitOption // ignore: cast_nullable_to_non_nullable
              as TransitOption,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      id: null == id
          ? _value.id!
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      departureLocation: null == departureLocation
          ? _value.departureLocation!
          : departureLocation // ignore: cast_nullable_to_non_nullable
              as Location,
      departureDateTime: null == departureDateTime
          ? _value.departureDateTime!
          : departureDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      arrivalLocation: null == arrivalLocation
          ? _value.arrivalLocation!
          : arrivalLocation // ignore: cast_nullable_to_non_nullable
              as Location,
      arrivalDateTime: null == arrivalDateTime
          ? _value.arrivalDateTime!
          : arrivalDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      operator: freezed == operator
          ? _value.operator
          : operator // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmationId: freezed == confirmationId
          ? _value.confirmationId
          : confirmationId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExpenseCopyWith<$Res> get expense {
    return $ExpenseCopyWith<$Res>(_value.expense, (value) {
      return _then(_value.copyWith(expense: value) as $Val);
    });
  }

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res>? get departureLocation {
    if (_value.departureLocation == null) {
      return null;
    }

    return $LocationCopyWith<$Res>(_value.departureLocation!, (value) {
      return _then(_value.copyWith(departureLocation: value) as $Val);
    });
  }

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res>? get arrivalLocation {
    if (_value.arrivalLocation == null) {
      return null;
    }

    return $LocationCopyWith<$Res>(_value.arrivalLocation!, (value) {
      return _then(_value.copyWith(arrivalLocation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TransitDraftImplCopyWith<$Res>
    implements $TransitCopyWith<$Res> {
  factory _$$TransitDraftImplCopyWith(
          _$TransitDraftImpl value, $Res Function(_$TransitDraftImpl) then) =
      __$$TransitDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      TransitOption transitOption,
      Expense expense,
      String? id,
      Location? departureLocation,
      DateTime? departureDateTime,
      Location? arrivalLocation,
      DateTime? arrivalDateTime,
      String? operator,
      String? confirmationId,
      String notes});

  @override
  $ExpenseCopyWith<$Res> get expense;
  @override
  $LocationCopyWith<$Res>? get departureLocation;
  @override
  $LocationCopyWith<$Res>? get arrivalLocation;
}

/// @nodoc
class __$$TransitDraftImplCopyWithImpl<$Res>
    extends _$TransitCopyWithImpl<$Res, _$TransitDraftImpl>
    implements _$$TransitDraftImplCopyWith<$Res> {
  __$$TransitDraftImplCopyWithImpl(
      _$TransitDraftImpl _value, $Res Function(_$TransitDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? transitOption = null,
    Object? expense = null,
    Object? id = freezed,
    Object? departureLocation = freezed,
    Object? departureDateTime = freezed,
    Object? arrivalLocation = freezed,
    Object? arrivalDateTime = freezed,
    Object? operator = freezed,
    Object? confirmationId = freezed,
    Object? notes = null,
  }) {
    return _then(_$TransitDraftImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      transitOption: null == transitOption
          ? _value.transitOption
          : transitOption // ignore: cast_nullable_to_non_nullable
              as TransitOption,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      departureLocation: freezed == departureLocation
          ? _value.departureLocation
          : departureLocation // ignore: cast_nullable_to_non_nullable
              as Location?,
      departureDateTime: freezed == departureDateTime
          ? _value.departureDateTime
          : departureDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      arrivalLocation: freezed == arrivalLocation
          ? _value.arrivalLocation
          : arrivalLocation // ignore: cast_nullable_to_non_nullable
              as Location?,
      arrivalDateTime: freezed == arrivalDateTime
          ? _value.arrivalDateTime
          : arrivalDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      operator: freezed == operator
          ? _value.operator
          : operator // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmationId: freezed == confirmationId
          ? _value.confirmationId
          : confirmationId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TransitDraftImpl extends TransitDraft {
  const _$TransitDraftImpl(
      {required this.tripId,
      required this.transitOption,
      required this.expense,
      this.id,
      this.departureLocation,
      this.departureDateTime,
      this.arrivalLocation,
      this.arrivalDateTime,
      this.operator,
      this.confirmationId,
      this.notes = ''})
      : super._();

  @override
  final String tripId;
  @override
  final TransitOption transitOption;
  @override
  final Expense expense;
  @override
  final String? id;
  @override
  final Location? departureLocation;
  @override
  final DateTime? departureDateTime;
  @override
  final Location? arrivalLocation;
  @override
  final DateTime? arrivalDateTime;
  @override
  final String? operator;
  @override
  final String? confirmationId;
  @override
  @JsonKey()
  final String notes;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransitDraftImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.transitOption, transitOption) ||
                other.transitOption == transitOption) &&
            (identical(other.expense, expense) || other.expense == expense) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.departureLocation, departureLocation) ||
                other.departureLocation == departureLocation) &&
            (identical(other.departureDateTime, departureDateTime) ||
                other.departureDateTime == departureDateTime) &&
            (identical(other.arrivalLocation, arrivalLocation) ||
                other.arrivalLocation == arrivalLocation) &&
            (identical(other.arrivalDateTime, arrivalDateTime) ||
                other.arrivalDateTime == arrivalDateTime) &&
            (identical(other.operator, operator) ||
                other.operator == operator) &&
            (identical(other.confirmationId, confirmationId) ||
                other.confirmationId == confirmationId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      tripId,
      transitOption,
      expense,
      id,
      departureLocation,
      departureDateTime,
      arrivalLocation,
      arrivalDateTime,
      operator,
      confirmationId,
      notes);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransitDraftImplCopyWith<_$TransitDraftImpl> get copyWith =>
      __$$TransitDraftImplCopyWithImpl<_$TransitDraftImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)
        draft,
    required TResult Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)
        strict,
  }) {
    return draft(
        tripId,
        transitOption,
        expense,
        id,
        departureLocation,
        departureDateTime,
        arrivalLocation,
        arrivalDateTime,
        operator,
        confirmationId,
        notes);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)?
        strict,
  }) {
    return draft?.call(
        tripId,
        transitOption,
        expense,
        id,
        departureLocation,
        departureDateTime,
        arrivalLocation,
        arrivalDateTime,
        operator,
        confirmationId,
        notes);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)?
        draft,
    TResult Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)?
        strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(
          tripId,
          transitOption,
          expense,
          id,
          departureLocation,
          departureDateTime,
          arrivalLocation,
          arrivalDateTime,
          operator,
          confirmationId,
          notes);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransitDraft value) draft,
    required TResult Function(TransitStrict value) strict,
  }) {
    return draft(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransitDraft value)? draft,
    TResult? Function(TransitStrict value)? strict,
  }) {
    return draft?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransitDraft value)? draft,
    TResult Function(TransitStrict value)? strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(this);
    }
    return orElse();
  }
}

abstract class TransitDraft extends Transit {
  const factory TransitDraft(
      {required final String tripId,
      required final TransitOption transitOption,
      required final Expense expense,
      final String? id,
      final Location? departureLocation,
      final DateTime? departureDateTime,
      final Location? arrivalLocation,
      final DateTime? arrivalDateTime,
      final String? operator,
      final String? confirmationId,
      final String notes}) = _$TransitDraftImpl;
  const TransitDraft._() : super._();

  @override
  String get tripId;
  @override
  TransitOption get transitOption;
  @override
  Expense get expense;
  @override
  String? get id;
  @override
  Location? get departureLocation;
  @override
  DateTime? get departureDateTime;
  @override
  Location? get arrivalLocation;
  @override
  DateTime? get arrivalDateTime;
  @override
  String? get operator;
  @override
  String? get confirmationId;
  @override
  String get notes;

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransitDraftImplCopyWith<_$TransitDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TransitStrictImplCopyWith<$Res>
    implements $TransitCopyWith<$Res> {
  factory _$$TransitStrictImplCopyWith(
          _$TransitStrictImpl value, $Res Function(_$TransitStrictImpl) then) =
      __$$TransitStrictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      String id,
      TransitOption transitOption,
      Location departureLocation,
      DateTime departureDateTime,
      Location arrivalLocation,
      DateTime arrivalDateTime,
      Expense expense,
      String? operator,
      String? confirmationId,
      String notes});

  @override
  $LocationCopyWith<$Res> get departureLocation;
  @override
  $LocationCopyWith<$Res> get arrivalLocation;
  @override
  $ExpenseCopyWith<$Res> get expense;
}

/// @nodoc
class __$$TransitStrictImplCopyWithImpl<$Res>
    extends _$TransitCopyWithImpl<$Res, _$TransitStrictImpl>
    implements _$$TransitStrictImplCopyWith<$Res> {
  __$$TransitStrictImplCopyWithImpl(
      _$TransitStrictImpl _value, $Res Function(_$TransitStrictImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? id = null,
    Object? transitOption = null,
    Object? departureLocation = null,
    Object? departureDateTime = null,
    Object? arrivalLocation = null,
    Object? arrivalDateTime = null,
    Object? expense = null,
    Object? operator = freezed,
    Object? confirmationId = freezed,
    Object? notes = null,
  }) {
    return _then(_$TransitStrictImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      transitOption: null == transitOption
          ? _value.transitOption
          : transitOption // ignore: cast_nullable_to_non_nullable
              as TransitOption,
      departureLocation: null == departureLocation
          ? _value.departureLocation
          : departureLocation // ignore: cast_nullable_to_non_nullable
              as Location,
      departureDateTime: null == departureDateTime
          ? _value.departureDateTime
          : departureDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      arrivalLocation: null == arrivalLocation
          ? _value.arrivalLocation
          : arrivalLocation // ignore: cast_nullable_to_non_nullable
              as Location,
      arrivalDateTime: null == arrivalDateTime
          ? _value.arrivalDateTime
          : arrivalDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      operator: freezed == operator
          ? _value.operator
          : operator // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmationId: freezed == confirmationId
          ? _value.confirmationId
          : confirmationId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res> get departureLocation {
    return $LocationCopyWith<$Res>(_value.departureLocation, (value) {
      return _then(_value.copyWith(departureLocation: value));
    });
  }

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res> get arrivalLocation {
    return $LocationCopyWith<$Res>(_value.arrivalLocation, (value) {
      return _then(_value.copyWith(arrivalLocation: value));
    });
  }
}

/// @nodoc

class _$TransitStrictImpl extends TransitStrict {
  const _$TransitStrictImpl(
      {required this.tripId,
      required this.id,
      required this.transitOption,
      required this.departureLocation,
      required this.departureDateTime,
      required this.arrivalLocation,
      required this.arrivalDateTime,
      required this.expense,
      this.operator,
      this.confirmationId,
      this.notes = ''})
      : super._();

  @override
  final String tripId;
  @override
  final String id;
  @override
  final TransitOption transitOption;
  @override
  final Location departureLocation;
  @override
  final DateTime departureDateTime;
  @override
  final Location arrivalLocation;
  @override
  final DateTime arrivalDateTime;
  @override
  final Expense expense;
  @override
  final String? operator;
  @override
  final String? confirmationId;
  @override
  @JsonKey()
  final String notes;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransitStrictImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.transitOption, transitOption) ||
                other.transitOption == transitOption) &&
            (identical(other.departureLocation, departureLocation) ||
                other.departureLocation == departureLocation) &&
            (identical(other.departureDateTime, departureDateTime) ||
                other.departureDateTime == departureDateTime) &&
            (identical(other.arrivalLocation, arrivalLocation) ||
                other.arrivalLocation == arrivalLocation) &&
            (identical(other.arrivalDateTime, arrivalDateTime) ||
                other.arrivalDateTime == arrivalDateTime) &&
            (identical(other.expense, expense) || other.expense == expense) &&
            (identical(other.operator, operator) ||
                other.operator == operator) &&
            (identical(other.confirmationId, confirmationId) ||
                other.confirmationId == confirmationId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      tripId,
      id,
      transitOption,
      departureLocation,
      departureDateTime,
      arrivalLocation,
      arrivalDateTime,
      expense,
      operator,
      confirmationId,
      notes);

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransitStrictImplCopyWith<_$TransitStrictImpl> get copyWith =>
      __$$TransitStrictImplCopyWithImpl<_$TransitStrictImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)
        draft,
    required TResult Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)
        strict,
  }) {
    return strict(
        tripId,
        id,
        transitOption,
        departureLocation,
        departureDateTime,
        arrivalLocation,
        arrivalDateTime,
        expense,
        operator,
        confirmationId,
        notes);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)?
        strict,
  }) {
    return strict?.call(
        tripId,
        id,
        transitOption,
        departureLocation,
        departureDateTime,
        arrivalLocation,
        arrivalDateTime,
        expense,
        operator,
        confirmationId,
        notes);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            TransitOption transitOption,
            Expense expense,
            String? id,
            Location? departureLocation,
            DateTime? departureDateTime,
            Location? arrivalLocation,
            DateTime? arrivalDateTime,
            String? operator,
            String? confirmationId,
            String notes)?
        draft,
    TResult Function(
            String tripId,
            String id,
            TransitOption transitOption,
            Location departureLocation,
            DateTime departureDateTime,
            Location arrivalLocation,
            DateTime arrivalDateTime,
            Expense expense,
            String? operator,
            String? confirmationId,
            String notes)?
        strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(
          tripId,
          id,
          transitOption,
          departureLocation,
          departureDateTime,
          arrivalLocation,
          arrivalDateTime,
          expense,
          operator,
          confirmationId,
          notes);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransitDraft value) draft,
    required TResult Function(TransitStrict value) strict,
  }) {
    return strict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransitDraft value)? draft,
    TResult? Function(TransitStrict value)? strict,
  }) {
    return strict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransitDraft value)? draft,
    TResult Function(TransitStrict value)? strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(this);
    }
    return orElse();
  }
}

abstract class TransitStrict extends Transit {
  const factory TransitStrict(
      {required final String tripId,
      required final String id,
      required final TransitOption transitOption,
      required final Location departureLocation,
      required final DateTime departureDateTime,
      required final Location arrivalLocation,
      required final DateTime arrivalDateTime,
      required final Expense expense,
      final String? operator,
      final String? confirmationId,
      final String notes}) = _$TransitStrictImpl;
  const TransitStrict._() : super._();

  @override
  String get tripId;
  @override
  String get id;
  @override
  TransitOption get transitOption;
  @override
  Location get departureLocation;
  @override
  DateTime get departureDateTime;
  @override
  Location get arrivalLocation;
  @override
  DateTime get arrivalDateTime;
  @override
  Expense get expense;
  @override
  String? get operator;
  @override
  String? get confirmationId;
  @override
  String get notes;

  /// Create a copy of Transit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransitStrictImplCopyWith<_$TransitStrictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
