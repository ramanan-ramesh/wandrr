import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';

/// Utility class for generating descriptive conflict messages
class ConflictMessageBuilder {
  ConflictMessageBuilder._();

  /// Generates a descriptive message for a stay conflict
  static String forStayConflict(EntityChange<LodgingFacade> change) {
    final stay = change.originalEntity;
    final location = stay.location?.toString() ?? 'this stay';

    return 'The check-in/check-out dates for $location overlap with your selected times. '
        'Please adjust the dates below or delete this stay.';
  }

  /// Generates a descriptive message for a transit conflict
  static String forTransitConflict(EntityChange<TransitFacade> change) {
    final transit = change.originalEntity;
    final from = transit.departureLocation?.toString() ?? '?';
    final to = transit.arrivalLocation?.toString() ?? '?';

    return 'The transit from $from to $to has arrival/departure times that conflict '
        'with your selected times. Please adjust the times below or delete this transit.';
  }

  /// Generates a descriptive message for a sight conflict
  static String forSightConflict(EntityChange<SightFacade> change) {
    final sight = change.originalEntity;

    return 'The visit time for "${sight.name}" overlaps with your selected times. '
        'Please adjust the visit time below or delete this sight.';
  }

  /// Generates a summary message for the conflict resolution header
  static String buildSummaryMessage(TripDataUpdatePlan plan) {
    final parts = <String>[];

    if (plan.transitChanges.isNotEmpty) {
      final count = plan.transitChanges.length;
      parts.add('$count transit${count > 1 ? 's' : ''} with conflicting times');
    }

    if (plan.stayChanges.isNotEmpty) {
      final count = plan.stayChanges.length;
      parts.add('$count stay${count > 1 ? 's' : ''} with overlapping dates');
    }

    if (plan.sightChanges.isNotEmpty) {
      final count = plan.sightChanges.length;
      parts.add(
          '$count sight${count > 1 ? 's' : ''} with conflicting visit times');
    }

    if (parts.isEmpty) return 'No conflicts detected.';

    return 'Found ${parts.join(', ')}. Review and resolve each conflict below.';
  }

  /// Generates an info message explaining what the user should do
  static String buildActionMessage() {
    return 'Items marked for deletion will be removed when you save. '
        'To keep an item, update its times to avoid conflicts, or tap the restore button.';
  }

  /// Generates a short description for what caused the conflict
  static String buildConflictReason({
    required String entityType,
    required String originalTime,
  }) {
    return 'Original $entityType time: $originalTime';
  }

  /// Generates a header message for a specific entity type section
  static String buildSectionHeader({
    required String entityType,
    required int count,
  }) {
    switch (entityType.toLowerCase()) {
      case 'transit':
      case 'transits':
        return '$count Transit${count > 1 ? 's' : ''} with Conflicting Arrival/Departure Times';
      case 'stay':
      case 'stays':
        return '$count Stay${count > 1 ? 's' : ''} with Overlapping Check-in/Check-out Dates';
      case 'sight':
      case 'sights':
        return '$count Sight${count > 1 ? 's' : ''} with Conflicting Visit Times';
      default:
        return '$count $entityType${count > 1 ? 's' : ''}';
    }
  }
}
