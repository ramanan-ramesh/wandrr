import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/plan_data/plan_data.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/trip_details_editor.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'action_handling/action_page.dart';
import 'budgeting/expense_editor.dart';
import 'lodging/lodging_editor.dart';
import 'transit/travel_editor.dart';

enum TripEditorAction {
  travel,
  stay,
  tripData,
  itineraryData,
  expense,
  tripDetails,
}

extension TripEditorSupportedActionExtension on TripEditorAction {
  String createTitle(AppLocalizations appLocalizations) {
    switch (this) {
      case TripEditorAction.travel:
        return 'Travel Entry';
      case TripEditorAction.stay:
        return 'Stay Entry';
      case TripEditorAction.tripData:
        return 'Trip Data Entry';
      case TripEditorAction.itineraryData:
        return 'Itinerary Data Entry';
      case TripEditorAction.expense:
        return 'Expense Entry';
      case TripEditorAction.tripDetails:
        return 'Trip Details Entry';
    }
  }

  String createSubtitle(AppLocalizations appLocalizations, bool isEditing) {
    switch (this) {
      case TripEditorAction.travel:
        return isEditing
            ? 'Edit transit information'
            : 'Add transit information';
      case TripEditorAction.stay:
        return isEditing ? 'Edit lodging details' : 'Add lodging details';
      case TripEditorAction.tripData:
        return isEditing
            ? 'Edit trip notes and checklist'
            : 'Add trip notes and checklist';
      case TripEditorAction.itineraryData:
        return isEditing ? 'Edit itinerary details' : 'Add itinerary details';
      case TripEditorAction.expense:
        return isEditing ? 'Edit expense details' : 'Add expense details';
      case TripEditorAction.tripDetails:
        return 'Edit trip details';
    }
  }

  IconData get icon {
    switch (this) {
      case TripEditorAction.travel:
        return Icons.flight;
      case TripEditorAction.stay:
        return Icons.hotel;
      case TripEditorAction.tripData:
        return Icons.note;
      case TripEditorAction.expense:
        return Icons.money;
      case TripEditorAction.itineraryData:
        return Icons.travel_explore_rounded;
      case TripEditorAction.tripDetails:
        return Icons.card_travel_rounded;
    }
  }

  TripEntity createTripEntity(BuildContext context) {
    var activeTrip = context.activeTrip;
    switch (this) {
      case TripEditorAction.travel:
        return TransitFacade.newUiEntry(
            tripId: activeTrip.tripMetadata.id!,
            transitOption: TransitOption.publicTransport,
            allTripContributors: activeTrip.tripMetadata.contributors,
            defaultCurrency: activeTrip.tripMetadata.budget.currency);
      case TripEditorAction.stay:
        return LodgingFacade.newUiEntry(
            tripId: activeTrip.tripMetadata.id!,
            allTripContributors: activeTrip.tripMetadata.contributors,
            defaultCurrency: activeTrip.tripMetadata.budget.currency);
      case TripEditorAction.tripData:
        return PlanDataFacade.newEntry(tripId: activeTrip.tripMetadata.id!);
      case TripEditorAction.expense:
        return ExpenseFacade.newUiEntry(
            tripId: activeTrip.tripMetadata.id!,
            allTripContributors: activeTrip.tripMetadata.contributors,
            defaultCurrency: activeTrip.tripMetadata.budget.currency);
      case TripEditorAction.itineraryData:
        throw UnimplementedError(); //TODO: Remove UnimplementedError in general
      case TripEditorAction.tripDetails:
        throw UnimplementedError(); //TODO: Remove UnimplementedError in general
    }
  }

  TripEditorActionPage? createActionPage({
    required TripEntity tripEntity,
    required String title,
    DateTime? tripDay,
    required bool isEditing,
    required void Function(BuildContext context) onClosePressed,
    required ScrollController scrollController,
  }) {
    var actionIcon = isEditing ? Icons.check_rounded : Icons.add_rounded;
    void Function(BuildContext context)? onActionInvoked;
    Widget Function(ValueNotifier<bool> validityNotifier)? pageContentCreator;
    if (tripEntity is ExpenseFacade) {
      pageContentCreator = (validityNotifier) => ExpenseEditor(
            expense: tripEntity,
            onExpenseUpdated: () => validityNotifier.value =
                tripEntity.validate() && tripEntity.title.isNotEmpty,
          );
    } else if (tripEntity is TransitFacade) {
      pageContentCreator = (validityNotifier) => TravelEditor(
            transitFacade: tripEntity,
            onTransitUpdated: () =>
                validityNotifier.value = tripEntity.validate(),
          );
    } else if (tripEntity is LodgingFacade) {
      pageContentCreator = (validityNotifier) => LodgingEditor(
            lodging: tripEntity,
            onLodgingUpdated: () =>
                validityNotifier.value = tripEntity.validate(),
          );
    } else if (tripEntity is PlanDataFacade) {
      pageContentCreator = (validityNotifier) => PlanDataListItem(
            planData: tripEntity,
            planDataUpdated: (newPlanData) =>
                validityNotifier.value = newPlanData.validate(),
          );
    } else if (tripEntity is ItineraryPlanData) {
      pageContentCreator = (validityNotifier) => Container();
    } else if (tripEntity is TripMetadataFacade) {
      pageContentCreator = (validityNotifier) => TripDetailsEditor(
            tripMetadataFacade: tripEntity,
            onTripMetadataUpdated: () =>
                validityNotifier.value = tripEntity.validate(),
          );
    }

    if (pageContentCreator != null) {
      onActionInvoked = (context) => context.addTripManagementEvent(isEditing
          ? _eventEmittersPerUpdateActions[this]!(tripEntity)
          : _eventEmittersPerAddActions[this]!(tripEntity));
    }
    if (pageContentCreator != null && onActionInvoked != null) {
      return TripEditorActionPage(
        tripEntity: tripEntity,
        title: title,
        onClosePressed: onClosePressed,
        onActionInvoked: onActionInvoked,
        scrollController: scrollController,
        tripEditorAction: this,
        pageContentCreator: (validityNotifier) =>
            pageContentCreator!(validityNotifier),
        actionIcon: actionIcon,
      );
    }
    return null;
  }

  Map<TripEditorAction, TripManagementEvent Function(TripEntity<dynamic>)>
      get _eventEmittersPerAddActions =>
          <TripEditorAction, TripManagementEvent Function(TripEntity)>{
            TripEditorAction.travel: (entity) =>
                UpdateTripEntity<TransitFacade>.create(
                    tripEntity: entity as TransitFacade),
            TripEditorAction.stay: (entity) =>
                UpdateTripEntity<LodgingFacade>.create(
                    tripEntity: entity as LodgingFacade),
            TripEditorAction.tripData: (entity) =>
                UpdateTripEntity<PlanDataFacade>.create(
                    tripEntity: entity as PlanDataFacade),
            TripEditorAction.itineraryData: (entity) =>
                UpdateTripEntity<ItineraryPlanData>.create(
                    tripEntity: entity as ItineraryPlanData),
            TripEditorAction.expense: (entity) =>
                UpdateTripEntity<ExpenseFacade>.create(
                    tripEntity: entity as ExpenseFacade),
          };

  Map<TripEditorAction, TripManagementEvent Function(TripEntity<dynamic>)>
      get _eventEmittersPerUpdateActions =>
          <TripEditorAction, TripManagementEvent Function(TripEntity)>{
            TripEditorAction.travel: (entity) =>
                UpdateTripEntity<TransitFacade>.update(
                    tripEntity: entity as TransitFacade),
            TripEditorAction.stay: (entity) =>
                UpdateTripEntity<LodgingFacade>.update(
                    tripEntity: entity as LodgingFacade),
            TripEditorAction.tripData: (entity) =>
                UpdateTripEntity<PlanDataFacade>.update(
                    tripEntity: entity as PlanDataFacade),
            TripEditorAction.itineraryData: (entity) =>
                UpdateTripEntity<ItineraryPlanData>.update(
                    tripEntity: entity as ItineraryPlanData),
            TripEditorAction.expense: (entity) =>
                UpdateTripEntity<ExpenseFacade>.update(
                    tripEntity: entity as ExpenseFacade),
          };
}
