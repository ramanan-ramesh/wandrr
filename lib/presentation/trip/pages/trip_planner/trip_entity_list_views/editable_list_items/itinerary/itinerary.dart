import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/models/data_states.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/ui_element.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/itinerary/stay_and_transits.dart';
import 'package:wandrr/presentation/trip/pages/trip_planner/trip_entity_list_views/editable_list_items/plan_data/plan_data.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class ItineraryListItem extends StatefulWidget {
  final ItineraryFacade itineraryFacade;

  const ItineraryListItem({required this.itineraryFacade, super.key});

  DateTime get day => itineraryFacade.day;

  @override
  State<ItineraryListItem> createState() => _ItineraryListItemState();
}

class _ItineraryListItemState extends State<ItineraryListItem>
    with SingleTickerProviderStateMixin {
  late final UiElement<PlanDataFacade> _planDataUiElement;
  bool _isCollapsed = true;
  final _canUpdateItineraryDataNotifier = ValueNotifier(false);

  String? _errorMessage;
  bool _showErrorMessage = false;

  late final AnimationController _errorAnimationController;
  late final Animation<Offset> _errorAnimation;

  @override
  void initState() {
    super.initState();
    _intializePlanDataUiElement();
    _errorAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _createErrorAnimation();
  }

  @override
  void dispose() {
    _errorAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ItineraryListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itineraryFacade != oldWidget.itineraryFacade) {
      setState(_intializePlanDataUiElement);
    }
  }

  void _intializePlanDataUiElement() {
    _planDataUiElement = UiElement<PlanDataFacade>(
        element: widget.itineraryFacade.planData, dataState: DataState.none);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _createHeader(context),
        if (_showErrorMessage && _errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Visibility(
              visible: _showErrorMessage,
              child: SlideTransition(
                position: _errorAnimation,
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        if (!_isCollapsed)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ItineraryStayAndTransits(itineraryDay: widget.day),
          ),
        if (!_isCollapsed) _buildPlanData()
      ],
    );
  }

  ListTile _createHeader(BuildContext context) {
    return ListTile(
      leading:
          Icon(_isCollapsed ? Icons.menu_open_rounded : Icons.list_rounded),
      title: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: PlatformTextElements.createSubHeader(
              context: context, text: widget.day.dayDateMonthFormat),
        ),
      ),
      trailing: !_isCollapsed ? _buildUpdateItineraryDataButton() : null,
      onTap: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
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
        var itineraryPlanData = context.activeTrip.itineraryCollection
            .getItineraryForDay(widget.day)
            .planData;
        _planDataUiElement.element = itineraryPlanData;
        return PlanDataListItem(
          initialPlanDataUiElement: _planDataUiElement,
          planDataUpdated: (newPlanData) {
            _planDataUiElement.element = newPlanData;
            var planValidationResult =
                _planDataUiElement.element.validate(isTitleRequired: false);
            if (planValidationResult == PlanDataValidationResult.valid) {
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

  void _createErrorAnimation() {
    _errorAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.1, 0)),
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
          tween: Tween(begin: const Offset(-0.1, 0), end: Offset.zero),
          weight: 1),
    ]).animate(CurvedAnimation(
        parent: _errorAnimationController, curve: Curves.easeInOutCirc));
  }

  void _showError(String message) {
    Future.delayed(const Duration(seconds: 3), () {
      _errorAnimationController.stop();
    });
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _showErrorMessage = false;
      });
    });
    setState(() {
      _errorMessage = message;
      _showErrorMessage = true;
    });
    unawaited(_errorAnimationController.repeat(reverse: true));
  }

  void _tryShowError() {
    var planDataValidationResult =
        _planDataUiElement.element.validate(isTitleRequired: false);
    switch (planDataValidationResult) {
      case PlanDataValidationResult.checkListItemEmpty:
        {
          _showError(context.localizations.checkListItemCannotBeEmpty);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.checkListTitleNotValid:
        {
          _showError(
              context.localizations.checkListTitleMustBeAtleast3Characters);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.noNotesOrCheckListsOrPlaces:
        {
          _showError(context.localizations.noNotesOrCheckListsOrPlaces);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.noteEmpty:
        {
          _showError(context.localizations.noteCannotBeEmpty);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      case PlanDataValidationResult.titleEmpty:
        {
          _showError(context.localizations.titleCannotBeEmpty);
          _canUpdateItineraryDataNotifier.value = false;
          break;
        }
      default:
        _canUpdateItineraryDataNotifier.value = true;
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
          valueNotifier: _canUpdateItineraryDataNotifier,
          callback: () {
            context.addTripManagementEvent(UpdateItineraryPlanData(
                planData: _planDataUiElement.element, day: widget.day));
          },
          callbackOnClickWhileDisabled: _tryShowError,
          isElevationRequired: false,
        );
      },
      listener: (BuildContext context, TripManagementState state) {},
    );
  }
}
