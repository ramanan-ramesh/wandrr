// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Expense {
  String get tripId => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  ExpenseCategory get category => throw _privateConstructorUsedError;
  Map<String, double> get paidBy => throw _privateConstructorUsedError;
  List<String> get splitBy => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  DateTime? get dateTime => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)
        draft,
    required TResult Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)?
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)?
        draft,
    TResult Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)?
        strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ExpenseDraft value) draft,
    required TResult Function(ExpenseStrict value) strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ExpenseDraft value)? draft,
    TResult? Function(ExpenseStrict value)? strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ExpenseDraft value)? draft,
    TResult Function(ExpenseStrict value)? strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpenseCopyWith<Expense> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseCopyWith<$Res> {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) then) =
      _$ExpenseCopyWithImpl<$Res, Expense>;
  @useResult
  $Res call(
      {String tripId,
      String currency,
      ExpenseCategory category,
      Map<String, double> paidBy,
      List<String> splitBy,
      String id,
      String title,
      String? description,
      DateTime? dateTime});
}

/// @nodoc
class _$ExpenseCopyWithImpl<$Res, $Val extends Expense>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? currency = null,
    Object? category = null,
    Object? paidBy = null,
    Object? splitBy = null,
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? dateTime = freezed,
  }) {
    return _then(_value.copyWith(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ExpenseCategory,
      paidBy: null == paidBy
          ? _value.paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      splitBy: null == splitBy
          ? _value.splitBy
          : splitBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      id: null == id
          ? _value.id!
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      dateTime: freezed == dateTime
          ? _value.dateTime
          : dateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExpenseDraftImplCopyWith<$Res>
    implements $ExpenseCopyWith<$Res> {
  factory _$$ExpenseDraftImplCopyWith(
          _$ExpenseDraftImpl value, $Res Function(_$ExpenseDraftImpl) then) =
      __$$ExpenseDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      String currency,
      ExpenseCategory category,
      Map<String, double> paidBy,
      List<String> splitBy,
      String? id,
      String title,
      String? description,
      DateTime? dateTime});
}

/// @nodoc
class __$$ExpenseDraftImplCopyWithImpl<$Res>
    extends _$ExpenseCopyWithImpl<$Res, _$ExpenseDraftImpl>
    implements _$$ExpenseDraftImplCopyWith<$Res> {
  __$$ExpenseDraftImplCopyWithImpl(
      _$ExpenseDraftImpl _value, $Res Function(_$ExpenseDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? currency = null,
    Object? category = null,
    Object? paidBy = null,
    Object? splitBy = null,
    Object? id = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? dateTime = freezed,
  }) {
    return _then(_$ExpenseDraftImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ExpenseCategory,
      paidBy: null == paidBy
          ? _value._paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      splitBy: null == splitBy
          ? _value._splitBy
          : splitBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      dateTime: freezed == dateTime
          ? _value.dateTime
          : dateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ExpenseDraftImpl extends ExpenseDraft {
  const _$ExpenseDraftImpl(
      {required this.tripId,
      required this.currency,
      required this.category,
      required final Map<String, double> paidBy,
      required final List<String> splitBy,
      this.id,
      this.title = '',
      this.description,
      this.dateTime})
      : _paidBy = paidBy,
        _splitBy = splitBy,
        super._();

  @override
  final String tripId;
  @override
  final String currency;
  @override
  final ExpenseCategory category;
  final Map<String, double> _paidBy;
  @override
  Map<String, double> get paidBy {
    if (_paidBy is EqualUnmodifiableMapView) return _paidBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_paidBy);
  }

  final List<String> _splitBy;
  @override
  List<String> get splitBy {
    if (_splitBy is EqualUnmodifiableListView) return _splitBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_splitBy);
  }

  @override
  final String? id;
  @override
  @JsonKey()
  final String title;
  @override
  final String? description;
  @override
  final DateTime? dateTime;

  @override
  String toString() {
    return 'Expense.draft(tripId: $tripId, currency: $currency, category: $category, paidBy: $paidBy, splitBy: $splitBy, id: $id, title: $title, description: $description, dateTime: $dateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseDraftImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._paidBy, _paidBy) &&
            const DeepCollectionEquality().equals(other._splitBy, _splitBy) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.dateTime, dateTime) ||
                other.dateTime == dateTime));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      tripId,
      currency,
      category,
      const DeepCollectionEquality().hash(_paidBy),
      const DeepCollectionEquality().hash(_splitBy),
      id,
      title,
      description,
      dateTime);

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseDraftImplCopyWith<_$ExpenseDraftImpl> get copyWith =>
      __$$ExpenseDraftImplCopyWithImpl<_$ExpenseDraftImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)
        draft,
    required TResult Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)
        strict,
  }) {
    return draft(tripId, currency, category, paidBy, splitBy, id, title,
        description, dateTime);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)?
        strict,
  }) {
    return draft?.call(tripId, currency, category, paidBy, splitBy, id, title,
        description, dateTime);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)?
        draft,
    TResult Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)?
        strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(tripId, currency, category, paidBy, splitBy, id, title,
          description, dateTime);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ExpenseDraft value) draft,
    required TResult Function(ExpenseStrict value) strict,
  }) {
    return draft(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ExpenseDraft value)? draft,
    TResult? Function(ExpenseStrict value)? strict,
  }) {
    return draft?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ExpenseDraft value)? draft,
    TResult Function(ExpenseStrict value)? strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(this);
    }
    return orElse();
  }
}

abstract class ExpenseDraft extends Expense {
  const factory ExpenseDraft(
      {required final String tripId,
      required final String currency,
      required final ExpenseCategory category,
      required final Map<String, double> paidBy,
      required final List<String> splitBy,
      final String? id,
      final String title,
      final String? description,
      final DateTime? dateTime}) = _$ExpenseDraftImpl;
  const ExpenseDraft._() : super._();

  @override
  String get tripId;
  @override
  String get currency;
  @override
  ExpenseCategory get category;
  @override
  Map<String, double> get paidBy;
  @override
  List<String> get splitBy;
  @override
  String? get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  DateTime? get dateTime;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseDraftImplCopyWith<_$ExpenseDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ExpenseStrictImplCopyWith<$Res>
    implements $ExpenseCopyWith<$Res> {
  factory _$$ExpenseStrictImplCopyWith(
          _$ExpenseStrictImpl value, $Res Function(_$ExpenseStrictImpl) then) =
      __$$ExpenseStrictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId,
      String id,
      String currency,
      ExpenseCategory category,
      Map<String, double> paidBy,
      List<String> splitBy,
      String title,
      String? description,
      DateTime? dateTime});
}

/// @nodoc
class __$$ExpenseStrictImplCopyWithImpl<$Res>
    extends _$ExpenseCopyWithImpl<$Res, _$ExpenseStrictImpl>
    implements _$$ExpenseStrictImplCopyWith<$Res> {
  __$$ExpenseStrictImplCopyWithImpl(
      _$ExpenseStrictImpl _value, $Res Function(_$ExpenseStrictImpl) _then)
      : super(_value, _then);

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? id = null,
    Object? currency = null,
    Object? category = null,
    Object? paidBy = null,
    Object? splitBy = null,
    Object? title = null,
    Object? description = freezed,
    Object? dateTime = freezed,
  }) {
    return _then(_$ExpenseStrictImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as ExpenseCategory,
      paidBy: null == paidBy
          ? _value._paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      splitBy: null == splitBy
          ? _value._splitBy
          : splitBy // ignore: cast_nullable_to_non_nullable
              as List<String>,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      dateTime: freezed == dateTime
          ? _value.dateTime
          : dateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ExpenseStrictImpl extends ExpenseStrict {
  const _$ExpenseStrictImpl(
      {required this.tripId,
      required this.id,
      required this.currency,
      required this.category,
      required final Map<String, double> paidBy,
      required final List<String> splitBy,
      this.title = '',
      this.description,
      this.dateTime})
      : _paidBy = paidBy,
        _splitBy = splitBy,
        super._();

  @override
  final String tripId;
  @override
  final String id;
  @override
  final String currency;
  @override
  final ExpenseCategory category;
  final Map<String, double> _paidBy;
  @override
  Map<String, double> get paidBy {
    if (_paidBy is EqualUnmodifiableMapView) return _paidBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_paidBy);
  }

  final List<String> _splitBy;
  @override
  List<String> get splitBy {
    if (_splitBy is EqualUnmodifiableListView) return _splitBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_splitBy);
  }

  @override
  @JsonKey()
  final String title;
  @override
  final String? description;
  @override
  final DateTime? dateTime;

  @override
  String toString() {
    return 'Expense.strict(tripId: $tripId, id: $id, currency: $currency, category: $category, paidBy: $paidBy, splitBy: $splitBy, title: $title, description: $description, dateTime: $dateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseStrictImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._paidBy, _paidBy) &&
            const DeepCollectionEquality().equals(other._splitBy, _splitBy) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.dateTime, dateTime) ||
                other.dateTime == dateTime));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      tripId,
      id,
      currency,
      category,
      const DeepCollectionEquality().hash(_paidBy),
      const DeepCollectionEquality().hash(_splitBy),
      title,
      description,
      dateTime);

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseStrictImplCopyWith<_$ExpenseStrictImpl> get copyWith =>
      __$$ExpenseStrictImplCopyWithImpl<_$ExpenseStrictImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)
        draft,
    required TResult Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)
        strict,
  }) {
    return strict(tripId, id, currency, category, paidBy, splitBy, title,
        description, dateTime);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)?
        draft,
    TResult? Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)?
        strict,
  }) {
    return strict?.call(tripId, id, currency, category, paidBy, splitBy, title,
        description, dateTime);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String tripId,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String? id,
            String title,
            String? description,
            DateTime? dateTime)?
        draft,
    TResult Function(
            String tripId,
            String id,
            String currency,
            ExpenseCategory category,
            Map<String, double> paidBy,
            List<String> splitBy,
            String title,
            String? description,
            DateTime? dateTime)?
        strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(tripId, id, currency, category, paidBy, splitBy, title,
          description, dateTime);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ExpenseDraft value) draft,
    required TResult Function(ExpenseStrict value) strict,
  }) {
    return strict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ExpenseDraft value)? draft,
    TResult? Function(ExpenseStrict value)? strict,
  }) {
    return strict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ExpenseDraft value)? draft,
    TResult Function(ExpenseStrict value)? strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(this);
    }
    return orElse();
  }
}

abstract class ExpenseStrict extends Expense {
  const factory ExpenseStrict(
      {required final String tripId,
      required final String id,
      required final String currency,
      required final ExpenseCategory category,
      required final Map<String, double> paidBy,
      required final List<String> splitBy,
      final String title,
      final String? description,
      final DateTime? dateTime}) = _$ExpenseStrictImpl;
  const ExpenseStrict._() : super._();

  @override
  String get tripId;
  @override
  String get id;
  @override
  String get currency;
  @override
  ExpenseCategory get category;
  @override
  Map<String, double> get paidBy;
  @override
  List<String> get splitBy;
  @override
  String get title;
  @override
  String? get description;
  @override
  DateTime? get dateTime;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseStrictImplCopyWith<_$ExpenseStrictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
