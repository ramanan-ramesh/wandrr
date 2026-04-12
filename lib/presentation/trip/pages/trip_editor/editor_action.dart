import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

/// Available editor actions in the trip editor
enum TripEditorAction {
  travel,
  stay,
  itineraryData,
  expense,
  tripDetails,
}

extension TripEditorActionMetadata on TripEditorAction {
  String? getCreatorTitle(AppLocalizations l10n) {
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

  String getSubtitle(AppLocalizations l10n, {required bool isEditing}) {
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

  /// Creates a new empty entity for this action type
  // TODO: Move this logic to backend or bloc
  TripEntity createEntity(BuildContext context) {
    final trip = context.activeTrip;
    final contributors = trip.tripMetadata.contributors;
    final currency = trip.tripMetadata.budget.currency;
    final tripId = trip.tripMetadata.id!;

    switch (this) {
      case TripEditorAction.travel:
        return TransitFacade.newUiEntry(
          tripId: tripId,
          transitOption: TransitOption.publicTransport,
          allTripContributors: contributors,
          defaultCurrency: currency,
        );
      case TripEditorAction.stay:
        return LodgingFacade.newUiEntry(
          tripId: tripId,
          allTripContributors: contributors,
          defaultCurrency: currency,
        );
      case TripEditorAction.expense:
        return StandaloneExpense(
          tripId: tripId,
          expense: ExpenseFacade.newUiEntry(
            allTripContributors: contributors,
            defaultCurrency: currency,
          ),
        );
      case TripEditorAction.itineraryData:
      case TripEditorAction.tripDetails:
        throw UnimplementedError('Cannot create new entity for $this');
    }
  }
}
