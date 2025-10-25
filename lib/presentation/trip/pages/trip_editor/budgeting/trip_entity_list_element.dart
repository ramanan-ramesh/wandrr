import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';

class TripEntityListElement<T extends TripEntity> extends StatefulWidget {
  final UiElement<T> uiElement;
  final void Function(BuildContext context, UiElement<T>)? onPressed;
  final Widget Function(UiElement<T> uiElement, ValueNotifier<bool>)
      openedListElementCreator;
  final Widget Function(UiElement<T>) closedElementCreator;
  final bool Function(UiElement<T>)? canDelete;
  final bool Function(
      TripManagementState previousState,
      TripManagementState currentState,
      UiElement<T> uiElement)? additionalListItemBuildWhenCondition;
  final void Function(UiElement<T>)? onUpdatePressed;
  final void Function(UiElement<T>)? onDeletePressed;
  final String? Function(UiElement<T>)? errorMessageCreator;

  const TripEntityListElement(
      {required this.uiElement,
      required this.openedListElementCreator,
      required this.closedElementCreator,
      required this.canDelete,
      super.key,
      this.additionalListItemBuildWhenCondition,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.errorMessageCreator,
      this.onPressed});

  @override
  State<TripEntityListElement<T>> createState() =>
      _TripEntityListElementState<T>();
}

class _TripEntityListElementState<T extends TripEntity>
    extends State<TripEntityListElement<T>>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildListElement,
      builder: (BuildContext context, TripManagementState state) {
        var shouldOpenForEditing =
            widget.uiElement.dataState == DataState.select ||
                widget.uiElement.dataState == DataState.newUiEntry;
        return shouldOpenForEditing
            ? _createEditableTripEntityListElement(context)
            : _createTripEntityListElement(
                context, widget.closedElementCreator(widget.uiElement));
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _createEditableTripEntityListElement(BuildContext context) {
    ValueNotifier<bool> validityNotifier;
    if (widget.uiElement.dataState == DataState.newUiEntry) {
      validityNotifier = ValueNotifier(false);
    } else {
      validityNotifier = ValueNotifier(true);
    }
    return Column(
      children: [
        _createTripEntityListElement(
          context,
          widget.openedListElementCreator(
              widget.uiElement.clone(), validityNotifier),
        ),
        _EditableTripEntityButtonBar(
          validityNotifier: validityNotifier,
          onUpdatePressed: widget.onUpdatePressed,
          uiElement: widget.uiElement,
          canDelete: widget.canDelete?.call(widget.uiElement) ?? true,
          onDeletePressed: widget.onDeletePressed,
          errorMessageCreator: widget.errorMessageCreator,
        ),
      ],
    );
  }

  Widget _createTripEntityListElement(
      BuildContext context, Widget listElement) {
    return InkWell(
      onTap: () {
        if (widget.onPressed != null) {
          widget.onPressed?.call(context, widget.uiElement);
          return;
        }
        if (widget.uiElement.dataState != DataState.newUiEntry) {
          context.addTripManagementEvent(
              UpdateTripEntity.select(tripEntity: widget.uiElement.element));
        }
      },
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: listElement,
      ),
    );
  }

  bool _shouldBuildListElement(
      TripManagementState previousState, TripManagementState currentState) {
    if (widget.additionalListItemBuildWhenCondition != null) {
      if (widget.additionalListItemBuildWhenCondition!(
          previousState, currentState, widget.uiElement)) {
        return true;
      }
    }
    if (currentState.isTripEntityUpdated<T>()) {
      var transitUpdatedState = currentState as UpdatedTripEntity;
      var operationPerformed = transitUpdatedState.dataState;
      T modifiedTransitCollectionItem =
          transitUpdatedState.tripEntityModificationData.modifiedCollectionItem;
      var updatedTransitId = modifiedTransitCollectionItem.id;
      if (operationPerformed == DataState.select) {
        if (updatedTransitId == widget.uiElement.element.id &&
            updatedTransitId != null &&
            updatedTransitId.isNotEmpty) {
          if (widget.uiElement.dataState == DataState.none) {
            widget.uiElement.dataState =
                DataState.select; //Select a de-selected item
            return true;
          } else if (widget.uiElement.dataState == DataState.select) {
            widget.uiElement.element = modifiedTransitCollectionItem;
            widget.uiElement.dataState =
                DataState.none; // De-select a selected item
            return true;
          }
        } else {
          if (widget.uiElement.dataState == DataState.select) {
            widget.uiElement.dataState = DataState
                .none; // Don't do anything if selected item is not yet added to DB
            return true;
          }
        }
      } else if (operationPerformed == DataState.update &&
          widget.uiElement.element.id == updatedTransitId &&
          updatedTransitId != null &&
          updatedTransitId.isNotEmpty) {
        widget.uiElement.element = modifiedTransitCollectionItem;
        widget.uiElement.dataState = DataState.none;
        return true;
      }
    }
    return false;
  }
}

class _EditableTripEntityButtonBar<T extends TripEntity>
    extends StatefulWidget {
  const _EditableTripEntityButtonBar({
    required ValueNotifier<bool> validityNotifier,
    required this.onUpdatePressed,
    required this.uiElement,
    required this.canDelete,
    required this.onDeletePressed,
    super.key,
    this.errorMessageCreator,
  }) : _validityNotifier = validityNotifier;

  final ValueNotifier<bool> _validityNotifier;
  final void Function(UiElement<T> p1)? onUpdatePressed;
  final UiElement<T> uiElement;
  final bool canDelete;
  final void Function(UiElement<T> p1)? onDeletePressed;
  final String? Function(UiElement<T>)? errorMessageCreator;

  @override
  State<_EditableTripEntityButtonBar<T>> createState() =>
      _EditableTripEntityButtonBarState<T>();
}

class _EditableTripEntityButtonBarState<T extends TripEntity>
    extends State<_EditableTripEntityButtonBar<T>>
    with SingleTickerProviderStateMixin {
  String? _errorMessage;
  bool _showErrorMessage = false;

  late final AnimationController _animationController;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.1, 0), end: const Offset(-0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.1, 0), end: const Offset(0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.1, 0), end: const Offset(-0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.1, 0), end: Offset.zero),
          weight: 1),
    ]).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutCirc));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_showErrorMessage && _errorMessage != null)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Visibility(
                visible: _showErrorMessage,
                child: SlideTransition(
                  position: _animation,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: PlatformSubmitterFAB.conditionallyEnabled(
            valueNotifier: widget._validityNotifier,
            child: Icon(Icons.check_rounded),
            callback: () {
              if (widget.onUpdatePressed != null) {
                widget.onUpdatePressed!(widget.uiElement);
                return;
              }
              if (widget.uiElement.dataState == DataState.newUiEntry) {
                context.addTripManagementEvent(UpdateTripEntity<T>.create(
                    tripEntity: widget.uiElement.element));
              } else {
                context.addTripManagementEvent(UpdateTripEntity<T>.update(
                    tripEntity: widget.uiElement.element));
              }
            },
            callbackOnClickWhileDisabled: widget.errorMessageCreator == null
                ? null
                : () {
                    var errorMessage =
                        widget.errorMessageCreator!(widget.uiElement);
                    if (errorMessage != null) {
                      _showError(errorMessage);
                    }
                  },
          ),
        ),
        if (widget.canDelete)
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: PlatformSubmitterFAB(
              child: Icon(Icons.delete_rounded),
              isEnabledInitially: true,
              callback: () {
                if (widget.onDeletePressed != null) {
                  widget.onDeletePressed!(widget.uiElement);
                  return;
                }
                context.addTripManagementEvent(UpdateTripEntity<T>.delete(
                    tripEntity: widget.uiElement.element));
              },
            ),
          ),
      ],
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _showErrorMessage = true;
    });
    unawaited(_animationController.repeat(reverse: true));
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showErrorMessage = false;
        });
      }
    });
  }
}
