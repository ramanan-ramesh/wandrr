/// Pure conflict detection logic for the data layer.
///
/// This module contains only pure logic - no UI concerns or message building.
/// All message building and UI-related concerns belong in the presentation layer.
///
/// Key components:
/// - [TimeRange] - Value object representing a time range with conflict detection helpers
/// - [TimelineAnalyzer] - Pure logic for analyzing temporal relationships
/// - [EntityTimeClamper] - Pure logic for clamping entity times to resolve conflicts
/// - [ConflictResult] - Raw conflict data without UI-specific information
/// - [TripConflictScanner] - Service for scanning trip data for conflicts

export 'conflict_result.dart';
export 'entity_conflict_detectors.dart';
export 'entity_time_clamper.dart';
export 'time_range.dart';
export 'timeline_analyzer.dart';
export 'trip_conflict_scanner.dart';
