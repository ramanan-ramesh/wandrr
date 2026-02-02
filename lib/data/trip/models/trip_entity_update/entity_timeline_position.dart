/// Represents the temporal relationship between an entity and a reference time range.
/// Used for both TripMetadata updates (entity vs new trip dates) and
/// timeline conflict resolution (entity vs edited entity times).
enum EntityTimelinePosition {
  /// Entity's time is completely before the reference time range
  beforeEvent,

  /// Entity's time overlaps with the start boundary of the reference time range
  overlapWithStartBoundary,

  /// Entity's time is completely contained within the reference time range
  duringEvent,

  /// Entity's time overlaps with the end boundary of the reference time range
  overlapWithEndBoundary,

  /// Entity's time is completely after the reference time range
  afterEvent,

  /// Entity's time exactly matches a boundary (checkin == checkout, departure == arrival)
  exactBoundaryMatch,
}
