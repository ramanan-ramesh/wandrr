// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CheckListItem {
  String get item => throw _privateConstructorUsedError;
  bool get isChecked => throw _privateConstructorUsedError;

  /// Create a copy of CheckListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckListItemCopyWith<CheckListItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckListItemCopyWith<$Res> {
  factory $CheckListItemCopyWith(
          CheckListItem value, $Res Function(CheckListItem) then) =
      _$CheckListItemCopyWithImpl<$Res, CheckListItem>;
  @useResult
  $Res call({String item, bool isChecked});
}

/// @nodoc
class _$CheckListItemCopyWithImpl<$Res, $Val extends CheckListItem>
    implements $CheckListItemCopyWith<$Res> {
  _$CheckListItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = null,
    Object? isChecked = null,
  }) {
    return _then(_value.copyWith(
      item: null == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as String,
      isChecked: null == isChecked
          ? _value.isChecked
          : isChecked // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckListItemImplCopyWith<$Res>
    implements $CheckListItemCopyWith<$Res> {
  factory _$$CheckListItemImplCopyWith(
          _$CheckListItemImpl value, $Res Function(_$CheckListItemImpl) then) =
      __$$CheckListItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String item, bool isChecked});
}

/// @nodoc
class __$$CheckListItemImplCopyWithImpl<$Res>
    extends _$CheckListItemCopyWithImpl<$Res, _$CheckListItemImpl>
    implements _$$CheckListItemImplCopyWith<$Res> {
  __$$CheckListItemImplCopyWithImpl(
      _$CheckListItemImpl _value, $Res Function(_$CheckListItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckListItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = null,
    Object? isChecked = null,
  }) {
    return _then(_$CheckListItemImpl(
      item: null == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as String,
      isChecked: null == isChecked
          ? _value.isChecked
          : isChecked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$CheckListItemImpl extends _CheckListItem {
  const _$CheckListItemImpl({required this.item, required this.isChecked})
      : super._();

  @override
  final String item;
  @override
  final bool isChecked;

  @override
  String toString() {
    return 'CheckListItem(item: $item, isChecked: $isChecked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckListItemImpl &&
            (identical(other.item, item) || other.item == item) &&
            (identical(other.isChecked, isChecked) ||
                other.isChecked == isChecked));
  }

  @override
  int get hashCode => Object.hash(runtimeType, item, isChecked);

  /// Create a copy of CheckListItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckListItemImplCopyWith<_$CheckListItemImpl> get copyWith =>
      __$$CheckListItemImplCopyWithImpl<_$CheckListItemImpl>(this, _$identity);
}

abstract class _CheckListItem extends CheckListItem {
  const factory _CheckListItem(
      {required final String item,
      required final bool isChecked}) = _$CheckListItemImpl;
  const _CheckListItem._() : super._();

  @override
  String get item;
  @override
  bool get isChecked;

  /// Create a copy of CheckListItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckListItemImplCopyWith<_$CheckListItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
