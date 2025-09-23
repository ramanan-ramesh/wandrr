import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/plan_data/plan_data_list_viewer.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class PlanDataListView extends StatelessWidget {
  final List<UiElement<PlanDataFacade>> _planDataUiElements = [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        _updatePlanDataListOnBuild(context, state);
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == _planDataUiElements.length) {
              return _buildPlanDataCreatorButton(context);
            }
            return PlanDataListItemViewer(
                initialPlanDataUiElement: _planDataUiElements.elementAt(index));
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_planDataUiElements.isNotEmpty) {
              return const Divider();
            } else {
              return const SizedBox.shrink();
            }
          },
          itemCount: _planDataUiElements.length + 1,
        );
      },
      buildWhen: _shouldBuildPlanDataList,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildPlanDataCreatorButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        context.addTripManagementEvent(
            UpdateTripEntity<PlanDataFacade>.createNewUiEntry());
      },
      label: Text(context.localizations.newPlanData),
      icon: const Icon(Icons.add_rounded),
    );
  }

  bool _shouldBuildPlanDataList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntityUpdated<PlanDataFacade>()) {
      var planDataUpdatedState = currentState as UpdatedTripEntity;
      if (planDataUpdatedState.dataState == DataState.delete ||
          planDataUpdatedState.dataState == DataState.create ||
          planDataUpdatedState.dataState == DataState.newUiEntry) {
        return true;
      }
    }
    return false;
  }

  void _updatePlanDataListOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = context.activeTrip;

    _planDataUiElements.removeWhere((x) => x.dataState != DataState.newUiEntry);

    if (state.isTripEntityUpdated<PlanDataFacade>()) {
      var updatedTripEntityState = state as UpdatedTripEntity;
      var updatedTripEntityDataState = updatedTripEntityState.dataState;
      if (updatedTripEntityState
          .tripEntityModificationData.isFromExplicitAction) {
        switch (updatedTripEntityDataState) {
          case DataState.create:
            {
              _planDataUiElements.removeWhere(
                  (element) => element.dataState == DataState.newUiEntry);
              break;
            }
          case DataState.delete:
            {
              if (updatedTripEntityState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
                _planDataUiElements.removeWhere(
                    (element) => element.dataState == DataState.newUiEntry);
              }
              break;
            }
          case DataState.newUiEntry:
            {
              if (!_planDataUiElements.any(
                  (element) => element.dataState == DataState.newUiEntry)) {
                _planDataUiElements.add(UiElement(
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
    _planDataUiElements.addAll(activeTrip.planDataCollection.collectionItems
        .map((e) =>
            UiElement<PlanDataFacade>(element: e, dataState: DataState.none)));
  }
}
