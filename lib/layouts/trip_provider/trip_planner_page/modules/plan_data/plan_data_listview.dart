import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/plan_data/opened_plan_data.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/trip_management.dart';

class PlanDataListView extends StatefulWidget {
  const PlanDataListView({super.key});

  @override
  State<PlanDataListView> createState() => _PlanDataListViewState();
}

class _PlanDataListViewState extends State<PlanDataListView> {
  List<PlanDataUpdator> _planDataUpators = [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        _updatePlanDataListOnBuild(context, state);
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == _planDataUpators.length) {
              return _buildPlanDataListCreator(context);
            }
            return _PlanDataListItemViewer(
                initialPlanDataUpdator: _planDataUpators.elementAt(index));
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_planDataUpators.isNotEmpty) {
              return Divider();
            } else {
              return SizedBox.shrink();
            }
          },
          itemCount: _planDataUpators.length + 1,
        );
      },
      buildWhen: _shouldBuildPlanDataList,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildPlanDataListCreator(BuildContext context) {
    return PlatformButtonElements.createExtendedFAB(
        iconData: Icons.add_rounded,
        text: AppLocalizations.of(context)!.newList,
        onPressed: () {
          var tripManagementBloc = BlocProvider.of<TripManagementBloc>(context);
          var tripId = RepositoryProvider.of<TripManagement>(context)
              .activeTrip!
              .tripMetaData
              .id;
          tripManagementBloc.add(UpdatePlanData.create(
              planDataUpdator:
                  PlanDataUpdator.createNewUIEntry(tripId: tripId)));
        },
        context: context);
  }

  bool _shouldBuildPlanDataList(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is LoadedTrip) {
      return true;
    }
    if (currentState is PlanDataUpdated) {
      if (currentState.operation == DataState.Deleted) {
        return true;
      } else if (currentState.operation == DataState.Created) {
        if (currentState.planDataUpdator.dataState ==
            DataState.CreateNewUIEntry) {
          return !_planDataUpators.any(
              (element) => element.dataState == DataState.CreateNewUIEntry);
        }
      }
    }
    return false;
  }

  void _updatePlanDataListOnBuild(
      BuildContext context, TripManagementState state) {
    var activeTrip = RepositoryProvider.of<TripManagement>(context).activeTrip!;

    _planDataUpators.removeWhere(
        (element) => element.dataState != DataState.CreateNewUIEntry);

    _planDataUpators = activeTrip.planDataList
        .map((element) => PlanDataUpdator.fromPlanData(
            planDataFacade: element, tripId: activeTrip.tripMetaData.id))
        .toList();

    if (state is PlanDataUpdated) {
      if (state.operation == DataState.Created) {
        if (state.planDataUpdator.dataState == DataState.CreateNewUIEntry &&
            !_planDataUpators.any(
                (element) => element.dataState == DataState.CreateNewUIEntry)) {
          _planDataUpators.add(state.planDataUpdator);
        } else if (state.planDataUpdator.dataState == DataState.Created) {
          _planDataUpators.removeWhere(
              (element) => element.dataState == DataState.CreateNewUIEntry);
        }
      }
    }
  }
}

class _PlanDataListItemViewer extends StatefulWidget {
  PlanDataUpdator initialPlanDataUpdator;

  _PlanDataListItemViewer({super.key, required this.initialPlanDataUpdator});

  @override
  State<_PlanDataListItemViewer> createState() =>
      _PlanDataListItemViewerState();
}

class _PlanDataListItemViewerState extends State<_PlanDataListItemViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _titleEditingController;
  final ValueNotifier<bool> _canUpdatePlanDataNotifier = ValueNotifier(false);
  bool _isCollapsed = true;
  late PlanDataUpdator _planDataUpdator;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _planDataUpdator = widget.initialPlanDataUpdator.clone();
    _titleEditingController =
        TextEditingController(text: _planDataUpdator.title);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        return Material(
          child: Column(
            children: [
              ListTile(
                leading: AnimatedIcon(
                    icon: _isCollapsed
                        ? AnimatedIcons.view_list
                        : AnimatedIcons.menu_arrow,
                    progress: _animationController),
                title: PlatformTextElements.createTextField(
                  context: context,
                  controller: _titleEditingController,
                  hintText: 'Enter a title',
                  onTextChanged: (newTitle) {
                    _planDataUpdator.title = newTitle;
                    _tryUpdatePlanData(
                        _planDataUpdator,
                        (widget.initialPlanDataUpdator.title ?? '') ==
                            newTitle);
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.0),
                      child: _buildUpdatePlanDataListButton(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.0),
                      child: PlatformSubmitterFAB(
                        icon: Icons.delete_rounded,
                        context: context,
                        backgroundColor: Colors.black,
                        callback: () {
                          var tripManagementBloc =
                              BlocProvider.of<TripManagementBloc>(context);
                          tripManagementBloc.add(UpdatePlanData.delete(
                              planDataUpdator: _planDataUpdator));
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
              ),
              if (!_isCollapsed)
                OpenedPlanDataListItem(
                  initialPlanDataUpdator: _planDataUpdator,
                  planDataUpdated: _tryUpdatePlanData,
                  isPlanDataList: true,
                )
            ],
          ),
        );
      },
      buildWhen: _shouldBuildPlanDataListItem,
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  void _tryUpdatePlanData(PlanDataUpdator newPlanData, bool canUpdatePlanData) {
    _planDataUpdator = newPlanData;
    _canUpdatePlanDataNotifier.value = canUpdatePlanData;
  }

  Widget _buildUpdatePlanDataListButton() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is LoadedTrip) {
          return true;
        }
        if (currentState is PlanDataUpdated) {
          return true;
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        _canUpdatePlanDataNotifier.value = false;
        return ValueListenableBuilder(
            valueListenable: _canUpdatePlanDataNotifier,
            builder: (context, canUpdatePlanData, oldWidget) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 500),
                child: Visibility(
                  visible: canUpdatePlanData,
                  child: PlatformSubmitterFAB(
                      icon: Icons.check_rounded,
                      context: context,
                      backgroundColor:
                          canUpdatePlanData ? Colors.black : Colors.white12,
                      callback: canUpdatePlanData
                          ? () {
                              var tripManagementBloc =
                                  BlocProvider.of<TripManagementBloc>(context);
                              if (_planDataUpdator.dataState ==
                                  DataState.CreateNewUIEntry) {
                                tripManagementBloc.add(UpdatePlanData.create(
                                    planDataUpdator: _planDataUpdator));
                              } else {
                                tripManagementBloc.add(UpdatePlanData.update(
                                    planDataUpdator: _planDataUpdator));
                              }
                            }
                          : null),
                ),
              );
            });
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildPlanDataListItem(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is LoadedTrip) {
      return true;
    }
    if (currentState is PlanDataUpdated) {
      if (currentState.operation == DataState.Created) {
        if (widget.initialPlanDataUpdator.dataState ==
            DataState.CreateNewUIEntry) {
          widget.initialPlanDataUpdator = currentState.planDataUpdator;
          return true;
        }
      }
    }
    return false;
  }
}
