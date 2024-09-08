import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/data_states.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/plan_data.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/plan_data/opened_plan_data/opened_plan_data.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';

class PlanDataListView extends StatefulWidget {
  const PlanDataListView({super.key});

  @override
  State<PlanDataListView> createState() => _PlanDataListViewState();
}

class _PlanDataListViewState extends State<PlanDataListView> {
  List<UiElement<PlanDataModelFacade>> _planDataUiElements = [];

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
          var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
          tripManagementBloc
              .add(UpdateTripEntity<PlanDataModelFacade>.createNewUiEntry());
        },
        label: Text(AppLocalizations.of(context)!.newList),
        icon: Icon(Icons.add_rounded));
  }

  bool _shouldBuildPlanDataList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntity<PlanDataModelFacade>()) {
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

    if (state.isTripEntity<PlanDataModelFacade>()) {
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
        UiElement<PlanDataModelFacade>(element: e, dataState: DataState.None)));
  }
}

class _PlanDataListItemViewer extends StatefulWidget {
  UiElement<PlanDataModelFacade> initialPlanDataUiElement;

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
  late UiElement<PlanDataModelFacade> _planDataUiElement;

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
                OpenedPlanDataListItem(
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
        hintText: AppLocalizations.of(context)!.addATitle,
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
                  var tripManagementBloc =
                      BlocProvider.of<TripManagementBloc>(context);
                  if (_planDataUiElement.dataState == DataState.NewUiEntry) {
                    tripManagementBloc.add(
                        UpdateTripEntity<PlanDataModelFacade>.create(
                            tripEntity: _planDataUiElement.element));
                  } else {
                    tripManagementBloc.add(
                        UpdateTripEntity<PlanDataModelFacade>.update(
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
                var tripManagementBloc =
                    BlocProvider.of<TripManagementBloc>(context);
                tripManagementBloc.add(
                    UpdateTripEntity<PlanDataModelFacade>.delete(
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

  void _tryUpdatePlanData(PlanDataModelFacade newPlanData) {
    var title = _planDataUiElement.element.title;
    _planDataUiElement.element = newPlanData;
    _planDataUiElement.element.title = title;
    var isValid = _planDataUiElement.isValid(
        widget.initialPlanDataUiElement.element, true);
    _canUpdatePlanDataNotifier.value = isValid;
  }

  bool _shouldBuildPlanDataListItem(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState.isTripEntity<PlanDataModelFacade>()) {
      var planDataUpdatedState =
          currentState as UpdatedTripEntity<PlanDataModelFacade>;
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
