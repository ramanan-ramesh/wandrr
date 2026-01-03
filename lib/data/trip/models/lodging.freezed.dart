// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lodging.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Lodging {
  String get tripId => throw _privateConstructorUsedError;
  Expense get expense => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  Location? get location => throw _privateConstructorUsedError;
  DateTime? get checkinDateTime => throw _privateConstructorUsedError;
  DateTime? get checkoutDateTime => throw _privateConstructorUsedError;
  String? get confirmationId => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)
        draft,
    required TResult Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)?
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)?
        draft,
    TResult Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)?
        strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LodgingDraft value) draft,
    required TResult Function(LodgingStrict value) strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LodgingDraft value)? draft,
    TResult? Function(LodgingStrict value)? strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LodgingDraft value)? draft,
    TResult Function(LodgingStrict value)? strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LodgingCopyWith<Lodging> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LodgingCopyWith<$Res> {
  factory $LodgingCopyWith(Lodging value, $Res Function(Lodging) then) =
      _$LodgingCopyWithImpl<$Res, Lodging>;
  @useResult
  $Res call(
      {String tripId,
      Expense expense,
      String id,
      Location location,
      DateTime checkinDateTime,
      DateTime checkoutDateTime,
      String? confirmationId,
      String? notes});

  $ExpenseCopyWith<$Res> get expense;
  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class _$LodgingCopyWithImpl<$Res, $Val extends Lodging>
    implements $LodgingCopyWith<$Res> {
  _$LodgingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? expense = null,
    Object? id = null,
    Object? location = null,
    Object? checkinDateTime = null,
    Object? checkoutDateTime = null,
    Object? confirmationId = freezed,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      id: null == id
          ? _value.id!
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location!
          : location // ignore: cast_nullable_to_non_nullable
              as Location,
      checkinDateTime: null == checkinDateTime
          ? _value.checkinDateTime!
          : checkinDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkoutDateTime: null == checkoutDateTime
          ? _value.checkoutDateTime!
          : checkoutDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      confirmationId: freezed == confirmationId
          ? _value.confirmationId
          : confirmationId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExpenseCopyWith<$Res> get expense {
    return $ExpenseCopyWith<$Res>(_value.expense, (value) {
      return _then(_value.copyWith(expense: value) as $Val);
    });
  }

  /// Create a copy of Lodging
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
abstract class _$$LodgingDraftImplCopyWith<$Res>
    implements $LodgingCopyWith<$Res> {
  factory _$$LodgingDraftImplCopyWith(
          _$LodgingDraftImpl value, $Res Function(_$LodgingDraftImpl) then) =
      __$$LodgingDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      Expense expense,
      String? id,
      Location? location,
      DateTime? checkinDateTime,
      DateTime? checkoutDateTime,
      String? confirmationId,
      String? notes});

  @override
  $ExpenseCopyWith<$Res> get expense;
  @override
  $LocationCopyWith<$Res>? get location;
}

/// @nodoc
class __$$LodgingDraftImplCopyWithImpl<$Res>
    extends _$LodgingCopyWithImpl<$Res, _$LodgingDraftImpl>
    implements _$$LodgingDraftImplCopyWith<$Res> {
  __$$LodgingDraftImplCopyWithImpl(
      _$LodgingDraftImpl _value, $Res Function(_$LodgingDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? expense = null,
    Object? id = freezed,
    Object? location = freezed,
    Object? checkinDateTime = freezed,
    Object? checkoutDateTime = freezed,
    Object? confirmationId = freezed,
    Object? notes = freezed,
  }) {
    return _then(_$LodgingDraftImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location?,
      checkinDateTime: freezed == checkinDateTime
          ? _value.checkinDateTime
          : checkinDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      checkoutDateTime: freezed == checkoutDateTime
          ? _value.checkoutDateTime
          : checkoutDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      confirmationId: freezed == confirmationId
          ? _value.confirmationId
          : confirmationId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$LodgingDraftImpl extends LodgingDraft {
  const _$LodgingDraftImpl(
      {required this.tripId,
      required this.expense,
      this.id,
      this.location,
      this.checkinDateTime,
      this.checkoutDateTime,
      this.confirmationId,
      this.notes})
      : super._();

  @override
  final String tripId;
  @override
  final Expense expense;
  @override
  final String? id;
  @override
  final Location? location;
  @override
  final DateTime? checkinDateTime;
  @override
  final DateTime? checkoutDateTime;
  @override
  final String? confirmationId;
  @override
  final String? notes;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LodgingDraftImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.expense, expense) || other.expense == expense) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.checkinDateTime, checkinDateTime) ||
                other.checkinDateTime == checkinDateTime) &&
            (identical(other.checkoutDateTime, checkoutDateTime) ||
                other.checkoutDateTime == checkoutDateTime) &&
            (identical(other.confirmationId, confirmationId) ||
                other.confirmationId == confirmationId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tripId, expense, id, location,
      checkinDateTime, checkoutDateTime, confirmationId, notes);

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LodgingDraftImplCopyWith<_$LodgingDraftImpl> get copyWith =>
      __$$LodgingDraftImplCopyWithImpl<_$LodgingDraftImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)
        draft,
    required TResult Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)
        strict,
  }) {
    return draft(tripId, expense, id, location, checkinDateTime,
        checkoutDateTime, confirmationId, notes);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)?
        strict,
  }) {
    return draft?.call(tripId, expense, id, location, checkinDateTime,
        checkoutDateTime, confirmationId, notes);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)?
        draft,
    TResult Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)?
        strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(tripId, expense, id, location, checkinDateTime,
          checkoutDateTime, confirmationId, notes);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LodgingDraft value) draft,
    required TResult Function(LodgingStrict value) strict,
  }) {
    return draft(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LodgingDraft value)? draft,
    TResult? Function(LodgingStrict value)? strict,
  }) {
    return draft?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LodgingDraft value)? draft,
    TResult Function(LodgingStrict value)? strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(this);
    }
    return orElse();
  }
}

abstract class LodgingDraft extends Lodging {
  const factory LodgingDraft(
      {required final String tripId,
      required final Expense expense,
      final String? id,
      final Location? location,
      final DateTime? checkinDateTime,
      final DateTime? checkoutDateTime,
      final String? confirmationId,
      final String? notes}) = _$LodgingDraftImpl;
  const LodgingDraft._() : super._();

  @override
  String get tripId;
  @override
  Expense get expense;
  @override
  String? get id;
  @override
  Location? get location;
  @override
  DateTime? get checkinDateTime;
  @override
  DateTime? get checkoutDateTime;
  @override
  String? get confirmationId;
  @override
  String? get notes;

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LodgingDraftImplCopyWith<_$LodgingDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LodgingStrictImplCopyWith<$Res>
    implements $LodgingCopyWith<$Res> {
  factory _$$LodgingStrictImplCopyWith(
          _$LodgingStrictImpl value, $Res Function(_$LodgingStrictImpl) then) =
      __$$LodgingStrictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      String id,
      Location location,
      DateTime checkinDateTime,
      DateTime checkoutDateTime,
      Expense expense,
      String? confirmationId,
      String? notes});

  @override
  $LocationCopyWith<$Res> get location;
  @override
  $ExpenseCopyWith<$Res> get expense;
}

/// @nodoc
class __$$LodgingStrictImplCopyWithImpl<$Res>
    extends _$LodgingCopyWithImpl<$Res, _$LodgingStrictImpl>
    implements _$$LodgingStrictImplCopyWith<$Res> {
  __$$LodgingStrictImplCopyWithImpl(
      _$LodgingStrictImpl _value, $Res Function(_$LodgingStrictImpl) _then)
      : super(_value, _then);

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? id = null,
    Object? location = null,
    Object? checkinDateTime = null,
    Object? checkoutDateTime = null,
    Object? expense = null,
    Object? confirmationId = freezed,
    Object? notes = freezed,
  }) {
    return _then(_$LodgingStrictImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Location,
      checkinDateTime: null == checkinDateTime
          ? _value.checkinDateTime
          : checkinDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkoutDateTime: null == checkoutDateTime
          ? _value.checkoutDateTime
          : checkoutDateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expense: null == expense
          ? _value.expense
          : expense // ignore: cast_nullable_to_non_nullable
              as Expense,
      confirmationId: freezed == confirmationId
          ? _value.confirmationId
          : confirmationId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res> get location {
    return $LocationCopyWith<$Res>(_value.location, (value) {
      return _then(_value.copyWith(location: value));
    });
  }
}

/// @nodoc

class _$LodgingStrictImpl extends LodgingStrict {
  const _$LodgingStrictImpl(
      {required this.tripId,
      required this.id,
      required this.location,
      required this.checkinDateTime,
      required this.checkoutDateTime,
      required this.expense,
      this.confirmationId,
      this.notes})
      : super._();

  @override
  final String tripId;
  @override
  final String id;
  @override
  final Location location;
  @override
  final DateTime checkinDateTime;
  @override
  final DateTime checkoutDateTime;
  @override
  final Expense expense;
  @override
  final String? confirmationId;
  @override
  final String? notes;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LodgingStrictImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.checkinDateTime, checkinDateTime) ||
                other.checkinDateTime == checkinDateTime) &&
            (identical(other.checkoutDateTime, checkoutDateTime) ||
                other.checkoutDateTime == checkoutDateTime) &&
            (identical(other.expense, expense) || other.expense == expense) &&
            (identical(other.confirmationId, confirmationId) ||
                other.confirmationId == confirmationId) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tripId, id, location,
      checkinDateTime, checkoutDateTime, expense, confirmationId, notes);

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LodgingStrictImplCopyWith<_$LodgingStrictImpl> get copyWith =>
      __$$LodgingStrictImplCopyWithImpl<_$LodgingStrictImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)
        draft,
    required TResult Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)
        strict,
  }) {
    return strict(tripId, id, location, checkinDateTime, checkoutDateTime,
        expense, confirmationId, notes);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)?
        strict,
  }) {
    return strict?.call(tripId, id, location, checkinDateTime, checkoutDateTime,
        expense, confirmationId, notes);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            Expense expense,
            String? id,
            Location? location,
            DateTime? checkinDateTime,
            DateTime? checkoutDateTime,
            String? confirmationId,
            String? notes)?
        draft,
    TResult Function(
            String tripId,
            String id,
            Location location,
            DateTime checkinDateTime,
            DateTime checkoutDateTime,
            Expense expense,
            String? confirmationId,
            String? notes)?
        strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(tripId, id, location, checkinDateTime, checkoutDateTime,
          expense, confirmationId, notes);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LodgingDraft value) draft,
    required TResult Function(LodgingStrict value) strict,
  }) {
    return strict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LodgingDraft value)? draft,
    TResult? Function(LodgingStrict value)? strict,
  }) {
    return strict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LodgingDraft value)? draft,
    TResult Function(LodgingStrict value)? strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(this);
    }
    return orElse();
  }
}

abstract class LodgingStrict extends Lodging {
  const factory LodgingStrict(
      {required final String tripId,
      required final String id,
      required final Location location,
      required final DateTime checkinDateTime,
      required final DateTime checkoutDateTime,
      required final Expense expense,
      final String? confirmationId,
      final String? notes}) = _$LodgingStrictImpl;
  const LodgingStrict._() : super._();

  @override
  String get tripId;
  @override
  String get id;
  @override
  Location get location;
  @override
  DateTime get checkinDateTime;
  @override
  DateTime get checkoutDateTime;
  @override
  Expense get expense;
  @override
  String? get confirmationId;
  @override
  String? get notes;

  /// Create a copy of Lodging
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LodgingStrictImplCopyWith<_$LodgingStrictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
