import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/trip_data.dart';
import 'package:wandrr/platform_elements/button.dart';

class TripEntityListElement<T extends TripEntity> extends StatelessWidget {
  UiElement<T> uiElement;
  void Function(BuildContext context, UiElement<T>)? onPressed;
  Widget Function() openedElementCreator;
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

  TripEntityListElement(
      {super.key,
      required this.uiElement,
      required this.openedElementCreator,
      required this.openedListElementCreator,
      required this.closedElementCreator,
      required this.canDelete,
      this.additionalListItemBuildWhenCondition,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildListElement,
      builder: (BuildContext context, TripManagementState state) {
        var shouldOpenForEditing = uiElement.dataState == DataState.Select ||
            uiElement.dataState == DataState.NewUiEntry;
        return shouldOpenForEditing
            ? _OpenedTripEntityUiElement(
                uiElement: uiElement,
                openedListElementCreator: openedListElementCreator,
                onUpdatePressed: onUpdatePressed,
                onDeletePressed: onDeletePressed,
                canDelete: canDelete != null ? canDelete!(uiElement) : true,
                onPressed: () {
                  if (uiElement.dataState != DataState.NewUiEntry) {
                    var tripManagementBloc =
                        BlocProvider.of<TripManagementBloc>(context);
                    tripManagementBloc.add(
                        UpdateTripEntity.select(tripEntity: uiElement.element));
                  }
                },
              )
            : Material(
                child: InkWell(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.grey.shade900,
                    child: closedElementCreator(),
                  ),
                  onTap: () {
                    var tripManagementBloc =
                        BlocProvider.of<TripManagementBloc>(context);
                    tripManagementBloc.add(
                        UpdateTripEntity.select(tripEntity: uiElement.element));
                  },
                ),
              );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildListElement(
      TripManagementState previousState, TripManagementState currentState) {
    if (additionalListItemBuildWhenCondition != null) {
      if (additionalListItemBuildWhenCondition!(
          previousState, currentState, uiElement)) {
        return true;
      }
    }
    if (currentState.isTripEntity<T>()) {
      var transitUpdatedState = currentState as UpdatedTripEntity;
      var operationPerformed = transitUpdatedState.dataState;
      T modifiedTransitCollectionItem =
          transitUpdatedState.tripEntityModificationData.modifiedCollectionItem;
      var updatedTransitId = modifiedTransitCollectionItem.id;
      if (operationPerformed == DataState.Select) {
        if (updatedTransitId == uiElement.element.id) {
          if (uiElement.dataState == DataState.None) {
            uiElement.dataState = DataState.Select;
            return true;
          } else if (uiElement.dataState == DataState.Select) {
            uiElement.dataState = DataState.None;
            return true;
          }
        } else {
          if (uiElement.dataState == DataState.Select) {
            uiElement.dataState = DataState.None;
            return true;
          }
        }
      } else if (operationPerformed == DataState.Update &&
          uiElement.element.id == modifiedTransitCollectionItem.id) {
        uiElement.element = modifiedTransitCollectionItem;
        uiElement.dataState = DataState.None;
        return true;
      }
    }
    return false;
  }
}

class _OpenedTripEntityUiElement<T extends TripEntity> extends StatelessWidget {
  UiElement<T> uiElement;
  final _validityNotifier = ValueNotifier(false);
  Widget Function(UiElement<T> uiElement, ValueNotifier<bool>)
      openedListElementCreator;
  void Function(UiElement<T>)? onUpdatePressed;
  void Function(UiElement<T>)? onDeletePressed;
  bool canDelete;
  VoidCallback onPressed;

  _OpenedTripEntityUiElement(
      {super.key,
      required UiElement<T> uiElement,
      this.onDeletePressed,
      this.onUpdatePressed,
      required this.canDelete,
      required this.onPressed,
      required this.openedListElementCreator})
      : uiElement = uiElement.clone();

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
              color: Colors.white10,
              child: openedListElementCreator(
                  uiElement.clone(), _validityNotifier),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(3.0),
              child: PlatformSubmitterFAB.conditionallyEnabled(
                  valueNotifier: _validityNotifier,
                  icon: Icons.check_rounded,
                  context: context,
                  callback: () {
                    if (onUpdatePressed != null) {
                      onUpdatePressed!(uiElement);
                      return;
                    }
                    var tripManagementBloc =
                        BlocProvider.of<TripManagementBloc>(context);
                    if (uiElement.dataState == DataState.NewUiEntry) {
                      tripManagementBloc.add(UpdateTripEntity<T>.create(
                          tripEntity: uiElement.element));
                    } else {
                      tripManagementBloc.add(UpdateTripEntity<T>.update(
                          tripEntity: uiElement.element));
                    }
                  }),
            ),
            if (canDelete)
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: PlatformSubmitterFAB(
                  icon: Icons.delete_rounded,
                  isEnabledInitially: true,
                  context: context,
                  callback: () {
                    if (onDeletePressed != null) {
                      onDeletePressed!(uiElement);
                      return;
                    }
                    var tripManagementBloc =
                        BlocProvider.of<TripManagementBloc>(context);
                    tripManagementBloc.add(UpdateTripEntity<T>.delete(
                        tripEntity: uiElement.element));
                  },
                ),
              )
          ],
        )
      ],
    );
  }
}
