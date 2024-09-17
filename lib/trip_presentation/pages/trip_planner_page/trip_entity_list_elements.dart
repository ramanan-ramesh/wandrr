import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/bloc.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/events.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/states.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/trip_data.dart';
import 'package:wandrr/trip_data/models/trip_entity.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';

import 'trip_entity_list_element.dart';

class TripEntityListView<T extends TripEntity> extends StatefulWidget {
  Widget Function(UiElement<T>, ValueNotifier<bool>) openedListElementCreator;
  void Function(UiElement<T>)? onUpdatePressed;
  void Function(UiElement<T>)? onDeletePressed;
  Widget Function(UiElement<T> uiElement) closedListElementCreator;
  String emptyListMessage;
  Widget? headerTileButton;
  VoidCallback? headerTileButtonCallback;
  BlocBuilderCondition<TripManagementState>? additionalListBuildWhenCondition;
  bool Function(
      TripManagementState previousState,
      TripManagementState currentState,
      UiElement<T> uiElement)? additionalListItemBuildWhenCondition;
  String headerTileLabel;
  void Function(BuildContext context, UiElement<T>)? onUiElementPressed;
  FutureOr<void> Function(List<UiElement<T>> uiElements) uiElementsSorter;
  List<UiElement<T>> Function(TripDataFacade tripDataModelFacade)
      uiElementsCreator;
  bool Function(UiElement<T>)? canDelete;

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
      this.additionalListItemBuildWhenCondition});

  TripEntityListView.customHeaderTileButton(
      {super.key,
      required this.openedListElementCreator,
      required this.closedListElementCreator,
      required this.emptyListMessage,
      required this.headerTileLabel,
      required this.uiElementsSorter,
      required Widget this.headerTileButton,
      this.headerTileButtonCallback,
      this.additionalListBuildWhenCondition,
      this.onUiElementPressed,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.canDelete,
      required this.uiElementsCreator,
      this.additionalListItemBuildWhenCondition});

  @override
  State<TripEntityListView<T>> createState() => _TripEntityListViewState<T>();
}

class _TripEntityListViewState<T extends TripEntity>
    extends State<TripEntityListView<T>> with SingleTickerProviderStateMixin {
  final _uiElements = <UiElement<T>>[];
  bool _isCollapsed = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildList,
      builder: (BuildContext context, TripManagementState state) {
        _updateListElementsOnBuild(context, state);
        return FutureBuilder<void>(
          future:
              _uiElementsSorterWrapper(widget.uiElementsSorter, _uiElements),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            return SliverList.builder(
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return _createHeaderTile(context);
                } else if (index == 1 && _uiElements.isEmpty) {
                  return _createEmptyMessagePane(context);
                } else if (index > 0) {
                  var uiElement = _uiElements.elementAt(index - 1);
                  return TripEntityListElement<T>(
                      uiElement: uiElement,
                      onPressed: widget.onUiElementPressed,
                      openedElementCreator: () => Container(
                            color: Colors.white10,
                            child: widget.openedListElementCreator(
                                uiElement, ValueNotifier(false)),
                          ),
                      canDelete: widget.canDelete,
                      openedListElementCreator: widget.openedListElementCreator,
                      closedElementCreator: () => Container(
                          color: Colors.black12,
                          child: widget.closedListElementCreator(uiElement)));
                }
                return null;
              },
              itemCount: _isCollapsed
                  ? 1
                  : (_uiElements.isEmpty ? 2 : _uiElements.length + 1),
            );
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntity<T>()) {
      var updatedTripEntityState = currentState as UpdatedTripEntity;
      if (updatedTripEntityState.dataState == DataState.Delete ||
          updatedTripEntityState.dataState == DataState.Create ||
          updatedTripEntityState.dataState == DataState.NewUiEntry) {
        return true;
      }
    } else if (widget.additionalListBuildWhenCondition != null) {
      widget.additionalListBuildWhenCondition!(previousState, currentState);
    }
    return false;
  }

  Future<void> _uiElementsSorterWrapper(
      FutureOr<void> Function(List<UiElement<T>>) func,
      List<UiElement<T>> uiElements) async {
    return Future.value(func(uiElements));
  }

  Container _createEmptyMessagePane(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.transparent,
      child: Center(
        child: PlatformTextElements.createSubHeader(
            context: context, text: widget.emptyListMessage),
      ),
    );
  }

  Widget _createHeaderTile(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return ListTile(
          leading: AnimatedIcon(
              icon: _isCollapsed
                  ? AnimatedIcons.view_list
                  : AnimatedIcons.menu_arrow,
              progress: _animationController),
          title: Text(widget.headerTileLabel),
          onTap: () {
            _isCollapsed = !_isCollapsed;
            setState(() {});
          },
          trailing: widget.headerTileButton != null
              ? widget.headerTileButton!
              : _buildCreateTripEntityButton(context),
        );
      },
      listener: (BuildContext context, TripManagementState state) {
        if (state.isTripEntity<T>() &&
            (state as UpdatedTripEntity).dataState == DataState.NewUiEntry) {
          _isCollapsed = false;
          widget.headerTileButtonCallback?.call();
          setState(() {});
        }
      },
      buildWhen: (previousState, currentState) {
        return currentState.isTripEntity<T>();
      },
    );
  }

  Widget _buildCreateTripEntityButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var shouldEnableButton = !_uiElements
            .any((element) => element.dataState == DataState.NewUiEntry);
        if (state.isTripEntity<T>()) {
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
          label: Text(widget.headerTileLabel),
          icon: Icon(Icons.add_rounded),
        );
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntity<T>()) {
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
    var activeTrip = context.getActiveTrip();

    _uiElements.removeWhere((x) => x.dataState != DataState.NewUiEntry);

    if (state.isTripEntity<T>()) {
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
