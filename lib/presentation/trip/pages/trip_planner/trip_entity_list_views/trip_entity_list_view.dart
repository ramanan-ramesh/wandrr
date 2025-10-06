import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
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
  final Widget? headerTileButton;
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
  final String section;

  const TripEntityListView(
      {required this.openedListElementCreator,
      required this.closedListElementCreator,
      required this.emptyListMessage,
      required this.headerTileLabel,
      required this.uiElementsSorter,
      required this.uiElementsCreator,
      required this.section,
      super.key,
      this.onUiElementPressed,
      this.additionalListBuildWhenCondition,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.canDelete,
      this.errorMessageCreator,
      this.additionalListItemBuildWhenCondition})
      : headerTileButton = null;

  const TripEntityListView.customHeaderTileButton(
      {required this.openedListElementCreator,
      required this.closedListElementCreator,
      required this.emptyListMessage,
      required this.headerTileLabel,
      required this.uiElementsSorter,
      required Widget this.headerTileButton,
      required this.section,
      required this.uiElementsCreator,
      super.key,
      this.additionalListBuildWhenCondition,
      this.onUiElementPressed,
      this.onUpdatePressed,
      this.onDeletePressed,
      this.canDelete,
      this.errorMessageCreator,
      this.additionalListItemBuildWhenCondition});

  @override
  State<TripEntityListView<T>> createState() => _TripEntityListViewState<T>();
}

class _TripEntityListViewState<T extends TripEntity>
    extends State<TripEntityListView<T>> {
  var _uiElements = <UiElement<T>>[];
  final _listVisibilityNotifier = ValueNotifier<bool>(false);
  final _headerContext = GlobalKey();

  @override
  void dispose() {
    _listVisibilityNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildList,
      builder: (BuildContext context, TripManagementState state) {
        _updateListElementsOnBuild(context, state);
        return SliverMainAxisGroup(
          slivers: [
            SliverAppBar(
              key: _headerContext,
              flexibleSpace: _createHeaderTile(context),
              pinned: true,
            ),
            ValueListenableBuilder(
              valueListenable: _listVisibilityNotifier,
              builder: (context, value, child) {
                return _createListViewingArea(context);
              },
            ),
          ],
        );
      },
      listener: (BuildContext context, TripManagementState state) {
        if (state.isTripEntityUpdated<T>() &&
            (state as UpdatedTripEntity).dataState == DataState.newUiEntry) {
          _listVisibilityNotifier.value = true;
        } else if (state is ProcessSectionNavigation) {
          if (state.section.toLowerCase() == widget.section.toLowerCase()) {
            if (state.dateTime == null) {
              unawaited(context.tripNavigator.jumpToList(context));
            } else {
              _listVisibilityNotifier.value = true;
            }
          }
        }
      },
    );
  }

  Widget _createListViewingArea(BuildContext context) {
    if (_listVisibilityNotifier.value) {
      if (_uiElements.isEmpty) {
        return SliverToBoxAdapter(child: _createEmptyMessagePane(context));
      } else {
        return FutureBuilder<Iterable<UiElement<T>>>(
          future:
              _uiElementsSorterWrapper(widget.uiElementsSorter, _uiElements),
          builder: (BuildContext context,
              AsyncSnapshot<Iterable<UiElement<T>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              _uiElements = snapshot.data!.toList();
              return _createSliverList();
            }
            return SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()));
          },
        );
      }
    } else {
      return SliverToBoxAdapter(child: const SizedBox.shrink());
    }
  }

  Widget _createSliverList() {
    return SliverList.builder(
      itemCount: _uiElements.length,
      itemBuilder: (BuildContext context, int index) {
        var uiElement = _uiElements.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 4.0),
          child: Material(
            color: context.isLightTheme
                ? Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.96)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.98),
            elevation: 5,
            borderRadius: BorderRadius.circular(23),
            shadowColor: AppColors.neutral900.withValues(alpha: 0.10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  width: 2.2,
                ),
              ),
              child: TripEntityListElement<T>(
                uiElement: uiElement,
                onPressed: widget.onUiElementPressed,
                canDelete: widget.canDelete,
                additionalListItemBuildWhenCondition:
                    widget.additionalListItemBuildWhenCondition,
                onUpdatePressed: widget.onUpdatePressed,
                onDeletePressed: widget.onDeletePressed,
                openedListElementCreator: widget.openedListElementCreator,
                closedElementCreator: widget.closedListElementCreator,
                errorMessageCreator: widget.errorMessageCreator,
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleListVisibility() {
    _listVisibilityNotifier.value = !_listVisibilityNotifier.value;
  }

  void _toggleListVisibilityOnOpenClose(BuildContext context) {
    if (_listVisibilityNotifier.value) {
      if (context.tripNavigator.isSliverAppBarPinned(_headerContext)) {
        unawaited(
            context.tripNavigator.jumpToList(context, alignment: 0.0).then((_) {
          _toggleListVisibility();
        }));
        return;
      }
    }

    _toggleListVisibility();
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

  Widget _createEmptyMessagePane(BuildContext context) {
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
    return Material(
      child: ListTile(
        //TODO: Fix this for tamil, the trailing widget consumes entire space in case of expenses
        leading: ValueListenableBuilder(
            valueListenable: _listVisibilityNotifier,
            builder: (context, value, child) {
              return Icon(
                value ? Icons.list_rounded : Icons.menu_open_rounded,
              );
            }),
        title: Text(
          widget.headerTileLabel,
        ),
        onTap: () => _toggleListVisibilityOnOpenClose(context),
        selected: true,
        trailing: Container(
          constraints: const BoxConstraints(
            maxWidth: 200,
          ),
          child: FittedBox(
            child: widget.headerTileButton != null
                ? widget.headerTileButton!
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: _buildCreateTripEntityButton(context),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTripEntityButton(BuildContext context) {
    var shouldEnableButton = !_uiElements
        .any((element) => element.dataState == DataState.newUiEntry);
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
  }

  void _updateListElementsOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = context.activeTrip;

    _uiElements.removeWhere((x) => x.dataState != DataState.newUiEntry);

    if (state.isTripEntityUpdated<T>()) {
      var updatedTripEntityState = state as UpdatedTripEntity;
      var updatedTripEntityDataState = updatedTripEntityState.dataState;
      if (updatedTripEntityState
          .tripEntityModificationData.isFromExplicitAction) {
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
