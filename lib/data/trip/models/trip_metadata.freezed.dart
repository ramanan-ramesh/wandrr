// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trip_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TripMetadata {
  String get name => throw _privateConstructorUsedError;
  String get thumbnailTag => throw _privateConstructorUsedError;
  List<String> get contributors => throw _privateConstructorUsedError;
  Money get budget => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)
        draft,
    required TResult Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)?
        draft,
    TResult? Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)?
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)?
        draft,
    TResult Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)?
        strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TripMetadataDraft value) draft,
    required TResult Function(TripMetadataStrict value) strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TripMetadataDraft value)? draft,
    TResult? Function(TripMetadataStrict value)? strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TripMetadataDraft value)? draft,
    TResult Function(TripMetadataStrict value)? strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TripMetadataCopyWith<TripMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripMetadataCopyWith<$Res> {
  factory $TripMetadataCopyWith(
          TripMetadata value, $Res Function(TripMetadata) then) =
      _$TripMetadataCopyWithImpl<$Res, TripMetadata>;
  @useResult
  $Res call(
      {String name,
      String thumbnailTag,
      List<String> contributors,
      Money budget,
      String id,
      DateTime startDate,
      DateTime endDate});

  $MoneyCopyWith<$Res> get budget;
}

/// @nodoc
class _$TripMetadataCopyWithImpl<$Res, $Val extends TripMetadata>
    implements $TripMetadataCopyWith<$Res> {
  _$TripMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? thumbnailTag = null,
    Object? contributors = null,
    Object? budget = null,
    Object? id = null,
    Object? startDate = null,
    Object? endDate = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailTag: null == thumbnailTag
          ? _value.thumbnailTag
          : thumbnailTag // ignore: cast_nullable_to_non_nullable
              as String,
      contributors: null == contributors
          ? _value.contributors
          : contributors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      budget: null == budget
          ? _value.budget
          : budget // ignore: cast_nullable_to_non_nullable
              as Money,
      id: null == id
          ? _value.id!
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate!
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate!
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MoneyCopyWith<$Res> get budget {
    return $MoneyCopyWith<$Res>(_value.budget, (value) {
      return _then(_value.copyWith(budget: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TripMetadataDraftImplCopyWith<$Res>
    implements $TripMetadataCopyWith<$Res> {
  factory _$$TripMetadataDraftImplCopyWith(_$TripMetadataDraftImpl value,
          $Res Function(_$TripMetadataDraftImpl) then) =
      __$$TripMetadataDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String thumbnailTag,
      List<String> contributors,
      Money budget,
      String? id,
      DateTime? startDate,
      DateTime? endDate});

  @override
  $MoneyCopyWith<$Res> get budget;
}

/// @nodoc
class __$$TripMetadataDraftImplCopyWithImpl<$Res>
    extends _$TripMetadataCopyWithImpl<$Res, _$TripMetadataDraftImpl>
    implements _$$TripMetadataDraftImplCopyWith<$Res> {
  __$$TripMetadataDraftImplCopyWithImpl(_$TripMetadataDraftImpl _value,
      $Res Function(_$TripMetadataDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? thumbnailTag = null,
    Object? contributors = null,
    Object? budget = null,
    Object? id = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
  }) {
    return _then(_$TripMetadataDraftImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailTag: null == thumbnailTag
          ? _value.thumbnailTag
          : thumbnailTag // ignore: cast_nullable_to_non_nullable
              as String,
      contributors: null == contributors
          ? _value._contributors
          : contributors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      budget: null == budget
          ? _value.budget
          : budget // ignore: cast_nullable_to_non_nullable
              as Money,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$TripMetadataDraftImpl extends TripMetadataDraft {
  const _$TripMetadataDraftImpl(
      {required this.name,
      required this.thumbnailTag,
      required final List<String> contributors,
      required this.budget,
      this.id,
      this.startDate,
      this.endDate})
      : _contributors = contributors,
        super._();

  @override
  final String name;
  @override
  final String thumbnailTag;
  final List<String> _contributors;
  @override
  List<String> get contributors {
    if (_contributors is EqualUnmodifiableListView) return _contributors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contributors);
  }

  @override
  final Money budget;
  @override
  final String? id;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;

  @override
  String toString() {
    return 'TripMetadata.draft(name: $name, thumbnailTag: $thumbnailTag, contributors: $contributors, budget: $budget, id: $id, startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripMetadataDraftImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.thumbnailTag, thumbnailTag) ||
                other.thumbnailTag == thumbnailTag) &&
            const DeepCollectionEquality()
                .equals(other._contributors, _contributors) &&
            (identical(other.budget, budget) || other.budget == budget) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      thumbnailTag,
      const DeepCollectionEquality().hash(_contributors),
      budget,
      id,
      startDate,
      endDate);

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TripMetadataDraftImplCopyWith<_$TripMetadataDraftImpl> get copyWith =>
      __$$TripMetadataDraftImplCopyWithImpl<_$TripMetadataDraftImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)
        draft,
    required TResult Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)
        strict,
  }) {
    return draft(
        name, thumbnailTag, contributors, budget, id, startDate, endDate);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)?
        draft,
    TResult? Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)?
        strict,
  }) {
    return draft?.call(
        name, thumbnailTag, contributors, budget, id, startDate, endDate);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)?
        draft,
    TResult Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)?
        strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(
          name, thumbnailTag, contributors, budget, id, startDate, endDate);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TripMetadataDraft value) draft,
    required TResult Function(TripMetadataStrict value) strict,
  }) {
    return draft(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TripMetadataDraft value)? draft,
    TResult? Function(TripMetadataStrict value)? strict,
  }) {
    return draft?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TripMetadataDraft value)? draft,
    TResult Function(TripMetadataStrict value)? strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(this);
    }
    return orElse();
  }
}

abstract class TripMetadataDraft extends TripMetadata {
  const factory TripMetadataDraft(
      {required final String name,
      required final String thumbnailTag,
      required final List<String> contributors,
      required final Money budget,
      final String? id,
      final DateTime? startDate,
      final DateTime? endDate}) = _$TripMetadataDraftImpl;
  const TripMetadataDraft._() : super._();

  @override
  String get name;
  @override
  String get thumbnailTag;
  @override
  List<String> get contributors;
  @override
  Money get budget;
  @override
  String? get id;
  @override
  DateTime? get startDate;
  @override
  DateTime? get endDate;

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TripMetadataDraftImplCopyWith<_$TripMetadataDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TripMetadataStrictImplCopyWith<$Res>
    implements $TripMetadataCopyWith<$Res> {
  factory _$$TripMetadataStrictImplCopyWith(_$TripMetadataStrictImpl value,
          $Res Function(_$TripMetadataStrictImpl) then) =
      __$$TripMetadataStrictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String thumbnailTag,
      List<String> contributors,
      Money budget,
      DateTime startDate,
      DateTime endDate});

  @override
  $MoneyCopyWith<$Res> get budget;
}

/// @nodoc
class __$$TripMetadataStrictImplCopyWithImpl<$Res>
    extends _$TripMetadataCopyWithImpl<$Res, _$TripMetadataStrictImpl>
    implements _$$TripMetadataStrictImplCopyWith<$Res> {
  __$$TripMetadataStrictImplCopyWithImpl(_$TripMetadataStrictImpl _value,
      $Res Function(_$TripMetadataStrictImpl) _then)
      : super(_value, _then);

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? thumbnailTag = null,
    Object? contributors = null,
    Object? budget = null,
    Object? startDate = null,
    Object? endDate = null,
  }) {
    return _then(_$TripMetadataStrictImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailTag: null == thumbnailTag
          ? _value.thumbnailTag
          : thumbnailTag // ignore: cast_nullable_to_non_nullable
              as String,
      contributors: null == contributors
          ? _value._contributors
          : contributors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      budget: null == budget
          ? _value.budget
          : budget // ignore: cast_nullable_to_non_nullable
              as Money,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$TripMetadataStrictImpl extends TripMetadataStrict {
  const _$TripMetadataStrictImpl(
      {required this.id,
      required this.name,
      required this.thumbnailTag,
      required final List<String> contributors,
      required this.budget,
      required this.startDate,
      required this.endDate})
      : _contributors = contributors,
        super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String thumbnailTag;
  final List<String> _contributors;
  @override
  List<String> get contributors {
    if (_contributors is EqualUnmodifiableListView) return _contributors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_contributors);
  }

  @override
  final Money budget;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;

  @override
  String toString() {
    return 'TripMetadata.strict(id: $id, name: $name, thumbnailTag: $thumbnailTag, contributors: $contributors, budget: $budget, startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripMetadataStrictImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.thumbnailTag, thumbnailTag) ||
                other.thumbnailTag == thumbnailTag) &&
            const DeepCollectionEquality()
                .equals(other._contributors, _contributors) &&
            (identical(other.budget, budget) || other.budget == budget) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      thumbnailTag,
      const DeepCollectionEquality().hash(_contributors),
      budget,
      startDate,
      endDate);

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TripMetadataStrictImplCopyWith<_$TripMetadataStrictImpl> get copyWith =>
      __$$TripMetadataStrictImplCopyWithImpl<_$TripMetadataStrictImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)
        draft,
    required TResult Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)
        strict,
  }) {
    return strict(
        id, name, thumbnailTag, contributors, budget, startDate, endDate);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)?
        draft,
    TResult? Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)?
        strict,
  }) {
    return strict?.call(
        id, name, thumbnailTag, contributors, budget, startDate, endDate);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            String? id,
            DateTime? startDate,
            DateTime? endDate)?
        draft,
    TResult Function(
            String id,
            String name,
            String thumbnailTag,
            List<String> contributors,
            Money budget,
            DateTime startDate,
            DateTime endDate)?
        strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(
          id, name, thumbnailTag, contributors, budget, startDate, endDate);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TripMetadataDraft value) draft,
    required TResult Function(TripMetadataStrict value) strict,
  }) {
    return strict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TripMetadataDraft value)? draft,
    TResult? Function(TripMetadataStrict value)? strict,
  }) {
    return strict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TripMetadataDraft value)? draft,
    TResult Function(TripMetadataStrict value)? strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(this);
    }
    return orElse();
  }
}

abstract class TripMetadataStrict extends TripMetadata {
  const factory TripMetadataStrict(
      {required final String id,
      required final String name,
      required final String thumbnailTag,
      required final List<String> contributors,
      required final Money budget,
      required final DateTime startDate,
      required final DateTime endDate}) = _$TripMetadataStrictImpl;
  const TripMetadataStrict._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String get thumbnailTag;
  @override
  List<String> get contributors;
  @override
  Money get budget;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;

  /// Create a copy of TripMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TripMetadataStrictImplCopyWith<_$TripMetadataStrictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
