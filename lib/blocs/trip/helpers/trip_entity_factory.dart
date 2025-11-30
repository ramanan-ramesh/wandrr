import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';

/// Factory class for creating new UI entry trip entities
class TripEntityFactory {
  final TripDataModelEventHandler activeTrip;

  const TripEntityFactory(this.activeTrip);

  /// Creates a new UI entry for transit
  TransitFacade createTransit({TransitFacade? existing}) {
    return existing ??
        TransitFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          transitOption: TransitOption.publicTransport,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency,
        );
  }

  /// Creates a new UI entry for lodging
  LodgingFacade createLodging({LodgingFacade? existing}) {
    return existing ??
        LodgingFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency,
        );
  }

  /// Creates a new UI entry for expense
  ExpenseFacade createExpense({ExpenseFacade? existing}) {
    return existing ??
        ExpenseFacade.newUiEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency,
        );
  }
}
