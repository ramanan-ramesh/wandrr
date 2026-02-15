import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Action to perform on an entity
enum ChangeAction { update, delete }

/// Describes the source of a conflict - what entity caused it and why
class ConflictSource {
  /// Type description of the source entity (e.g., "Transit", "Stay", "Trip dates")
  final String sourceType;

  /// Display name of the source entity (e.g., "Paris → London", "Hotel Ibis")
  final String sourceName;

  /// The time range of the source entity that caused the conflict
  final TimeRange sourceTimeRange;

  const ConflictSource({
    required this.sourceType,
    required this.sourceName,
    required this.sourceTimeRange,
  });

  /// Compact time range display (e.g., "Mon 5 2:30 PM - 4:00 PM")
  String get compactTimeRange {
    return '${_formatCompactTime(sourceTimeRange.start)} - ${_formatCompactTime(sourceTimeRange.end)}';
  }

  /// Short conflict message for display
  String get shortMessage => '$sourceType: $sourceName';

  static String _formatCompactTime(DateTime dt) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dayNames[dt.weekday - 1]} ${dt.day} $hour:$minute $amPm';
  }

  /// Creates a conflict source for trip metadata date changes
  factory ConflictSource.fromMetadataChange({
    required DateTime newTripStart,
    required DateTime newTripEnd,
  }) {
    return ConflictSource(
      sourceType: 'Trip dates',
      sourceName: 'New trip range',
      sourceTimeRange: TimeRange(start: newTripStart, end: newTripEnd),
    );
  }

  /// Creates a conflict source for a transit being edited
  factory ConflictSource.fromTransit(TransitFacade transit) {
    final from = transit.departureLocation?.context.name ?? '?';
    final to = transit.arrivalLocation?.context.name ?? '?';
    return ConflictSource(
      sourceType: 'Transit',
      sourceName: '$from → $to',
      sourceTimeRange: TimeRange(
        start: transit.departureDateTime ?? DateTime.now(),
        end: transit.arrivalDateTime ?? DateTime.now(),
      ),
    );
  }

  /// Creates a conflict source for a stay being edited
  factory ConflictSource.fromStay(LodgingFacade stay) {
    final location = stay.location?.context.name ?? 'Stay';
    return ConflictSource(
      sourceType: 'Stay',
      sourceName: location,
      sourceTimeRange: TimeRange(
        start: stay.checkinDateTime ?? DateTime.now(),
        end: stay.checkoutDateTime ?? DateTime.now(),
      ),
    );
  }

  /// Creates a conflict source for a sight being edited
  factory ConflictSource.fromSight(SightFacade sight) {
    final name = sight.name.isNotEmpty ? sight.name : 'Sight visit';
    final visitTime = sight.visitTime ?? DateTime.now();
    return ConflictSource(
      sourceType: 'Sight',
      sourceName: name,
      sourceTimeRange: TimeRange(
        start: visitTime,
        end: visitTime.add(const Duration(minutes: 30)),
      ),
    );
  }

  /// Creates a conflict source from any TripEntity
  factory ConflictSource.fromEntity(TripEntity entity) {
    if (entity is TransitFacade) {
      return ConflictSource.fromTransit(entity);
    } else if (entity is LodgingFacade) {
      return ConflictSource.fromStay(entity);
    } else if (entity is SightFacade) {
      return ConflictSource.fromSight(entity);
    }
    return ConflictSource(
      sourceType: 'Entity',
      sourceName: entity.id ?? 'Unknown',
      sourceTimeRange: TimeRange(start: DateTime.now(), end: DateTime.now()),
    );
  }
}

/// Base class for entity changes
abstract class EntityChangeBase<T extends TripEntity> {
  final T original;
  T modified;
  ChangeAction _action;

  /// Source of this conflict - what entity caused it
  final ConflictSource? conflictSource;

  /// Whether times were auto-clamped to resolve conflict
  final bool isClamped;

  EntityChangeBase({
    required this.original,
    required this.modified,
    ChangeAction action = ChangeAction.update,
    this.conflictSource,
    this.isClamped = false,
  }) : _action = action;

  bool get isUpdate => _action == ChangeAction.update;

  bool get isDelete => _action == ChangeAction.delete;

  bool get isMarkedForDeletion => _action == ChangeAction.delete;

  /// A conflict is resolved if it's clamped OR marked for deletion
  bool get isResolved => isClamped || isMarkedForDeletion;

  void markForDeletion() => _action = ChangeAction.delete;

  void restore() => _action = ChangeAction.update;
}

/// Change for entities with date/time conflicts (stays, transits, sights)
class DateTimeChange<T extends TripEntity> extends EntityChangeBase<T> {
  /// Position relative to reference time range
  final EntityTimelinePosition? timelinePosition;

  DateTimeChange.forDeletion({
    required T original,
    this.timelinePosition,
    ConflictSource? conflictSource,
  }) : super(
          original: original,
          modified: original,
          action: ChangeAction.delete,
          conflictSource: conflictSource,
          isClamped: false,
        );

  DateTimeChange.forClamping({
    required super.original,
    required super.modified,
    this.timelinePosition,
    ConflictSource? conflictSource,
  }) : super(
          action: ChangeAction.update,
          conflictSource: conflictSource,
          isClamped: true,
        );
}

/// Change for expense split updates (when contributors change)
class ExpenseSplitChange extends EntityChangeBase<ExpenseBearingTripEntity> {
  /// Whether to include new contributors in splitBy for this expense
  bool includeInSplitBy;

  ExpenseSplitChange({
    required super.original,
    required super.modified,
    this.includeInSplitBy = false,
  });
}

/// Type aliases for cleaner API
typedef StayChange = DateTimeChange<LodgingFacade>;
typedef TransitChange = DateTimeChange<TransitFacade>;
typedef SightChange = DateTimeChange<SightFacade>;
typedef EntityChange<T extends TripEntity> = DateTimeChange<T>;
