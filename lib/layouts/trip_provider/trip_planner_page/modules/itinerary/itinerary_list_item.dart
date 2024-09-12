import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/blocs/trip_management/bloc.dart';
import 'package:wandrr/blocs/trip_management/events.dart';
import 'package:wandrr/blocs/trip_management/states.dart';
import 'package:wandrr/contracts/database_connectors/data_states.dart';
import 'package:wandrr/contracts/extensions.dart';
import 'package:wandrr/contracts/itinerary.dart';
import 'package:wandrr/contracts/trip_entity_facades/lodging.dart';
import 'package:wandrr/contracts/trip_entity_facades/plan_data.dart';
import 'package:wandrr/contracts/trip_entity_facades/transit.dart';
import 'package:wandrr/contracts/trip_entity_facades/trip_metadata.dart';
import 'package:wandrr/contracts/ui_element.dart';
import 'package:wandrr/layouts/trip_provider/trip_planner_page/modules/plan_data/opened_plan_data/opened_plan_data.dart';
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/text.dart';

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
  LodgingFacade? _lodging;
  late UiElement<PlanDataFacade> _planDataUiElement;
  bool _isCollapsed = true;
  final _canUpdateItineraryDataNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _planDataUiElement = UiElement<PlanDataFacade>(
        element: widget.itineraryFacade.planData, dataState: DataState.None);
    _transits = widget.itineraryFacade.transits.toList();
    _transits.sort((transit1, transit2) =>
        transit1.departureDateTime!.compareTo(transit2.departureDateTime!));
    _lodging = widget.itineraryFacade.lodging;
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
          trailing: !_isCollapsed ? _buildUpdateItineraryDataButton() : null,
          onTap: () {
            setState(() {
              _isCollapsed = !_isCollapsed;
            });
          },
        ),
        if (!_isCollapsed)
          BlocConsumer<TripManagementBloc, TripManagementState>(
            builder: (BuildContext context, TripManagementState state) {
              var numberOfItems = _transits.length + (_lodging == null ? 0 : 1);
              return ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == numberOfItems - 1) {
                      if (_lodging != null) {
                        return _buildLodging();
                      }
                    }
                    return _buildTransit(_transits.elementAt(index));
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Padding(
                        padding: EdgeInsets.symmetric(vertical: 3.0));
                  },
                  itemCount: numberOfItems);
            },
            buildWhen: (previousState, currentState) {
              if (currentState.isTripEntity<TripMetadataFacade>() &&
                  (currentState as UpdatedTripEntity).dataState ==
                      DataState.Update) {
                return true;
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
        if (currentState is ItineraryDataUpdated) {
          if (_areOnSameDay(currentState.day, widget.itineraryFacade.day)) {
            return true;
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        return OpenedPlanDataListItem(
          initialPlanDataUiElement: _planDataUiElement,
          planDataUpdated: (newPlanData) {
            _planDataUiElement.element = newPlanData;
            var isValid = _planDataUiElement.isValid(
                widget.itineraryFacade.planData, false);
            _canUpdateItineraryDataNotifier.value = isValid;
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildTransit(TransitFacade transitFacade) {
    String dateTimeDetail = '';
    var dateTimeFormat = DateFormat('h:mm a');
    var departureDateTime = transitFacade.departureDateTime!;
    var arrivalDateTime = transitFacade.arrivalDateTime!;
    dateTimeDetail =
        '${dateTimeFormat.format(departureDateTime)} - ${dateTimeFormat.format(arrivalDateTime)}';
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
                  '${transitFacade.departureLocation!.context.name} - ${transitFacade.arrivalLocation!.context.name}'),
            ),
            trailing: Text(dateTimeDetail),
          ),
        ),
      ],
    );
  }

  Widget _buildLodging() {
    String stayDetail = '';
    var checkInDateTime = _lodging!.checkinDateTime!;
    var checkoutDateTime = _lodging!.checkoutDateTime!;
    var dateTime1 = DateTime(
        checkInDateTime.year, checkInDateTime.month, checkInDateTime.day);
    var dateTime2 = DateTime(widget.itineraryFacade.day.year,
        widget.itineraryFacade.day.month, widget.itineraryFacade.day.day);
    var dateTime3 = DateTime(
        checkoutDateTime.year, checkoutDateTime.month, checkoutDateTime.day);
    if (_areOnSameDay(dateTime1, dateTime2)) {
      if (_areOnSameDay(dateTime3, dateTime2)) {
        stayDetail =
            '${context.withLocale().checkIn} & ${context.withLocale().checkOut}';
      } else {
        stayDetail = context.withLocale().checkIn;
      }
    } else if (_areOnSameDay(dateTime3, dateTime2)) {
      stayDetail = context.withLocale().checkOut;
    }
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
              child: Text(_lodging!.location!.context.name),
            ),
            trailing: Text(stayDetail),
          ),
        ),
      ],
    );
  }

  bool _areOnSameDay(DateTime dateTime1, DateTime dateTime2) {
    return dateTime1.year == dateTime2.year &&
        dateTime1.month == dateTime2.month &&
        dateTime1.day == dateTime2.day;
  }

  Widget _buildUpdateItineraryDataButton() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is ItineraryDataUpdated &&
            _areOnSameDay(currentState.day, widget.itineraryFacade.day)) {
          return true;
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        _canUpdateItineraryDataNotifier.value = false;
        return PlatformSubmitterFAB.conditionallyEnabled(
          icon: Icons.check_rounded,
          context: context,
          valueNotifier: _canUpdateItineraryDataNotifier,
          callback: () {
            context.addTripManagementEvent(UpdateItineraryPlanData(
                planData: _planDataUiElement.element,
                day: widget.itineraryFacade.day));
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
