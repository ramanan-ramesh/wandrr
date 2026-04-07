import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_timeline_position.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';

/// Action to perform on an entity
enum ChangeAction { update, delete }

/// Base class for entity changes
abstract class EntityChangeBase<T extends TripEntity> {
  final T original;
  T modified;
  ChangeAction _action;

  /// Whether times were auto-clamped to resolve conflict
  bool isClamped;

  EntityChangeBase({
    required this.original,
    required this.modified,
    ChangeAction action = ChangeAction.update,
    this.isClamped = false,
  }) : _action = action;

  bool get isUpdate => _action == ChangeAction.update;

  bool get isDelete => _action == ChangeAction.delete;

  bool get isMarkedForDeletion => _action == ChangeAction.delete;

  /// A conflict is resolved if it's clamped OR marked for deletion
  bool get isResolved => isClamped || isMarkedForDeletion;

  void markAsResolved() => isClamped = true;

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
  }) : super(
          original: original,
          modified: original,
          action: ChangeAction.delete,
          isClamped: false,
        );

  DateTimeChange.forClamping({
    required super.original,
    required super.modified,
    this.timelinePosition,
  }) : super(
          action: ChangeAction.update,
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
