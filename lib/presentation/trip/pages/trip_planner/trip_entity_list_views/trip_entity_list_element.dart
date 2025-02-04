import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';

class TripEntityListElement<T extends TripEntity> extends StatefulWidget {
  UiElement<T> uiElement;
  void Function(BuildContext context, UiElement<T>)? onPressed;
  Widget Function(UiElement<T> uiElement, ValueNotifier<bool>)
      openedListElementCreator;
  Widget Function() closedElementCreator;
  bool Function(UiElement<T>)? canDelete;
  bool Function(
      TripManagementState previousState,
      TripManagementState currentState,
      UiElement<T> uiElement)? additionalListItemBuildWhenCondition;
  void Function(UiElement<T>)? onUpdatePressed;
  void Function(UiElement<T>)? onDeletePressed;
  String? Function(UiElement<T>)? errorMessageCreator;

  TripEntityListElement(
      {super.key,
      required this.uiElement,
      required this.openedListElementCreator,
      required this.closedElementCreator,
      required this.canDelete,
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
            widget.uiElement.dataState == DataState.Select ||
                widget.uiElement.dataState == DataState.NewUiEntry;
        return shouldOpenForEditing
            ? _OpenedTripEntityUiElement(
                uiElement: widget.uiElement,
                openedListElementCreator: widget.openedListElementCreator,
                onUpdatePressed: widget.onUpdatePressed,
                onDeletePressed: widget.onDeletePressed,
                canDelete: widget.canDelete != null
                    ? widget.canDelete!(widget.uiElement)
                    : true,
                onPressed: () {
                  if (widget.onPressed != null) {
                    widget.onPressed?.call(context, widget.uiElement);
                    return;
                  }
                  if (widget.uiElement.dataState != DataState.NewUiEntry) {
                    context.addTripManagementEvent(UpdateTripEntity.select(
                        tripEntity: widget.uiElement.element));
                  }
                },
                errorMessageCreator: widget.errorMessageCreator,
              )
            : Material(
                child: InkWell(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: context.isLightTheme
                        ? null
                        : Colors.grey.shade900, //ThemingRequired
                    child: widget.closedElementCreator(),
                  ),
                  onTap: () {
                    if (widget.onPressed != null) {
                      widget.onPressed?.call(context, widget.uiElement);
                      return;
                    }
                    context.addTripManagementEvent(UpdateTripEntity.select(
                        tripEntity: widget.uiElement.element));
                  },
                ),
              );
      },
      listener: (BuildContext context, TripManagementState state) {},
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
      if (operationPerformed == DataState.Select) {
        if (updatedTransitId == widget.uiElement.element.id &&
            updatedTransitId != null &&
            updatedTransitId.isNotEmpty) {
          if (widget.uiElement.dataState == DataState.None) {
            widget.uiElement.dataState =
                DataState.Select; //Select a de-selected item
            return true;
          } else if (widget.uiElement.dataState == DataState.Select) {
            widget.uiElement.element = modifiedTransitCollectionItem;
            widget.uiElement.dataState =
                DataState.None; // De-select a selected item
            return true;
          }
        } else {
          if (widget.uiElement.dataState == DataState.Select) {
            widget.uiElement.dataState = DataState
                .None; // Don't do anything if selected item is not yet added to DB
            return true;
          }
        }
      } else if (operationPerformed == DataState.Update &&
          widget.uiElement.element.id == updatedTransitId &&
          updatedTransitId != null &&
          updatedTransitId.isNotEmpty) {
        widget.uiElement.element = modifiedTransitCollectionItem;
        widget.uiElement.dataState = DataState.None;
        return true;
      }
    }
    return false;
  }
}

class _OpenedTripEntityUiElement<T extends TripEntity> extends StatelessWidget {
  UiElement<T> uiElement;
  final ValueNotifier<bool> _validityNotifier;
  Widget Function(UiElement<T> uiElement, ValueNotifier<bool>)
      openedListElementCreator;
  void Function(UiElement<T>)? onUpdatePressed;
  void Function(UiElement<T>)? onDeletePressed;
  bool canDelete;
  VoidCallback onPressed;
  String? Function(UiElement<T>)? errorMessageCreator;

  _OpenedTripEntityUiElement(
      {super.key,
      required UiElement<T> uiElement,
      this.onDeletePressed,
      this.onUpdatePressed,
      required this.canDelete,
      required this.onPressed,
      required this.openedListElementCreator,
      this.errorMessageCreator})
      : uiElement = uiElement.clone(),
        _validityNotifier = ValueNotifier(
            uiElement.dataState == DataState.NewUiEntry ? false : true);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          child: InkWell(
            onTap: onPressed,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color:
                  context.isLightTheme ? Colors.teal.shade300 : Colors.white10,
              child: openedListElementCreator(
                  uiElement.clone(), _validityNotifier),
            ),
          ),
        ),
        _EditableTripEntityButtonBar(
            validityNotifier: _validityNotifier,
            onUpdatePressed: onUpdatePressed,
            uiElement: uiElement,
            canDelete: canDelete,
            onDeletePressed: onDeletePressed,
            errorMessageCreator: errorMessageCreator),
      ],
    );
  }
}

class _EditableTripEntityButtonBar<T extends TripEntity>
    extends StatefulWidget {
  _EditableTripEntityButtonBar({
    super.key,
    required ValueNotifier<bool> validityNotifier,
    required this.onUpdatePressed,
    required this.uiElement,
    required this.canDelete,
    required this.onDeletePressed,
    this.errorMessageCreator,
  }) : _validityNotifier = validityNotifier;

  final ValueNotifier<bool> _validityNotifier;
  final void Function(UiElement<T> p1)? onUpdatePressed;
  final UiElement<T> uiElement;
  final bool canDelete;
  final void Function(UiElement<T> p1)? onDeletePressed;
  String? Function(UiElement<T>)? errorMessageCreator;

  @override
  State<_EditableTripEntityButtonBar<T>> createState() =>
      _EditableTripEntityButtonBarState<T>();
}

class _EditableTripEntityButtonBarState<T extends TripEntity>
    extends State<_EditableTripEntityButtonBar<T>>
    with SingleTickerProviderStateMixin {
  String? _errorMessage;
  bool _showErrorMessage = false;

  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0, 0), end: const Offset(0.1, 0)),
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
          tween: Tween(begin: const Offset(-0.1, 0), end: const Offset(0, 0)),
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
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(3.0),
          child: PlatformSubmitterFAB.conditionallyEnabled(
            valueNotifier: widget._validityNotifier,
            icon: Icons.check_rounded,
            context: context,
            callback: () {
              if (widget.onUpdatePressed != null) {
                widget.onUpdatePressed!(widget.uiElement);
                return;
              }
              if (widget.uiElement.dataState == DataState.NewUiEntry) {
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
              icon: Icons.delete_rounded,
              isEnabledInitially: true,
              context: context,
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
    _animationController.repeat(reverse: true);
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showErrorMessage = false;
        });
      }
    });
  }
}
