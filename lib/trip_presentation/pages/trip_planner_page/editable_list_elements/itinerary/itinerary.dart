import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/app_data/models/data_states.dart';
import 'package:wandrr/app_data/models/ui_element.dart';
import 'package:wandrr/app_presentation/blocs/bloc_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';
import 'package:wandrr/app_presentation/widgets/button.dart';
import 'package:wandrr/app_presentation/widgets/text.dart';
import 'package:wandrr/trip_data/models/itinerary.dart';
import 'package:wandrr/trip_data/models/plan_data.dart';
import 'package:wandrr/trip_data/trip_repository_extensions.dart';
import 'package:wandrr/trip_presentation/pages/trip_planner_page/editable_list_elements/itinerary/stay_and_transits.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/bloc.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/events.dart';
import 'package:wandrr/trip_presentation/trip_management_bloc/states.dart';

import '../plan_data/plan_data.dart';

class ItineraryListItem extends StatefulWidget {
  ItineraryFacade itineraryFacade;

  ItineraryListItem({super.key, required this.itineraryFacade});

  DateTime get day => itineraryFacade.day;

  @override
  State<ItineraryListItem> createState() => _ItineraryListItemState();
}

class _ItineraryListItemState extends State<ItineraryListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
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
          title: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: PlatformTextElements.createHeader(
                  context: context,
                  text: DateFormat('EEE, MMM d').format(widget.day)),
            ),
          ),
          trailing: !_isCollapsed ? _buildUpdateItineraryDataButton() : null,
          onTap: () {
            setState(() {
              _isCollapsed = !_isCollapsed;
            });
          },
        ),
        if (!_isCollapsed) ItineraryStayAndTransits(itineraryDay: widget.day),
        if (!_isCollapsed) _buildPlanData()
      ],
    );
  }

  Widget _buildPlanData() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is ItineraryDataUpdated) {
          if (currentState.day.isOnSameDayAs(widget.day)) {
            return true;
          }
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        var itineraryPlanData = context
            .getActiveTrip()
            .itineraryModelCollection
            .getItineraryForDay(widget.day)
            .planData;
        _planDataUiElement.element = itineraryPlanData;
        return PlanDataListItem(
          initialPlanDataUiElement: _planDataUiElement,
          planDataUpdated: (newPlanData) {
            _planDataUiElement.element = newPlanData;
            var isValid = _planDataUiElement.element.isValid(false);
            _canUpdateItineraryDataNotifier.value = isValid;
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  Widget _buildUpdateItineraryDataButton() {
    return BlocConsumer<TripManagementBloc, TripManagementState>(
      buildWhen: (previousState, currentState) {
        if (currentState is ItineraryDataUpdated &&
            currentState.day.isOnSameDayAs(widget.day)) {
          return true;
        }
        return false;
      },
      builder: (BuildContext context, TripManagementState state) {
        _canUpdateItineraryDataNotifier.value = false;
        return PlatformSubmitterFAB.conditionallyEnabled(
          icon: Icons.check_rounded,
          isSubmitted: false,
          context: context,
          valueNotifier: _canUpdateItineraryDataNotifier,
          callback: () {
            context.addTripManagementEvent(UpdateItineraryPlanData(
                planData: _planDataUiElement.element, day: widget.day));
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
