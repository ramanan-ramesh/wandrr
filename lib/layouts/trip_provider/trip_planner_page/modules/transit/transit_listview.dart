import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/expense.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';
import 'package:wandrr/repositories/trip_management.dart';

import 'transit_list_item_components/closed_transit.dart';
import 'transit_list_item_components/opened_transit.dart';

class TransitListView extends StatefulWidget {
  TransitListView({super.key});

  @override
  State<TransitListView> createState() => _TransitListViewState();
}

class TransitOptionMetadata {
  final TransitOptions transitOptions;
  final IconData icon;
  final String name;
  TransitOptionMetadata(
      {required this.transitOptions, required this.icon, required this.name});
}

class _TransitListViewState extends State<TransitListView>
    with SingleTickerProviderStateMixin {
  var _transitUpdators = <TransitUpdator>[];
  bool _isCollapsed = true;
  late var _animationController;
  final _transitOptionMetadatas = <TransitOptionMetadata>[];

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
  }

  void _initializeIconsAndTransitOptions(BuildContext context) {
    if (_transitOptionMetadatas.isNotEmpty) {
      return;
    }
    var appLocalizations = AppLocalizations.of(context)!;
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.PublicTransport,
        icon: Icons.emoji_transportation_rounded,
        name: appLocalizations.publicTransit));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.Flight,
        icon: Icons.flight_rounded,
        name: appLocalizations.flight));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.Bus,
        icon: Icons.directions_bus_rounded,
        name: appLocalizations.bus));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.Cruise,
        icon: Icons.kayaking_rounded,
        name: appLocalizations.cruise));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.Ferry,
        icon: Icons.directions_ferry_outlined,
        name: appLocalizations.ferry));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.RentedVehicle,
        icon: Icons.car_rental_rounded,
        name: appLocalizations.carRental));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.Train,
        icon: Icons.train_rounded,
        name: appLocalizations.train));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.Vehicle,
        icon: Icons.bike_scooter_rounded,
        name: appLocalizations.personalVehicle));
    _transitOptionMetadatas.add(TransitOptionMetadata(
        transitOptions: TransitOptions.Walk,
        icon: Icons.directions_walk_rounded,
        name: appLocalizations.walk));
  }

  @override
  Widget build(BuildContext context) {
    _initializeIconsAndTransitOptions(context);
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildTransitList,
      builder: (BuildContext context, TripManagementState state) {
        print('TransitListView builder');
        _updateTransitsOnBuild(context, state);
        return SliverList.separated(
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _createHeaderTile(context);
            } else if (index == 1 && _transitUpdators.isEmpty) {
              return _createEmptyMessagePane(context);
            } else if (index > 0) {
              return _TransitListItem(
                transitUpdator: _transitUpdators.elementAt(index - 1),
                transitOptionMetadatas: _transitOptionMetadatas,
              );
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_transitUpdators.isNotEmpty) {
              return Divider();
            } else {
              return SizedBox.shrink();
            }
          },
          itemCount: _isCollapsed
              ? 1
              : (_transitUpdators.isEmpty ? 2 : _transitUpdators.length + 1),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildTransitList(previousState, currentState) {
    if (currentState is LoadedTrip) {
      return true;
    }
    if (currentState is TransitUpdated) {
      //TODO: Should handle update done on any property that is affected by SortOption(ex: update done to dateTime field of any expense, must potentially rebuild the list, if selected sort option is DateTime)
      if (currentState.operation == DataState.Deleted) {
        return true;
      } else if (currentState.operation == DataState.Created) {
        var newUIItemIncomingButSuchOneExists = currentState
                    .transitUpdator.dataState ==
                DataState.CreateNewUIEntry &&
            _transitUpdators.any(
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
            text: AppLocalizations.of(context)!.noTransitsCreated),
      ),
    );
  }

  Widget _createHeaderTile(BuildContext context) {
    return ListTile(
      leading: AnimatedIcon(
          icon:
              _isCollapsed ? AnimatedIcons.view_list : AnimatedIcons.menu_arrow,
          progress: _animationController),
      title: Text(AppLocalizations.of(context)!.transit),
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
      trailing: _buildCreateTransitButton(context),
    );
  }

  Widget _buildCreateTransitButton(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      builder: (BuildContext context, TripManagementState state) {
        print('builder of create transit button called for state - ${state}');
        var shouldEnableButton = true;
        if (state is TransitUpdated) {
          var stateOperation = state.operation;
          if (stateOperation == DataState.Created) {
            if (state.transitUpdator.dataState == DataState.CreateNewUIEntry) {
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
            var transitUpdator = TransitUpdator.createNewUIEntry(
                tripId: activeTrip.tripMetaData.id);
            transitUpdator.expenseUpdator = ExpenseUpdator.createNewUIEntry(
                category: ExpenseCategory.PublicTransit,
                tripId: activeTrip.tripMetaData.id,
                currentUserName: appLevelData.activeUser!.userName,
                tripContributors: activeTrip.tripMetaData.contributors,
                currency: activeTrip.tripMetaData.budget.currency);
            tripManagementBloc
                .add(UpdateTransit.create(transitUpdator: transitUpdator));
          },
          child: PlatformButtonElements.createExtendedFAB(
              iconData: Icons.add_rounded,
              text: AppLocalizations.of(context)!.add_transit,
              enabled: shouldEnableButton,
              context: context),
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState is TransitUpdated &&
            currentState.operation == DataState.Created;
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  void _updateTransitsOnBuild(BuildContext context, TripManagementState state) {
    var activeTrip = RepositoryProvider.of<TripManagement>(context).activeTrip!;

    _transitUpdators.removeWhere(
        (element) => element.dataState != DataState.CreateNewUIEntry);

    _transitUpdators = activeTrip.transits
        .map((element) => TransitUpdator.fromTransit(transit: element))
        .toList();

    if (state is TransitUpdated && state.operation == DataState.Created) {
      if (state.transitUpdator.dataState == DataState.CreateNewUIEntry &&
          !_transitUpdators.any(
              (element) => element.dataState == DataState.CreateNewUIEntry)) {
        _transitUpdators.add(state.transitUpdator);
      } else if (state.transitUpdator.dataState == DataState.Created) {
        _transitUpdators.removeWhere((element) =>
            element.dataState == DataState.CreateNewUIEntry ||
            element.dataState == DataState.RequestedDeletion);
      }
    } else if (state is TransitUpdated &&
        state.operation == DataState.Deleted) {
      if (state.transitUpdator.dataState == DataState.CreateNewUIEntry) {
        _transitUpdators.removeWhere(
            (element) => element.dataState == DataState.CreateNewUIEntry);
      }
    }
    _sortTransits();
  }

  void _sortTransits() {
    var transitsWithValidDateTime = <TransitUpdator>[];
    var transitsWithInvalidDateTime = <TransitUpdator>[];
    for (var transit in _transitUpdators) {
      if (transit.departureDateTime != null &&
          transit.arrivalDateTime != null) {
        transitsWithValidDateTime.add(transit);
      } else {
        transitsWithInvalidDateTime.add(transit);
      }
    }
    transitsWithValidDateTime
        .sort((a, b) => a.departureDateTime!.compareTo(b.departureDateTime!));
    _transitUpdators = transitsWithValidDateTime
      ..addAll(transitsWithInvalidDateTime);
  }
}

class _TransitListItem extends StatelessWidget {
  TransitUpdator transitUpdator;
  List<TransitOptionMetadata> transitOptionMetadatas;
  _TransitListItem(
      {super.key,
      required this.transitUpdator,
      required this.transitOptionMetadatas});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: _shouldBuildTransitListItem,
      builder: (BuildContext context, TripManagementState state) {
        var shouldOpenForEditing =
            transitUpdator.dataState == DataState.Selected ||
                transitUpdator.dataState == DataState.CreateNewUIEntry;
        return Material(
          child: AnimatedSize(
              curve: shouldOpenForEditing ? Curves.easeInOut : Curves.easeOut,
              duration: Duration(milliseconds: 700),
              reverseDuration: Duration(milliseconds: 700),
              child: InkWell(
                onTap: shouldOpenForEditing
                    ? null
                    : () {
                        var currentOperation = transitUpdator.dataState;
                        if (currentOperation == DataState.Created ||
                            currentOperation == DataState.Updated ||
                            currentOperation == DataState.None) {
                          var tripManagementBloc =
                              BlocProvider.of<TripManagementBloc>(context);
                          tripManagementBloc.add(UpdateTransit.select(
                              transitUpdator: transitUpdator));
                        }
                      },
                child: shouldOpenForEditing
                    ? OpenedTransitListItem(
                        initialTransitUpdator: transitUpdator,
                        transitOptionMetadatas: transitOptionMetadatas,
                      )
                    : ClosedTransitListItem(
                        transitUpdator: transitUpdator,
                        transitOptionMetadatas: transitOptionMetadatas,
                      ),
              )),
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  bool _shouldBuildTransitListItem(
      TripManagementState previousState, TripManagementState currentState) {
    if (currentState is TransitUpdated) {
      var operationToPerform = currentState.operation;
      var updatedTransitId = currentState.transitUpdator.id;
      if (operationToPerform == DataState.Selected) {
        if (updatedTransitId == transitUpdator.id) {
          return true;
        } else {
          if (transitUpdator.dataState == DataState.Selected) {
            transitUpdator.dataState = DataState.None;
            return true;
          }
        }
      } else if (operationToPerform == DataState.Updated &&
          transitUpdator.id == currentState.transitUpdator.id) {
        transitUpdator = currentState.transitUpdator;
        return true;
      }
    }
    return false;
  }
}
