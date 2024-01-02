import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/blocs/trip_management_bloc/bloc.dart';
import 'package:wandrr/blocs/trip_management_bloc/data_state.dart';
import 'package:wandrr/blocs/trip_management_bloc/events.dart';
import 'package:wandrr/blocs/trip_management_bloc/states.dart';
import 'package:wandrr/contracts/communicators.dart';
import 'package:wandrr/contracts/itinerary.dart';
import 'package:wandrr/contracts/lodging.dart';
import 'package:wandrr/contracts/transit.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/plan_data/opened_plan_data.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';
import 'package:wandrr/repositories/trip_management.dart';

class ItineraryListItem extends StatefulWidget {
  final ItineraryFacade itineraryFacade;

  const ItineraryListItem({super.key, required this.itineraryFacade});

  @override
  State<ItineraryListItem> createState() => _ItineraryListItemState();
}

class _ItineraryListItemState extends State<ItineraryListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<TransitFacade> _transits;
  late List<LodgingFacade> _lodgings;
  late PlanDataUpdator _planDataUpdator;
  bool _isCollapsed = true;
  var _canUpdateItineraryDataNotifier = ValueNotifier(false);
  late List _sortedEvents;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _transits = widget.itineraryFacade.transits;
    _lodgings = widget.itineraryFacade.lodgings;
    _sortedEvents = widget.itineraryFacade.calculateSortedEvents();
    var activeTripMetadata =
        RepositoryProvider.of<TripManagement>(context).activeTrip!.tripMetaData;
    _planDataUpdator = PlanDataUpdator.fromPlanData(
        planDataFacade: widget.itineraryFacade.planData,
        tripId: activeTripMetadata.id);
  }

  bool _doesTravelDayMatch(TransitUpdated transitUpdated) {
    var shouldIgnoreUpdate =
        transitUpdated.transitUpdator.dataState == DataState.CreateNewUIEntry ||
            (transitUpdated.operation == DataState.Selected);
    if (!shouldIgnoreUpdate) {
      var doesItineraryDayMatchAnyTravelDay = widget.itineraryFacade
              .isOnSameDayAs(
                  transitUpdated.transitUpdator.departureDateTime!) ||
          widget.itineraryFacade
              .isOnSameDayAs(transitUpdated.transitUpdator.arrivalDateTime!);
      if (doesItineraryDayMatchAnyTravelDay) {
        return true;
      }
    }
    return false;
  }

  bool _doesStayDayMatch(LodgingUpdated lodgingUpdated) {
    var shouldIgnoreUpdate =
        lodgingUpdated.lodgingUpdator.dataState == DataState.CreateNewUIEntry ||
            (lodgingUpdated.operation == DataState.Selected);
    if (!shouldIgnoreUpdate) {
      var doesItineraryDayMatchAnyStayDay = widget.itineraryFacade
              .isOnSameDayAs(lodgingUpdated.lodgingUpdator.checkinDateTime!) ||
          widget.itineraryFacade
              .isOnSameDayAs(lodgingUpdated.lodgingUpdator.checkoutDateTime!);
      if (doesItineraryDayMatchAnyStayDay) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: AnimatedIcon(
              icon: _isCollapsed
                  ? AnimatedIcons.view_list
                  : AnimatedIcons.menu_arrow,
              progress: _animationController),
          title: PlatformTextElements.createHeader(
              context: context,
              text:
                  DateFormat('EEE, MMM d').format(widget.itineraryFacade.day)),
          trailing: _buildUpdateItineraryDataButton(),
          onTap: () {
            setState(() {
              _isCollapsed = !_isCollapsed;
            });
          },
        ),
        if (!_isCollapsed)
          BlocConsumer<TripManagementBloc, TripManagementState>(
            builder: (BuildContext context, TripManagementState state) {
              var activeTrip =
                  RepositoryProvider.of<TripManagement>(context).activeTrip!;
              var itineraryToConsider = activeTrip.itineraries.firstWhere(
                  (element) =>
                      element.isOnSameDayAs(widget.itineraryFacade.day));
              if (state is TransitUpdated && _doesTravelDayMatch(state)) {
                _transits = List.of(itineraryToConsider.transits);
              } else if (state is LodgingUpdated && _doesStayDayMatch(state)) {
                _lodgings = List.of(itineraryToConsider.lodgings);
              }
              _sortedEvents = itineraryToConsider.calculateSortedEvents();
              return ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    var event = _sortedEvents.elementAt(index);
                    if (event is TransitFacade) {
                      return _buildTransit(event);
                    } else {
                      return _buildLodging(event);
                    }
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Padding(
                        padding: EdgeInsets.symmetric(vertical: 3.0));
                  },
                  itemCount: _sortedEvents.length);
            },
            buildWhen: (previousState, currentState) {
              if (currentState is LoadedTrip) {
                return true;
              } else if (currentState is TransitUpdated) {
                if (_doesTravelDayMatch(currentState)) {
                  return true;
                }
              } else if (currentState is LodgingUpdated) {
                if (_doesStayDayMatch(currentState)) {
                  return true;
                }
              }
              return false;
            },
            listener: (BuildContext context, TripManagementState state) {},
          ),
        if (!_isCollapsed) _buildPlanData()
      ],
    );
  }

  BlocConsumer<TripManagementBloc, TripManagementState> _buildPlanData() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is LoadedTrip) {
          return true;
        } else if (currentState is ItineraryDataUpdated &&
            widget.itineraryFacade.isOnSameDayAs(currentState.day)) {
          return true;
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        return OpenedPlanDataListItem(
          initialPlanDataUpdator: _planDataUpdator,
          planDataUpdated: (newPlanData, canUpdatePlanData) {
            _planDataUpdator = newPlanData;
            _canUpdateItineraryDataNotifier.value = canUpdatePlanData;
          },
          isPlanDataList: true,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildTransit(TransitFacade transitFacade) {
    String dateTimeDetail = '';
    var dateTimeFormat = DateFormat('h:mm a');
    var departureDateTime = transitFacade.departureDateTime;
    var arrivalDateTime = transitFacade.arrivalDateTime;
    if (widget.itineraryFacade.isOnSameDayAs(departureDateTime) &&
        widget.itineraryFacade.isOnSameDayAs(arrivalDateTime)) {
      dateTimeDetail =
          '${dateTimeFormat.format(transitFacade.departureDateTime)} - ${dateTimeFormat.format(transitFacade.arrivalDateTime)}';
    } else if (widget.itineraryFacade.isOnSameDayAs(departureDateTime)) {
      dateTimeDetail =
          '${AppLocalizations.of(context)!.depart} ${dateTimeFormat.format(transitFacade.departureDateTime)}';
    } else if (widget.itineraryFacade.isOnSameDayAs(arrivalDateTime)) {
      dateTimeDetail =
          '${AppLocalizations.of(context)!.arrive} ${dateTimeFormat.format(transitFacade.arrivalDateTime)}';
    }
    return Stack(
      children: [
        IconButton.filledTonal(
          onPressed: () {},
          iconSize: 30,
          icon: Icon(Icons.train_rounded),
        ),
        Positioned.fill(
          left: 30,
          child: ListTile(
            tileColor: Colors.white12,
            title: Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: Text(
                  '${transitFacade.departureLocation.context.name} - ${transitFacade.arrivalLocation.context.name}'),
            ),
            trailing: Text(dateTimeDetail),
          ),
        ),
      ],
    );
  }

  Widget _buildLodging(LodgingFacade lodgingFacade) {
    var dateTimeFormat = DateFormat('h:mm a');
    var checkingDetail = widget.itineraryFacade
            .isOnSameDayAs(lodgingFacade.checkinDateTime)
        ? '${AppLocalizations.of(context)!.checkIn} @ ${dateTimeFormat.format(lodgingFacade.checkinDateTime)}'
        : '${AppLocalizations.of(context)!.checkOut} @ ${dateTimeFormat.format(lodgingFacade.checkoutDateTime)}';
    return Stack(
      children: [
        IconButton.filledTonal(
          onPressed: () {},
          iconSize: 30,
          icon: Icon(Icons.hotel_rounded),
        ),
        Positioned.fill(
          left: 30,
          child: ListTile(
            tileColor: Colors.white12,
            title: Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: Text(lodgingFacade.location.context.name),
            ),
            trailing: Text(checkingDetail),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateItineraryDataButton() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is LoadedTrip) {
          return true;
        }
        if (currentState is ItineraryDataUpdated &&
            widget.itineraryFacade.isOnSameDayAs(currentState.day)) {
          return true;
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        _canUpdateItineraryDataNotifier.value = false;
        return ValueListenableBuilder(
            valueListenable: _canUpdateItineraryDataNotifier,
            builder: (context, canUpdateItineraryData, oldWidget) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 500),
                child: Visibility(
                  visible: canUpdateItineraryData,
                  child: PlatformSubmitterFAB(
                      icon: Icons.check_rounded,
                      context: context,
                      backgroundColor: canUpdateItineraryData
                          ? Colors.black
                          : Colors.white12,
                      callback: canUpdateItineraryData
                          ? () {
                              var tripManagementBloc =
                                  BlocProvider.of<TripManagementBloc>(context);
                              tripManagementBloc.add(UpdateItineraryData(
                                  planDataUpdator: _planDataUpdator,
                                  day: widget.itineraryFacade.day));
                            }
                          : null),
                ),
              );
            });
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
