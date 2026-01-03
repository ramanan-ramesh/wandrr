import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';

/// Factory class for creating new UI entry trip entities
class TripEntityFactory {
  final TripDataModelEventHandler activeTrip;

  const TripEntityFactory(this.activeTrip);

  /// Creates a new UI entry for transit
  Transit createTransit({Transit? existing}) {
    return existing ??
        Transit.newEntry(
          tripId: activeTrip.tripMetadata.id!,
          transitOption: TransitOption.publicTransport,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency,
        );
  }

  /// Creates a new UI entry for lodging
  Lodging createLodging({Lodging? existing}) {
    return existing ??
        Lodging.newEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency,
        );
  }

  /// Creates a new UI entry for expense
  Expense createExpense({Expense? existing}) {
    return existing ??
        Expense.newEntry(
          tripId: activeTrip.tripMetadata.id!,
          allTripContributors: activeTrip.tripMetadata.contributors,
          defaultCurrency: activeTrip.tripMetadata.budget.currency,
        );
  }
}
