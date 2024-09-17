import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/bloc.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/events.dart';
import 'package:wandrr/app_presentation/blocs/trip_management/states.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/editable_list_elements/plan_data/plan_data.dart';

class PlanDataListView extends StatefulWidget {
  const PlanDataListView({super.key});

  @override
  State<PlanDataListView> createState() => _PlanDataListViewState();
}

class _PlanDataListViewState extends State<PlanDataListView> {
  final List<UiElement<PlanDataFacade>> _planDataUiElements = [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        _updatePlanDataListOnBuild(context, state);
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == _planDataUiElements.length) {
              return _buildCreatePlanDataListButton(context);
            }
            return _PlanDataListItemViewer(
                initialPlanDataUiElement: _planDataUiElements.elementAt(index));
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_planDataUiElements.isNotEmpty) {
              return Divider();
            } else {
              return SizedBox.shrink();
            }
          },
          itemCount: _planDataUiElements.length + 1,
        );
      },
      buildWhen: _shouldBuildPlanDataList,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildCreatePlanDataListButton(BuildContext context) {
    return FloatingActionButton.extended(
        onPressed: () {
          context.addTripManagementEvent(
              UpdateTripEntity<PlanDataFacade>.createNewUiEntry());
        },
        label: Text(context.withLocale().newList),
        icon: Icon(Icons.add_rounded));
  }

  bool _shouldBuildPlanDataList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntity<PlanDataFacade>()) {
      var planDataUpdatedState = currentState as UpdatedTripEntity;
      if (planDataUpdatedState.dataState == DataState.Delete ||
          planDataUpdatedState.dataState == DataState.Create ||
          planDataUpdatedState.dataState == DataState.NewUiEntry) {
        return true;
      }
    }
    return false;
  }

  void _updatePlanDataListOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = context.getActiveTrip();

    _planDataUiElements.removeWhere((x) => x.dataState != DataState.NewUiEntry);

    if (state.isTripEntity<PlanDataFacade>()) {
      var updatedTripEntityState = state as UpdatedTripEntity;
      var updatedTripEntityDataState = updatedTripEntityState.dataState;
      if (updatedTripEntityState.tripEntityModificationData.isFromEvent) {
        switch (updatedTripEntityDataState) {
          case DataState.Create:
            {
              _planDataUiElements.removeWhere(
                  (element) => element.dataState == DataState.NewUiEntry);
              break;
            }
          case DataState.Delete:
            {
              if (updatedTripEntityState
                      .tripEntityModificationData.modifiedCollectionItem.id ==
                  null) {
                _planDataUiElements.removeWhere(
                    (element) => element.dataState == DataState.NewUiEntry);
              }
              break;
            }
          case DataState.NewUiEntry:
            {
              if (!_planDataUiElements.any(
                  (element) => element.dataState == DataState.NewUiEntry)) {
                _planDataUiElements.add(UiElement(
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
    _planDataUiElements.addAll(activeTrip.planDataList.map((e) =>
        UiElement<PlanDataFacade>(element: e, dataState: DataState.None)));
  }
}

class _PlanDataListItemViewer extends StatefulWidget {
  UiElement<PlanDataFacade> initialPlanDataUiElement;

  _PlanDataListItemViewer({super.key, required this.initialPlanDataUiElement});

  @override
  State<_PlanDataListItemViewer> createState() =>
      _PlanDataListItemViewerState();
}

class _PlanDataListItemViewerState extends State<_PlanDataListItemViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _titleEditingController;
  final ValueNotifier<bool> _canUpdatePlanDataNotifier = ValueNotifier(false);
  bool _isCollapsed = false;
  late UiElement<PlanDataFacade> _planDataUiElement;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _planDataUiElement = widget.initialPlanDataUiElement.clone();
    _planDataUiElement.element =
        widget.initialPlanDataUiElement.element.clone();
    _titleEditingController =
        TextEditingController(text: _planDataUiElement.element.title);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return Material(
          child: Column(
            children: [
              _buildPlanDataHeaderTile(),
              if (!_isCollapsed)
                PlanDataListItem(
                    initialPlanDataUiElement: _planDataUiElement,
                    planDataUpdated: _tryUpdatePlanData)
            ],
          ),
        );
      },
      buildWhen: _shouldBuildPlanDataListItem,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  ListTile _buildPlanDataHeaderTile() {
    return ListTile(
      leading: AnimatedIcon(
          icon:
              _isCollapsed ? AnimatedIcons.view_list : AnimatedIcons.menu_arrow,
          progress: _animationController),
      title: PlatformTextElements.createTextField(
        context: context,
        controller: _titleEditingController,
        hintText: context.withLocale().addATitle,
        onTextChanged: (newTitle) {
          _planDataUiElement.element.title = newTitle;
          _tryUpdatePlanData(_planDataUiElement.element);
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.0),
            child: PlatformSubmitterFAB.conditionallyEnabled(
                icon: Icons.check_rounded,
                context: context,
                callback: () {
                  if (_planDataUiElement.dataState == DataState.NewUiEntry) {
                    context.addTripManagementEvent(
                        UpdateTripEntity<PlanDataFacade>.create(
                            tripEntity: _planDataUiElement.element));
                  } else {
                    context.addTripManagementEvent(
                        UpdateTripEntity<PlanDataFacade>.update(
                            tripEntity: _planDataUiElement.element));
                  }
                },
                valueNotifier: _canUpdatePlanDataNotifier,
                isConditionallyVisible: true),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.0),
            child: PlatformSubmitterFAB(
              icon: Icons.delete_rounded,
              context: context,
              isEnabledInitially: true,
              callback: () {
                context.addTripManagementEvent(
                    UpdateTripEntity<PlanDataFacade>.delete(
                        tripEntity: _planDataUiElement.element));
              },
            ),
          )
        ],
      ),
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
    );
  }

  void _tryUpdatePlanData(PlanDataFacade newPlanData) {
    var title = _planDataUiElement.element.title;
    _planDataUiElement.element = newPlanData;
    _planDataUiElement.element.title = title;
    var isValid = _planDataUiElement.isValid(
        widget.initialPlanDataUiElement.element, true);
    _canUpdatePlanDataNotifier.value = isValid;
  }

  bool _shouldBuildPlanDataListItem(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntity<PlanDataFacade>()) {
      var planDataUpdatedState =
          currentState as UpdatedTripEntity<PlanDataFacade>;
      if (planDataUpdatedState.dataState == DataState.Update &&
          _planDataUiElement.element.id ==
              planDataUpdatedState
                  .tripEntityModificationData.modifiedCollectionItem.id) {
        _planDataUiElement.element = planDataUpdatedState
            .tripEntityModificationData.modifiedCollectionItem;
        _planDataUiElement.dataState = DataState.None;
        return true;
      }
    }
    return false;
  }
}
