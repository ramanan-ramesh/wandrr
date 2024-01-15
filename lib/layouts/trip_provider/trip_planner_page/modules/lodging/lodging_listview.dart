import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';
import 'package:wandrr/repositories/trip_management.dart';

import 'lodging_list_item_components/closed_lodging.dart';
import 'lodging_list_item_components/opened_lodging.dart';

class LodgingListView extends StatefulWidget {
  LodgingListView({super.key});

  @override
  State<LodgingListView> createState() => _LodgingListViewState();
}

class _LodgingListViewState extends State<LodgingListView>
    with SingleTickerProviderStateMixin {
  var _lodgingUpdators = <LodgingUpdator>[];
  bool _isCollapsed = true;
  late var _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildLodgingList,
      builder: (BuildContext context, TripManagementState state) {
        print('LodgingListView builder');
        _updateLodgingsOnBuild(context, state);
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _createHeaderTile(context);
            } else if (index == 1 && _lodgingUpdators.isEmpty) {
              return _createEmptyMessagePane(context);
            } else if (index > 0) {
              return _LodgingListItem(
                lodgingUpdator: _lodgingUpdators.elementAt(index - 1),
              );
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_lodgingUpdators.isNotEmpty) {
              return Divider();
            } else {
              return SizedBox.shrink();
            }
          },
          itemCount: _isCollapsed
              ? 1
              : (_lodgingUpdators.isEmpty ? 2 : _lodgingUpdators.length + 1),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildLodgingList(previousState, currentState) {
    if (currentState is LoadedTrip) {
      return true;
    }
    if (currentState is LodgingUpdated) {
      //TODO: Should handle update done on any property that is affected by SortOption(ex: update done to dateTime field of any expense, must potentially rebuild the list, if selected sort option is DateTime)
      if (currentState.operation == DataState.Deleted) {
        return true;
      } else if (currentState.operation == DataState.Created) {
        var newUIItemIncomingButSuchOneExists = currentState
                    .lodgingUpdator.dataState ==
                DataState.CreateNewUIEntry &&
            _lodgingUpdators.any(
                (element) => element.dataState == DataState.CreateNewUIEntry);
        return !newUIItemIncomingButSuchOneExists;
      }
    }
    return false;
  }

  Container _createEmptyMessagePane(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.transparent,
      child: Center(
        child: PlatformTextElements.createSubHeader(
            context: context,
            text: AppLocalizations.of(context)!.noLodgingCreated),
      ),
    );
  }

  Widget _createHeaderTile(BuildContext context) {
    return ListTile(
      leading: AnimatedIcon(
          icon:
              _isCollapsed ? AnimatedIcons.view_list : AnimatedIcons.menu_arrow,
          progress: _animationController),
      title: Text(AppLocalizations.of(context)!.lodging),
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
      trailing: _buildCreatelodgingButton(context),
    );
  }

  Widget _buildCreatelodgingButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        print('builder of create lodging button called for state - ${state}');
        var shouldEnableButton = true;
        if (state is LodgingUpdated) {
          var stateOperation = state.operation;
          if (stateOperation == DataState.Created) {
            if (state.lodgingUpdator.dataState == DataState.CreateNewUIEntry) {
              shouldEnableButton = false;
            }
          }
        }
        return GestureDetector(
          onTap: () {
            var tripManagementBloc =
                BlocProvider.of<TripManagementBloc>(context);
            var activeTrip =
                RepositoryProvider.of<TripManagement>(context).activeTrip!;
            var appLevelData =
                RepositoryProvider.of<PlatformDataRepository>(context)
                    .appLevelData;
            var lodgingUpdator = LodgingUpdator.createNewUIEntry(
                tripId: activeTrip.tripMetaData.id);
            lodgingUpdator.expenseUpdator = ExpenseUpdator.createNewUIEntry(
                category: ExpenseCategory.Lodging,
                tripId: activeTrip.tripMetaData.id,
                currentUserName: appLevelData.activeUser!.userName,
                tripContributors: activeTrip.tripMetaData.contributors,
                currency: activeTrip.tripMetaData.budget.currency);
            tripManagementBloc
                .add(UpdateLodging.create(lodgingUpdator: lodgingUpdator));
          },
          child: PlatformButtonElements.createExtendedFAB(
              iconData: Icons.add_rounded,
              text: AppLocalizations.of(context)!.addLodging,
              enabled: shouldEnableButton,
              context: context),
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState is LodgingUpdated &&
            currentState.operation == DataState.Created;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  void _updateLodgingsOnBuild(BuildContext context, TripManagementState state) {
    var activeTrip = RepositoryProvider.of<TripManagement>(context).activeTrip!;

    _lodgingUpdators.removeWhere(
        (element) => element.dataState != DataState.CreateNewUIEntry);

    _lodgingUpdators = activeTrip.lodgings
        .map((element) => LodgingUpdator.fromLodging(lodging: element))
        .toList();

    if (state is LodgingUpdated && state.operation == DataState.Created) {
      if (state.lodgingUpdator.dataState == DataState.CreateNewUIEntry &&
          !_lodgingUpdators.any(
              (element) => element.dataState == DataState.CreateNewUIEntry)) {
        _lodgingUpdators.add(state.lodgingUpdator);
      } else if (state.lodgingUpdator.dataState == DataState.Created) {
        _lodgingUpdators.removeWhere((element) =>
            element.dataState == DataState.CreateNewUIEntry ||
            element.dataState == DataState.RequestedCreation);
      }
    } else if (state is LodgingUpdated &&
        state.operation == DataState.Deleted) {
      if (state.lodgingUpdator.dataState == DataState.CreateNewUIEntry) {
        _lodgingUpdators.removeWhere(
            (element) => element.dataState == DataState.CreateNewUIEntry);
      }
    }
    _sortLodgings();
  }

  void _sortLodgings() {
    var lodgingsWithValidDateTime = <LodgingUpdator>[];
    var lodgingsWithInvalidDateTime = <LodgingUpdator>[];
    for (var lodging in _lodgingUpdators) {
      if (lodging.checkinDateTime != null) {
        lodgingsWithValidDateTime.add(lodging);
      } else {
        lodgingsWithInvalidDateTime.add(lodging);
      }
    }
    lodgingsWithValidDateTime
        .sort((a, b) => a.checkinDateTime!.compareTo(b.checkinDateTime!));
    _lodgingUpdators = lodgingsWithValidDateTime
      ..addAll(lodgingsWithInvalidDateTime);
  }
}

class _LodgingListItem extends StatelessWidget {
  LodgingUpdator lodgingUpdator;
  _LodgingListItem({super.key, required this.lodgingUpdator});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildLodgingListItem,
      builder: (BuildContext context, TripManagementState state) {
        var shouldOpenForEditing =
            lodgingUpdator.dataState == DataState.Selected ||
                lodgingUpdator.dataState == DataState.CreateNewUIEntry;
        return Material(
          child: AnimatedSize(
              curve: shouldOpenForEditing ? Curves.easeInOut : Curves.easeOut,
              duration: Duration(milliseconds: 700),
              reverseDuration: Duration(milliseconds: 700),
              child: InkWell(
                onTap: shouldOpenForEditing
                    ? null
                    : () {
                        var currentOperation = lodgingUpdator.dataState;
                        if (currentOperation == DataState.Created ||
                            currentOperation == DataState.Updated ||
                            currentOperation == DataState.None) {
                          var tripManagementBloc =
                              BlocProvider.of<TripManagementBloc>(context);
                          tripManagementBloc.add(UpdateLodging.select(
                              lodgingUpdator: lodgingUpdator));
                        }
                      },
                child: shouldOpenForEditing
                    ? OpenedLodgingListItem(
                        initialLodgingUpdator: lodgingUpdator,
                      )
                    : ClosedLodgingListItem(
                        lodgingUpdator: lodgingUpdator,
                      ),
              )),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildLodgingListItem(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is LodgingUpdated) {
      var operationToPerform = currentState.operation;
      var updatedLodgingId = currentState.lodgingUpdator.id;
      if (operationToPerform == DataState.Selected) {
        if (updatedLodgingId == lodgingUpdator.id) {
          return true;
        } else {
          if (lodgingUpdator.dataState == DataState.Selected) {
            lodgingUpdator.dataState = DataState.None;
            return true;
          }
        }
      } else if (operationToPerform == DataState.Updated &&
          lodgingUpdator.id == currentState.lodgingUpdator.id) {
        lodgingUpdator = currentState.lodgingUpdator;
        return true;
      }
    }
    return false;
  }
}
