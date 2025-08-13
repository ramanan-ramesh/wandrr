import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
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
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/constants.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/jump_to_date.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/navigation/trip_navigator.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'trip_entity_list_element.dart';

class TripEntityListView<T extends TripEntity> extends StatefulWidget {
  final Widget Function(UiElement<T>, ValueNotifier<bool>)
      openedListElementCreator;
  final void Function(UiElement<T>)? onUpdatePressed;
  final void Function(UiElement<T>)? onDeletePressed;
  final Widget Function(UiElement<T> uiElement) closedListElementCreator;
  final String emptyListMessage;
  Widget? headerTileButton;
  final BlocBuilderCondition<TripManagementState>?
      additionalListBuildWhenCondition;
  final bool Function(
      TripManagementState previousState,
      TripManagementState currentState,
      UiElement<T> uiElement)? additionalListItemBuildWhenCondition;
  final String headerTileLabel;
  final void Function(BuildContext context, UiElement<T>)? onUiElementPressed;
  final FutureOr<Iterable<UiElement<T>>> Function(List<UiElement<T>> uiElements)
      uiElementsSorter;
  final List<UiElement<T>> Function(TripDataFacade tripDataModelFacade)
      uiElementsCreator;
  final bool Function(UiElement<T>)? canDelete;
  final String? Function(UiElement<T>)? errorMessageCreator;
  final bool Function(T, DateTime)? canConsiderUiElementForNavigation;
  final String section;

  TripEntityListView(
      {super.key,
      required this.openedListElementCreator,
      required this.closedListElementCreator,
      required this.emptyListMessage,
      required this.headerTileLabel,
      required this.uiElementsSorter,
      required this.uiElementsCreator,
      required this.section,
      this.canConsiderUiElementForNavigation,
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
      required this.section,
      this.canConsiderUiElementForNavigation,
      this.additionalListBuildWhenCondition,
      this.onUiElementPressed,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.canDelete,
      required this.uiElementsCreator,
      this.errorMessageCreator,
      this.additionalListItemBuildWhenCondition});

  @override
  State<TripEntityListView> createState() => _TripEntityListViewState<T>();
}

class _TripEntityListViewState<T extends TripEntity>
    extends State<TripEntityListView<T>> {
  var _uiElements = <UiElement<T>>[];
  final ListController _listController = ListController();
  var _isListVisible = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildList,
      builder: (BuildContext context, TripManagementState state) {
        _updateListElementsOnBuild(state);
        return FutureBuilder<Iterable<UiElement<T>>>(
          future:
              _uiElementsSorterWrapper(widget.uiElementsSorter, _uiElements),
          builder: (BuildContext context,
              AsyncSnapshot<Iterable<UiElement<T>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              _uiElements = snapshot.data!.toList();
            }
            return SliverMainAxisGroup(
              slivers: [
                SliverAppBar(
                  flexibleSpace: _createHeaderTile(),
                  pinned: true,
                ),
                _isListVisible
                    ? (_uiElements.isEmpty
                        ? SliverToBoxAdapter(
                            child: _createEmptyMessagePane(),
                          )
                        : _createSliverList())
                    : SliverToBoxAdapter(
                        child: SizedBox.shrink(),
                      ),
              ],
            );
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {
        if (state.isTripEntityUpdated<T>() &&
            (state as UpdatedTripEntity).dataState == DataState.newUiEntry) {
          _setListVisibility(true);
        } else if (state is ProcessSectionNavigation) {
          if (state.section.toLowerCase() == widget.section.toLowerCase()) {
            if (state.dateTime == null) {
              RepositoryProvider.of<TripNavigator>(context).jumpToList(context);
            } else {
              _setListVisibility(true);
              Future.delayed(
                  NavAnimationDurations.delayedNavigateToDateInSection, () {
                if (context.mounted) {
                  _jumpToDate(state);
                }
              });
            }
          }
        }
      },
    );
  }

  Widget _createSliverList() {
    return SuperSliverList.builder(
      itemCount: _uiElements.length,
      listController: _listController,
      itemBuilder: (BuildContext context, int index) {
        var uiElement = _uiElements.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 3.0),
          child: TripEntityListElement<T>(
            uiElement: uiElement,
            onPressed: widget.onUiElementPressed,
            canDelete: widget.canDelete,
            additionalListItemBuildWhenCondition:
                widget.additionalListItemBuildWhenCondition,
            onUpdatePressed: widget.onUpdatePressed,
            onDeletePressed: widget.onDeletePressed,
            openedListElementCreator: widget.openedListElementCreator,
            closedElementCreator: (uiElement) =>
                widget.closedListElementCreator(uiElement),
            errorMessageCreator: widget.errorMessageCreator,
          ),
        );
      },
    );
  }

  void _toggleListVisibility() {
    _setListVisibility(!_isListVisible);
  }

  void _setListVisibility(bool isVisible) {
    if (_isListVisible == isVisible) {
      return;
    }

    setState(() {
      _isListVisible = isVisible;
    });
  }

  void _toggleListVisibilityOnOpenClose() {
    if (_isListVisible) {
      RepositoryProvider.of<TripNavigator>(context)
          .jumpToList(context, alignment: 0.0);
    }

    _toggleListVisibility();
  }

  void _jumpToDate(ProcessSectionNavigation state) {
    for (var index = 0; index < _uiElements.length; index++) {
      var uiElement = _uiElements[index];
      if (widget.canConsiderUiElementForNavigation != null &&
          widget.canConsiderUiElementForNavigation!(
              uiElement.element, state.dateTime!)) {
        RepositoryProvider.of<TripNavigator>(context)
            .animateToListItem(context, _listController, index);
        break;
      }
    }
  }

  Widget _createJumpToDateNavigator() {
    return JumpToDateNavigator(
      section: widget.section,
      tripEntitiesGetter: () => _uiElements.map((e) => e.element),
    );
  }

  bool _shouldBuildList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<T>()) {
      var updatedTripEntityState = currentState as UpdatedTripEntity;
      if (updatedTripEntityState.dataState == DataState.delete ||
          updatedTripEntityState.dataState == DataState.create ||
          updatedTripEntityState.dataState == DataState.newUiEntry) {
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

  Widget _createEmptyMessagePane() {
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

  Widget _createHeaderTile() {
    return ListTile(
      //TODO: Fix this for tamil, the trailing widget consumes entire space in case of expenses
      leading:
          Icon(_isListVisible ? Icons.list_rounded : Icons.menu_open_rounded),
      title: Text(
        widget.headerTileLabel,
      ),
      onTap: _toggleListVisibilityOnOpenClose,
      trailing: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
        ),
        child: FittedBox(
          child: widget.headerTileButton != null
              ? widget.headerTileButton!
              : Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: _createJumpToDateNavigator(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: _buildCreateTripEntityButton(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCreateTripEntityButton() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        var shouldEnableButton = !_uiElements
            .any((element) => element.dataState == DataState.newUiEntry);
        if (state.isTripEntityUpdated<T>()) {
          var updatedTripEntityState = state as UpdatedTripEntity;
          if (updatedTripEntityState.dataState == DataState.newUiEntry) {
            shouldEnableButton = false;
          } else if (updatedTripEntityState.dataState == DataState.delete &&
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
          icon: const Icon(Icons.add_rounded),
          elevation: 0,
        );
      },
      buildWhen: (previousState, currentState) {
        if (currentState.isTripEntityUpdated<T>()) {
          var updatedTripEntityState = currentState as UpdatedTripEntity;
          return updatedTripEntityState.dataState == DataState.create ||
              updatedTripEntityState.dataState == DataState.newUiEntry ||
              updatedTripEntityState.dataState == DataState.delete;
        }
        return false;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  void _updateListElementsOnBuild(TripManagementState state) {
    var activeTrip = context.activeTrip;

    _uiElements.removeWhere((x) => x.dataState != DataState.newUiEntry);

    if (state.isTripEntityUpdated<T>()) {
      var updatedTripEntityState = state as UpdatedTripEntity;
      var updatedTripEntityDataState = updatedTripEntityState.dataState;
      if (updatedTripEntityState.tripEntityModificationData.isFromEvent) {
        switch (updatedTripEntityDataState) {
          case DataState.create:
            {
              _uiElements.removeWhere(
                  (element) => element.dataState == DataState.newUiEntry);
              break;
            }
          case DataState.delete:
            {
              if (updatedTripEntityState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
                _uiElements.removeWhere(
                    (element) => element.dataState == DataState.newUiEntry);
              }
              break;
            }
          case DataState.newUiEntry:
            {
              if (!_uiElements.any(
                  (element) => element.dataState == DataState.newUiEntry)) {
                _uiElements.add(UiElement(
                    element: updatedTripEntityState
                        .tripEntityModificationData.modifiedCollectionItem,
                    dataState: DataState.newUiEntry));
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
