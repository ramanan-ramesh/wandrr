import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

import 'trip_entity_list_element.dart';

class TripEntityListView<T extends TripEntity> extends StatefulWidget {
  final Widget Function(UiElement<T>, ValueNotifier<bool>)
      openedListElementCreator;
  final void Function(UiElement<T>)? onUpdatePressed;
  final void Function(UiElement<T>)? onDeletePressed;
  final Widget Function(UiElement<T> uiElement) closedListElementCreator;
  final String emptyListMessage;
  Widget? headerTileButton;
  VoidCallback? headerTileActionButtonCallback;
  BlocBuilderCondition<TripManagementState>? additionalListBuildWhenCondition;
  bool Function(
      TripManagementState previousState,
      TripManagementState currentState,
      UiElement<T> uiElement)? additionalListItemBuildWhenCondition;
  final String headerTileLabel;
  void Function(BuildContext context, UiElement<T>)? onUiElementPressed;
  FutureOr<Iterable<UiElement<T>>> Function(List<UiElement<T>> uiElements)
      uiElementsSorter;
  final List<UiElement<T>> Function(TripDataFacade tripDataModelFacade)
      uiElementsCreator;
  bool Function(UiElement<T>)? canDelete;
  String? Function(UiElement<T>)? errorMessageCreator;

  TripEntityListView(
      {super.key,
      required this.openedListElementCreator,
      required this.closedListElementCreator,
      required this.emptyListMessage,
      required this.headerTileLabel,
      required this.uiElementsSorter,
      required this.uiElementsCreator,
      this.onUiElementPressed,
      this.additionalListBuildWhenCondition,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.canDelete,
      this.errorMessageCreator,
      this.additionalListItemBuildWhenCondition});

  TripEntityListView.customHeaderTileButton(
      {super.key,
      required this.openedListElementCreator,
      required this.closedListElementCreator,
      required this.emptyListMessage,
      required this.headerTileLabel,
      required this.uiElementsSorter,
      required Widget this.headerTileButton,
      this.headerTileActionButtonCallback,
      this.additionalListBuildWhenCondition,
      this.onUiElementPressed,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.canDelete,
      required this.uiElementsCreator,
      this.errorMessageCreator,
      this.additionalListItemBuildWhenCondition});

  @override
  State<TripEntityListView<T>> createState() => _TripEntityListViewState<T>();
}

class _TripEntityListViewState<T extends TripEntity>
    extends State<TripEntityListView<T>> {
  var _uiElements = <UiElement<T>>[];
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildList,
      builder: (BuildContext context, TripManagementState state) {
        _updateListElementsOnBuild(context, state);
        return FutureBuilder<Iterable<UiElement<T>>>(
          future:
              _uiElementsSorterWrapper(widget.uiElementsSorter, _uiElements),
          builder: (BuildContext context,
              AsyncSnapshot<Iterable<UiElement<T>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              _uiElements = snapshot.data!.toList();
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  if (index == 0) {
                    return _createHeaderTile(context);
                  } else if (index == 1 && _uiElements.isEmpty) {
                    return _createEmptyMessagePane(context);
                  } else if (index > 0) {
                    var uiElement = _uiElements.elementAt(index - 1);
                    if (uiElement.dataState == DataState.NewUiEntry &&
                        state is UpdatedTripEntity &&
                        state.dataState == DataState.NewUiEntry) {}
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: TripEntityListElement<T>(
                        uiElement: uiElement,
                        onPressed: widget.onUiElementPressed,
                        canDelete: widget.canDelete,
                        additionalListItemBuildWhenCondition:
                            widget.additionalListItemBuildWhenCondition,
                        onUpdatePressed: widget.onUpdatePressed,
                        onDeletePressed: widget.onDeletePressed,
                        openedListElementCreator:
                            widget.openedListElementCreator,
                        closedElementCreator: () => Container(
                            color: Colors.black12,
                            child: widget.closedListElementCreator(uiElement)),
                        errorMessageCreator: widget.errorMessageCreator,
                      ),
                    );
                  }
                  return null;
                },
                childCount: _isCollapsed
                    ? 1
                    : (_uiElements.isEmpty ? 2 : _uiElements.length + 1),
              ),
            );
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<T>()) {
      var updatedTripEntityState = currentState as UpdatedTripEntity;
      if (updatedTripEntityState.dataState == DataState.Delete ||
          updatedTripEntityState.dataState == DataState.Create ||
          updatedTripEntityState.dataState == DataState.NewUiEntry) {
        return true;
      }
    } else if (widget.additionalListBuildWhenCondition != null) {
      return widget.additionalListBuildWhenCondition!(
          previousState, currentState);
    }
    return false;
  }

  Future<Iterable<UiElement<T>>> _uiElementsSorterWrapper(
      FutureOr<Iterable<UiElement<T>>> Function(List<UiElement<T>>) func,
      List<UiElement<T>> uiElements) async {
    return Future.value(func(uiElements));
  }

  Container _createEmptyMessagePane(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.transparent,
      child: Center(
        child: PlatformTextElements.createSubHeader(
            context: context,
            text: widget.emptyListMessage,
            textAlign: TextAlign.center),
      ),
    );
  }

  Widget _createHeaderTile(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return ListTile(
          //TODO: Fix this for tamil, the trailing widget consumes entire space in case of expenses
          leading:
              Icon(_isCollapsed ? Icons.menu_open_rounded : Icons.list_rounded),
          title: Text(
            widget.headerTileLabel,
          ),
          onTap: () {
            _isCollapsed = !_isCollapsed;
            setState(() {});
          },
          trailing: Container(
            constraints: BoxConstraints(
              maxWidth: 200,
            ),
            child: FittedBox(
              child: widget.headerTileButton != null
                  ? widget.headerTileButton!
                  : _buildCreateTripEntityButton(context),
            ),
          ),
        );
      },
      listener: (BuildContext context, TripManagementState state) {
        if (state.isTripEntityUpdated<T>() &&
            (state as UpdatedTripEntity).dataState == DataState.NewUiEntry) {
          _isCollapsed = false;
          widget.headerTileActionButtonCallback?.call();
          setState(() {});
        }
      },
      buildWhen: (previousState, currentState) {
        return currentState.isTripEntityUpdated<T>();
      },
    );
  }

  Widget _buildCreateTripEntityButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var shouldEnableButton = !_uiElements
            .any((element) => element.dataState == DataState.NewUiEntry);
        if (state.isTripEntityUpdated<T>()) {
          var updatedTripEntityState = state as UpdatedTripEntity;
          if (updatedTripEntityState.dataState == DataState.NewUiEntry) {
            shouldEnableButton = false;
          } else if (updatedTripEntityState.dataState == DataState.Delete &&
              updatedTripEntityState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
            shouldEnableButton = true;
          }
        }
        return FloatingActionButton.extended(
          onPressed: !shouldEnableButton
              ? null
              : () {
                  context.addTripManagementEvent(
                      UpdateTripEntity<T>.createNewUiEntry());
                },
          label: Text(context.localizations.addNew),
          icon: Icon(Icons.add_rounded),
          elevation: 0,
        );
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<T>()) {
          var updatedTripEntityState = currentState as UpdatedTripEntity;
          return updatedTripEntityState.dataState == DataState.Create ||
              updatedTripEntityState.dataState == DataState.NewUiEntry ||
              updatedTripEntityState.dataState == DataState.Delete;
        }
        return false;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  void _updateListElementsOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = context.activeTrip;

    _uiElements.removeWhere((x) => x.dataState != DataState.NewUiEntry);

    if (state.isTripEntityUpdated<T>()) {
      var updatedTripEntityState = state as UpdatedTripEntity;
      var updatedTripEntityDataState = updatedTripEntityState.dataState;
      if (updatedTripEntityState.tripEntityModificationData.isFromEvent) {
        switch (updatedTripEntityDataState) {
          case DataState.Create:
            {
              _uiElements.removeWhere(
                  (element) => element.dataState == DataState.NewUiEntry);
              break;
            }
          case DataState.Delete:
            {
              if (updatedTripEntityState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
                _uiElements.removeWhere(
                    (element) => element.dataState == DataState.NewUiEntry);
              }
              break;
            }
          case DataState.NewUiEntry:
            {
              if (!_uiElements.any(
                  (element) => element.dataState == DataState.NewUiEntry)) {
                _uiElements.add(UiElement(
                    element: updatedTripEntityState
                        .tripEntityModificationData.modifiedCollectionItem,
                    dataState: DataState.NewUiEntry));
              }
              break;
            }
          default:
            {
              break;
            }
        }
      }
    }
    _uiElements.addAll(widget.uiElementsCreator(activeTrip));
  }
}
