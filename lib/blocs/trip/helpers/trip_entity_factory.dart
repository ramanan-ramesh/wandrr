import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Factory class for creating new UI entry trip entities
class TripEntityFactory {
  /// Creates a new UI entry for transit
  static TransitFacade createTransit({
    required TripMetadataFacade tripMetadata,
    TransitFacade? existing,
  }) {
    return existing ??
        TransitFacade.newUiEntry(
          tripId: tripMetadata.id!,
          transitOption: TransitOption.publicTransport,
          allTripContributors: tripMetadata.contributors,
          defaultCurrency: tripMetadata.budget.currency,
        );
  }

  /// Creates a new UI entry for lodging
  static LodgingFacade createLodging({
    required TripMetadataFacade tripMetadata,
    LodgingFacade? existing,
  }) {
    return existing ??
        LodgingFacade.newUiEntry(
          tripId: tripMetadata.id!,
          allTripContributors: tripMetadata.contributors,
          defaultCurrency: tripMetadata.budget.currency,
        );
  }

  /// Creates a new UI entry for expense
  static StandaloneExpense createExpense({
    required TripMetadataFacade tripMetadata,
    StandaloneExpense? existing,
  }) {
    return existing ??
        StandaloneExpense(
          tripId: tripMetadata.id!,
          expense: ExpenseFacade.newUiEntry(
            allTripContributors: tripMetadata.contributors,
            defaultCurrency: tripMetadata.budget.currency,
          ),
        );
  }
}
