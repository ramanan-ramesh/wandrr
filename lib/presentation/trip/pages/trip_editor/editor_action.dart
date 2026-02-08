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
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_detection_callback.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/entity_conflict_coordinator.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_plan_data_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/trip_details_editor.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'action_handling/action_page.dart';
import 'action_handling/conflict_aware_action_page.dart';
import 'budgeting/expenses/expense_editor.dart';
import 'lodging/lodging_editor.dart';
import 'transit/journey_editor.dart';

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
      case TripEditorAction.expense:
        return StandaloneExpense(
            tripId: activeTrip.tripMetadata.id!,
            expense: ExpenseFacade.newUiEntry(
                allTripContributors: activeTrip.tripMetadata.contributors,
                defaultCurrency: activeTrip.tripMetadata.budget.currency));
      case TripEditorAction.itineraryData:
        throw UnimplementedError(); //TODO: Remove UnimplementedError in general
      case TripEditorAction.tripDetails:
        throw UnimplementedError(); //TODO: Remove UnimplementedError in general
    }
  }

  Widget? createActionPage({
    required TripEntity tripEntity,
    required String title,
    required bool isEditing,
    required void Function(BuildContext context) onClosePressed,
    required ScrollController scrollController,
    required BuildContext context,
    ItineraryPlanDataEditorConfig? itineraryConfig,
  }) {
    var actionIcon = isEditing ? Icons.check_rounded : Icons.add_rounded;
    void Function(BuildContext context)? onActionInvoked;
    Widget Function(
            ValueNotifier<bool> validityNotifier, VoidCallback onEntityUpdated)?
        conflictAwarePageContentCreator;
    Widget Function(ValueNotifier<bool> validityNotifier)? pageContentCreator;
    ConflictDetectionCallback? conflictDetectionCallback;
    var tripEntityToEdit = tripEntity.clone();

    // Track if we need conflict-aware action page
    bool useConflictAwarePage = false;

    // Create conflict coordinator for entity-specific detection
    final coordinator = EntityConflictCoordinator(
      tripData: context.activeTrip,
    );

    if (this == TripEditorAction.tripDetails &&
        tripEntity is TripMetadataFacade) {
      useConflictAwarePage = true;
      final typedEntity = tripEntityToEdit as TripMetadataFacade;
      conflictDetectionCallback = () => coordinator.detectTripMetadataConflicts(
            typedEntity,
          );
      conflictAwarePageContentCreator =
          (validityNotifier, onEntityUpdated) => TripDetailsEditor(
                tripMetadataFacade: tripEntityToEdit,
                onTripMetadataUpdated: () {
                  validityNotifier.value = tripEntityToEdit.validate();
                  onEntityUpdated();
                },
              );
    } else if (this == TripEditorAction.itineraryData &&
        tripEntity is ItineraryPlanData) {
      useConflictAwarePage = true;
      final typedEntity = tripEntityToEdit as ItineraryPlanData;
      conflictDetectionCallback = () => coordinator.detectItineraryConflicts(
            typedEntity,
          );
      conflictAwarePageContentCreator =
          (validityNotifier, onEntityUpdated) => ItineraryPlanDataEditor(
                planData: tripEntityToEdit,
                onPlanDataUpdated: () {
                  validityNotifier.value = tripEntityToEdit.validate();
                  onEntityUpdated();
                },
                config: itineraryConfig!,
              );
    } else if (this == TripEditorAction.travel && tripEntity is TransitFacade) {
      useConflictAwarePage = true;
      final journeyEditorKey = GlobalKey<JourneyEditorState>();
      conflictAwarePageContentCreator =
          (validityNotifier, onEntityUpdated) => JourneyEditor(
                key: journeyEditorKey,
                initialLeg: tripEntityToEdit as TransitFacade,
                onJourneyUpdated: () {
                  onEntityUpdated();
                },
                validityNotifier: validityNotifier,
              );
      // Create callback that dynamically gets legs from JourneyEditor
      conflictDetectionCallback = () {
        final legs = journeyEditorKey.currentState?.legs ??
            [tripEntityToEdit as TransitFacade];
        return coordinator.detectJourneyConflicts(legs);
      };
      // Custom action for journey - saves all legs
      onActionInvoked = (context) {
        journeyEditorKey.currentState?.saveAllLegs(context);
      };
    } else if (this == TripEditorAction.stay && tripEntity is LodgingFacade) {
      useConflictAwarePage = true;
      final typedEntity = tripEntityToEdit as LodgingFacade;
      conflictDetectionCallback = () => coordinator.detectStayConflicts(
            typedEntity,
            isNewEntity: !isEditing,
          );
      conflictAwarePageContentCreator =
          (validityNotifier, onEntityUpdated) => LodgingEditor(
                lodging: tripEntityToEdit,
                onLodgingUpdated: () {
                  validityNotifier.value = tripEntityToEdit.validate();
                  onEntityUpdated();
                },
                validityNotifier: validityNotifier,
              );
    } else if (this == TripEditorAction.expense &&
        tripEntity is ExpenseBearingTripEntity) {
      pageContentCreator = (validityNotifier) => ExpenseEditor(
            expenseBearingTripEntity: tripEntityToEdit,
            onExpenseUpdated: () =>
                validityNotifier.value = tripEntityToEdit.validate(),
          );
    }

    if (onActionInvoked == null) {
      onActionInvoked = (context) => context.addTripManagementEvent(isEditing
          ? _eventEmittersPerUpdateActions[this]!(tripEntityToEdit)
          : _eventEmittersPerAddActions[this]!(tripEntityToEdit));
    }

    // Use ConflictAwareActionPage for entities that need conflict detection
    if (useConflictAwarePage && conflictAwarePageContentCreator != null) {
      if (tripEntity is TripMetadataFacade) {
        final typedEntity = tripEntityToEdit as TripMetadataFacade;
        return ConflictAwareActionPage<TripMetadataFacade>(
          tripEntity: typedEntity,
          title: title,
          onClosePressed: onClosePressed,
          onActionInvoked: onActionInvoked,
          scrollController: scrollController,
          pageContentCreator: conflictAwarePageContentCreator,
          actionIcon: actionIcon,
          conflictDetectionCallback: conflictDetectionCallback,
        );
      } else if (tripEntity is ItineraryPlanData) {
        final typedEntity = tripEntityToEdit as ItineraryPlanData;
        return ConflictAwareActionPage<ItineraryPlanData>(
          tripEntity: typedEntity,
          title: title,
          onClosePressed: onClosePressed,
          onActionInvoked: onActionInvoked,
          scrollController: scrollController,
          pageContentCreator: conflictAwarePageContentCreator,
          actionIcon: actionIcon,
          conflictDetectionCallback: conflictDetectionCallback,
        );
      } else if (tripEntity is TransitFacade) {
        final typedEntity = tripEntityToEdit as TransitFacade;
        return ConflictAwareActionPage<TransitFacade>(
          tripEntity: typedEntity,
          title: title,
          onClosePressed: onClosePressed,
          onActionInvoked: onActionInvoked,
          scrollController: scrollController,
          pageContentCreator: conflictAwarePageContentCreator,
          actionIcon: actionIcon,
          conflictDetectionCallback: conflictDetectionCallback,
        );
      } else if (tripEntity is LodgingFacade) {
        final typedEntity = tripEntityToEdit as LodgingFacade;
        return ConflictAwareActionPage<LodgingFacade>(
          tripEntity: typedEntity,
          title: title,
          onClosePressed: onClosePressed,
          onActionInvoked: onActionInvoked,
          scrollController: scrollController,
          pageContentCreator: conflictAwarePageContentCreator,
          actionIcon: actionIcon,
          conflictDetectionCallback: conflictDetectionCallback,
        );
      }
    }

    // Use regular TripEditorActionPage for non-conflict-aware entities (e.g., expenses)
    if (pageContentCreator != null) {
      if (tripEntity is ExpenseBearingTripEntity) {
        // ExpenseBearingTripEntity can be TransitFacade, LodgingFacade, or StandaloneExpense
        if (tripEntity is StandaloneExpense) {
          final typedEntity = tripEntityToEdit as StandaloneExpense;
          return TripEditorActionPage<StandaloneExpense>(
            tripEntity: typedEntity,
            title: title,
            onClosePressed: onClosePressed,
            onActionInvoked: onActionInvoked,
            scrollController: scrollController,
            pageContentCreator: (validityNotifier) =>
                pageContentCreator!(validityNotifier),
            actionIcon: actionIcon,
          );
        }
      }
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
                UpdateTripEntity<StandaloneExpense>.create(
                    tripEntity: entity as StandaloneExpense),
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
          return UpdateTripEntity<StandaloneExpense>.update(
              tripEntity: entity as StandaloneExpense);
        },
        TripEditorAction.tripDetails: (entity) =>
            UpdateTripEntity<TripMetadataFacade>.update(
                tripEntity: entity as TripMetadataFacade),
      };
}
