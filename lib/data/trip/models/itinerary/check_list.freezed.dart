// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CheckList {
  String get tripId => throw _privateConstructorUsedError;
  String? get id => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  List<CheckListItem> get items => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId, String? id, String? title, List<CheckListItem> items)
        draft,
    required TResult Function(
            String tripId, String id, String title, List<CheckListItem> items)
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String tripId, String? id, String? title,
            List<CheckListItem> items)?
        draft,
    TResult? Function(
            String tripId, String id, String title, List<CheckListItem> items)?
        strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String tripId, String? id, String? title,
            List<CheckListItem> items)?
        draft,
    TResult Function(
            String tripId, String id, String title, List<CheckListItem> items)?
        strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CheckListDraft value) draft,
    required TResult Function(CheckListStrict value) strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CheckListDraft value)? draft,
    TResult? Function(CheckListStrict value)? strict,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CheckListDraft value)? draft,
    TResult Function(CheckListStrict value)? strict,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckListCopyWith<CheckList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckListCopyWith<$Res> {
  factory $CheckListCopyWith(CheckList value, $Res Function(CheckList) then) =
      _$CheckListCopyWithImpl<$Res, CheckList>;
  @useResult
  $Res call(
      {String tripId, String id, String title, List<CheckListItem> items});
}

/// @nodoc
class _$CheckListCopyWithImpl<$Res, $Val extends CheckList>
    implements $CheckListCopyWith<$Res> {
  _$CheckListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? id = null,
    Object? title = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id!
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title!
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CheckListItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckListDraftImplCopyWith<$Res>
    implements $CheckListCopyWith<$Res> {
  factory _$$CheckListDraftImplCopyWith(_$CheckListDraftImpl value,
          $Res Function(_$CheckListDraftImpl) then) =
      __$$CheckListDraftImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId, String? id, String? title, List<CheckListItem> items});
}

/// @nodoc
class __$$CheckListDraftImplCopyWithImpl<$Res>
    extends _$CheckListCopyWithImpl<$Res, _$CheckListDraftImpl>
    implements _$$CheckListDraftImplCopyWith<$Res> {
  __$$CheckListDraftImplCopyWithImpl(
      _$CheckListDraftImpl _value, $Res Function(_$CheckListDraftImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? id = freezed,
    Object? title = freezed,
    Object? items = null,
  }) {
    return _then(_$CheckListDraftImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CheckListItem>,
    ));
  }
}

/// @nodoc

class _$CheckListDraftImpl extends CheckListDraft {
  const _$CheckListDraftImpl(
      {required this.tripId,
      this.id,
      this.title,
      final List<CheckListItem> items = const []})
      : _items = items,
        super._();

  @override
  final String tripId;
  @override
  final String? id;
  @override
  final String? title;
  final List<CheckListItem> _items;
  @override
  @JsonKey()
  List<CheckListItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'CheckList.draft(tripId: $tripId, id: $id, title: $title, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckListDraftImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tripId, id, title,
      const DeepCollectionEquality().hash(_items));

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckListDraftImplCopyWith<_$CheckListDraftImpl> get copyWith =>
      __$$CheckListDraftImplCopyWithImpl<_$CheckListDraftImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId, String? id, String? title, List<CheckListItem> items)
        draft,
    required TResult Function(
            String tripId, String id, String title, List<CheckListItem> items)
        strict,
  }) {
    return draft(tripId, id, title, items);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String tripId, String? id, String? title,
            List<CheckListItem> items)?
        draft,
    TResult? Function(
            String tripId, String id, String title, List<CheckListItem> items)?
        strict,
  }) {
    return draft?.call(tripId, id, title, items);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String tripId, String? id, String? title,
            List<CheckListItem> items)?
        draft,
    TResult Function(
            String tripId, String id, String title, List<CheckListItem> items)?
        strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(tripId, id, title, items);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CheckListDraft value) draft,
    required TResult Function(CheckListStrict value) strict,
  }) {
    return draft(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CheckListDraft value)? draft,
    TResult? Function(CheckListStrict value)? strict,
  }) {
    return draft?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CheckListDraft value)? draft,
    TResult Function(CheckListStrict value)? strict,
    required TResult orElse(),
  }) {
    if (draft != null) {
      return draft(this);
    }
    return orElse();
  }
}

abstract class CheckListDraft extends CheckList {
  const factory CheckListDraft(
      {required final String tripId,
      final String? id,
      final String? title,
      final List<CheckListItem> items}) = _$CheckListDraftImpl;
  const CheckListDraft._() : super._();

  @override
  String get tripId;
  @override
  String? get id;
  @override
  String? get title;
  @override
  List<CheckListItem> get items;

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckListDraftImplCopyWith<_$CheckListDraftImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CheckListStrictImplCopyWith<$Res>
    implements $CheckListCopyWith<$Res> {
  factory _$$CheckListStrictImplCopyWith(_$CheckListStrictImpl value,
          $Res Function(_$CheckListStrictImpl) then) =
      __$$CheckListStrictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tripId, String id, String title, List<CheckListItem> items});
}

/// @nodoc
class __$$CheckListStrictImplCopyWithImpl<$Res>
    extends _$CheckListCopyWithImpl<$Res, _$CheckListStrictImpl>
    implements _$$CheckListStrictImplCopyWith<$Res> {
  __$$CheckListStrictImplCopyWithImpl(
      _$CheckListStrictImpl _value, $Res Function(_$CheckListStrictImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tripId = null,
    Object? id = null,
    Object? title = null,
    Object? items = null,
  }) {
    return _then(_$CheckListStrictImpl(
      tripId: null == tripId
          ? _value.tripId
          : tripId // ignore: cast_nullable_to_non_nullable
              as String,
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<CheckListItem>,
    ));
  }
}

/// @nodoc

class _$CheckListStrictImpl extends CheckListStrict {
  const _$CheckListStrictImpl(
      {required this.tripId,
      required this.id,
      required this.title,
      required final List<CheckListItem> items})
      : _items = items,
        super._();

  @override
  final String tripId;
  @override
  final String id;
  @override
  final String title;
  final List<CheckListItem> _items;
  @override
  List<CheckListItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'CheckList.strict(tripId: $tripId, id: $id, title: $title, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckListStrictImpl &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tripId, id, title,
      const DeepCollectionEquality().hash(_items));

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckListStrictImplCopyWith<_$CheckListStrictImpl> get copyWith =>
      __$$CheckListStrictImplCopyWithImpl<_$CheckListStrictImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String tripId, String? id, String? title, List<CheckListItem> items)
        draft,
    required TResult Function(
            String tripId, String id, String title, List<CheckListItem> items)
        strict,
  }) {
    return strict(tripId, id, title, items);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String tripId, String? id, String? title,
            List<CheckListItem> items)?
        draft,
    TResult? Function(
            String tripId, String id, String title, List<CheckListItem> items)?
        strict,
  }) {
    return strict?.call(tripId, id, title, items);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String tripId, String? id, String? title,
            List<CheckListItem> items)?
        draft,
    TResult Function(
            String tripId, String id, String title, List<CheckListItem> items)?
        strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(tripId, id, title, items);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CheckListDraft value) draft,
    required TResult Function(CheckListStrict value) strict,
  }) {
    return strict(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CheckListDraft value)? draft,
    TResult? Function(CheckListStrict value)? strict,
  }) {
    return strict?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CheckListDraft value)? draft,
    TResult Function(CheckListStrict value)? strict,
    required TResult orElse(),
  }) {
    if (strict != null) {
      return strict(this);
    }
    return orElse();
  }
}

abstract class CheckListStrict extends CheckList {
  const factory CheckListStrict(
      {required final String tripId,
      required final String id,
      required final String title,
      required final List<CheckListItem> items}) = _$CheckListStrictImpl;
  const CheckListStrict._() : super._();

  @override
  String get tripId;
  @override
  String get id;
  @override
  String get title;
  @override
  List<CheckListItem> get items;

  /// Create a copy of CheckList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckListStrictImplCopyWith<_$CheckListStrictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
