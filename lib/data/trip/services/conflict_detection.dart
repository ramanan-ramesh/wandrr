/// Conflict detection for timeline entities.
///
/// This module provides two layers of conflict detection:
///
/// **Pure Logic Layer** (in `conflict_detection/` subfolder):
// ///    - [TimeRange] - Value object for time ranges
// ///    - [TimelineAnalyzer] - Pure logic for analyzing temporal relationships
// ///    - [EntityTimeClamper] - Pure logic for clamping entity times
// ///    - [ConflictResult] - Raw conflict data
// ///    - [TripConflictScanner] - Service for scanning trip data for conflicts
///
/// For new implementations, prefer using [EntityConflictCoordinator] from the
/// presentation layer which provides a cleaner API.

// Pure conflict detection logic
export 'conflict_detection/conflict_detection.dart';
