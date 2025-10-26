import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/plan_data/plan_data.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/plan_data/plan_data.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

import 'budgeting/expense_editor.dart';
import 'editing/action_page.dart';
import 'lodging/lodging_editor.dart';
import 'transit/transit.dart';

enum TripEditorAction {
  travel,
  stay,
  tripData,
  expense,
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
      case TripEditorAction.expense:
        return 'Expense Entry';
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
      case TripEditorAction.expense:
        return isEditing ? 'Edit expense details' : 'Add expense details';
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
    }
  }

  TripEditorActionPage? createActionPage<T extends TripEntity>({
    required T tripEntity,
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
      onActionInvoked = (context) {
        context.addTripManagementEvent(isEditing
            ? UpdateTripEntity<ExpenseFacade>.update(tripEntity: tripEntity)
            : UpdateTripEntity<ExpenseFacade>.create(tripEntity: tripEntity));
      };
      pageContentCreator = (validityNotifier) => ExpenseEditor(
            expense: tripEntity,
            validityNotifier: validityNotifier,
          );
    } else if (tripEntity is TransitFacade) {
      onActionInvoked = (context) {
        context.addTripManagementEvent(isEditing
            ? UpdateTripEntity<TransitFacade>.update(tripEntity: tripEntity)
            : UpdateTripEntity<TransitFacade>.create(tripEntity: tripEntity));
      };
      pageContentCreator = (validityNotifier) => TravelEditor(
            transitFacade: tripEntity,
            onTransitUpdated: () {
              validityNotifier.value = tripEntity.validate();
            },
          );
    } else if (tripEntity is LodgingFacade) {
      onActionInvoked = (context) {
        context.addTripManagementEvent(isEditing
            ? UpdateTripEntity<LodgingFacade>.update(tripEntity: tripEntity)
            : UpdateTripEntity<LodgingFacade>.create(tripEntity: tripEntity));
      };
      pageContentCreator = (validityNotifier) => LodgingEditor(
            lodging: tripEntity,
            onLodgingUpdated: () {
              validityNotifier.value = tripEntity.validate();
            },
          );
    } else if (tripEntity is PlanDataFacade) {
      if (tripDay != null) {
        onActionInvoked = (context) {
          context.addTripManagementEvent(
              UpdateItineraryPlanData(planData: tripEntity, day: tripDay));
        };
        pageContentCreator = (validityNotifier) => PlanDataListItem(
              planData: tripEntity,
              planDataUpdated: (newPlanData) {
                validityNotifier.value = newPlanData.validate();
              },
            );
      } else {
        onActionInvoked = (context) {
          context.addTripManagementEvent(
              UpdateTripEntity<PlanDataFacade>.update(tripEntity: tripEntity));
        };
      }
      pageContentCreator = (validityNotifier) => PlanDataListItem(
            planData: tripEntity,
            planDataUpdated: (newPlanData) {
              validityNotifier.value = newPlanData.validate();
            },
          );
    }

    if (onActionInvoked != null) {
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
}
