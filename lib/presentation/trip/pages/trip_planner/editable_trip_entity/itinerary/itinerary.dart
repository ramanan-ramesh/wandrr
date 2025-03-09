import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/app/models/ui_element.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/plan_data.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/extensions.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/bloc/bloc.dart';
import 'package:wandrr/presentation/trip/bloc/events.dart';
import 'package:wandrr/presentation/trip/bloc/states.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/editable_trip_entity/itinerary/stay_and_transits.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

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
  late UiElement<PlanDataFacade> _planDataUiElement;
  bool _isCollapsed = true;
  final _canUpdateItineraryDataNotifier = ValueNotifier(false);

  String? _errorMessage;
  bool _showErrorMessage = false;

  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _planDataUiElement = UiElement<PlanDataFacade>(
        element: widget.itineraryFacade.planData, dataState: DataState.None);
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0, 0), end: const Offset(0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.1, 0), end: const Offset(-0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.1, 0), end: const Offset(0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.1, 0), end: const Offset(-0.1, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(-0.1, 0), end: const Offset(0, 0)),
          weight: 1),
    ]).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutCirc));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading:
              Icon(_isCollapsed ? Icons.menu_open_rounded : Icons.list_rounded),
          title: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: PlatformTextElements.createSubHeader(
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
        if (_showErrorMessage && _errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Visibility(
              visible: _showErrorMessage,
              child: SlideTransition(
                position: _animation,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        if (!_isCollapsed) ItineraryStayAndTransits(itineraryDay: widget.day),
        if (!_isCollapsed) _buildPlanData()
      ],
    );
  }

  void _showError(String message) {
    Future.delayed(Duration(seconds: 3), () {
      _animationController.stop();
    });
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _showErrorMessage = false;
      });
    });
    setState(() {
      _errorMessage = message;
      _showErrorMessage = true;
    });
    _animationController.repeat(reverse: true);
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
        var itineraryPlanData = context.activeTrip.itineraryModelCollection
            .getItineraryForDay(widget.day)
            .planData;
        _planDataUiElement.element = itineraryPlanData;
        return PlanDataListItem(
          initialPlanDataUiElement: _planDataUiElement,
          planDataUpdated: (newPlanData) {
            _planDataUiElement.element = newPlanData;
            var planValidationResult =
                _planDataUiElement.element.getValidationResult(false);
            if (planValidationResult == PlanDataValidationResult.Valid) {
              _canUpdateItineraryDataNotifier.value = true;
            } else {
              _canUpdateItineraryDataNotifier.value = false;
            }
          },
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }

  void _tryShowError() {
    var planDataValidationResult =
        _planDataUiElement.element.getValidationResult(false);
    switch (planDataValidationResult) {
      case PlanDataValidationResult.CheckListItemEmpty:
        {
          _showError(context.localizations.checkListItemCannotBeEmpty);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.CheckListTitleNotValid:
        {
          _showError(
              context.localizations.checkListTitleMustBeAtleast3Characters);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.NoNotesOrCheckListsOrPlaces:
        {
          _showError(context.localizations.noNotesOrCheckListsOrPlaces);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.NoteEmpty:
        {
          _showError(context.localizations.noteCannotBeEmpty);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.TitleEmpty:
        {
          _showError(context.localizations.titleCannotBeEmpty);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      default:
        _canUpdateItineraryDataNotifier.value = true;
        break;
    }
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
          callbackOnClickWhileDisabled: () {
            _tryShowError();
          },
          isElevationRequired: false,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
