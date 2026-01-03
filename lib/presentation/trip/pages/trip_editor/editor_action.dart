import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_plan_data_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/trip_details_editor.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'action_handling/action_page.dart';
import 'budgeting/expenses/expense_editor.dart';
import 'lodging/lodging_editor.dart';
import 'transit/travel_editor.dart';

enum TripEditorAction {
  travel,
  stay,
  itineraryData,
  expense,
  tripDetails,
}

extension TripEditorSupportedActionExtension on TripEditorAction {
  String? getTripEntityCreatorTitle(AppLocalizations appLocalizations) {
    switch (this) {
      case TripEditorAction.travel:
        return 'Travel Entry';
      case TripEditorAction.stay:
        return 'Stay Entry';
      case TripEditorAction.expense:
        return 'Expense Entry';
      case TripEditorAction.tripDetails:
        return 'Trip Details Entry';
      default:
        return null;
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
        return Transit.newEntry(
            tripId: activeTrip.tripMetadata.id!,
            transitOption: TransitOption.publicTransport,
            allTripContributors: activeTrip.tripMetadata.contributors,
            defaultCurrency: activeTrip.tripMetadata.budget.currency);
      case TripEditorAction.stay:
        return Lodging.newEntry(
            tripId: activeTrip.tripMetadata.id!,
            allTripContributors: activeTrip.tripMetadata.contributors,
            defaultCurrency: activeTrip.tripMetadata.budget.currency);
      case TripEditorAction.expense:
        return Expense.newEntry(
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
    required bool isEditing,
    required void Function(BuildContext context) onClosePressed,
    required ScrollController scrollController,
    ItineraryPlanDataEditorConfig? itineraryConfig,
  }) {
    var actionIcon = isEditing ? Icons.check_rounded : Icons.add_rounded;
    void Function(BuildContext context)? onActionInvoked;
    Widget Function(ValueNotifier<bool> validityNotifier)? pageContentCreator;
    // Use a ValueNotifier to track the current entity state (mutable holder for immutable model)
    final tripEntityNotifier = ValueNotifier<TripEntity>(tripEntity.clone());

    if (this == TripEditorAction.tripDetails &&
        tripEntity is TripMetadataFacade) {
      pageContentCreator = (validityNotifier) => TripDetailsEditor(
            tripMetadataFacade: tripEntityNotifier.value as TripMetadata,
            onTripMetadataUpdated: (updated) {
              tripEntityNotifier.value = updated;
              validityNotifier.value = updated.validate();
            },
          );
    } else if (this == TripEditorAction.itineraryData &&
        tripEntity is ItineraryPlanData) {
      pageContentCreator = (validityNotifier) => ItineraryPlanDataEditor(
            planData: tripEntityNotifier.value as ItineraryPlanData,
            onPlanDataUpdated: (updated) {
              tripEntityNotifier.value = updated;
              validityNotifier.value = updated.validate();
            },
            config: itineraryConfig!,
          );
    } else if (this == TripEditorAction.travel && tripEntity is TransitFacade) {
      pageContentCreator = (validityNotifier) => TravelEditor(
            initialTransit: tripEntityNotifier.value as Transit,
            onTransitUpdated: (updated) {
              tripEntityNotifier.value = updated;
              validityNotifier.value = updated.validate();
            },
          );
    } else if (this == TripEditorAction.stay && tripEntity is LodgingFacade) {
      pageContentCreator = (validityNotifier) => LodgingEditor(
            initialLodging: tripEntityNotifier.value as Lodging,
            onLodgingUpdated: (updated) {
              tripEntityNotifier.value = updated;
              validityNotifier.value = updated.validate();
            },
          );
    } else if (this == TripEditorAction.expense &&
        tripEntity is ExpenseLinkedTripEntity) {
      pageContentCreator = (validityNotifier) => ExpenseEditor(
            expenseLinkedTripEntity:
                tripEntityNotifier.value as ExpenseLinkedTripEntity,
            onExpenseUpdated: () {
              // The expense editor mutates the entity directly, so just update validity
              validityNotifier.value = tripEntityNotifier.value.validate();
            },
          );
    }

    if (pageContentCreator != null) {
      onActionInvoked = (context) => context.addTripManagementEvent(isEditing
          ? _eventEmittersPerUpdateActions[this]!(tripEntityNotifier.value)
          : _eventEmittersPerAddActions[this]!(tripEntityNotifier.value));
    }
    if (pageContentCreator != null && onActionInvoked != null) {
      return TripEditorActionPage(
        tripEntity: tripEntityNotifier.value,
        title: title,
        onClosePressed: onClosePressed,
        onActionInvoked: onActionInvoked,
        scrollController: scrollController,
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
            TripEditorAction.expense: (entity) =>
                UpdateTripEntity<ExpenseFacade>.create(
                    tripEntity: entity as ExpenseFacade),
          };

  Map<
      TripEditorAction,
      TripManagementEvent Function(
          TripEntity<dynamic>)> get _eventEmittersPerUpdateActions =>
      <TripEditorAction, TripManagementEvent Function(TripEntity)>{
        TripEditorAction.travel: (entity) =>
            UpdateTripEntity<TransitFacade>.update(
                tripEntity: entity as TransitFacade),
        TripEditorAction.stay: (entity) =>
            UpdateTripEntity<LodgingFacade>.update(
                tripEntity: entity as LodgingFacade),
        TripEditorAction.itineraryData: (entity) =>
            UpdateTripEntity<ItineraryPlanData>.update(
                tripEntity: entity as ItineraryPlanData),
        TripEditorAction.expense: (entity) {
          if (entity is TransitFacade) {
            return UpdateTripEntity<TransitFacade>.update(tripEntity: entity);
          } else if (entity is LodgingFacade) {
            return UpdateTripEntity<LodgingFacade>.update(tripEntity: entity);
          }
          return UpdateTripEntity<ExpenseFacade>.update(
              tripEntity: entity as ExpenseFacade);
        },
        TripEditorAction.tripDetails: (entity) =>
            UpdateTripEntity<TripMetadataFacade>.update(
                tripEntity: entity as TripMetadataFacade),
      };
}
