import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

class TripVisitTracker {
  static const String _visitCountPrefix = 'trip_visit_count_';

  static Future<void> recordVisit(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_visitCountPrefix$tripId';
    final currentCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentCount + 1);
  }

  static Future<int> getVisitCount(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_visitCountPrefix$tripId';
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> deleteVisitCount(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_visitCountPrefix$tripId';
    await prefs.remove(key);
  }

  static Future<TripMetadataFacade?> getMostVisitedTrip(
      Iterable<TripMetadataFacade> trips) async {
    if (trips.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    TripMetadataFacade? mostVisited;
    int maxVisits = -1;

    for (final trip in trips) {
      if (trip.id == null) continue;
      final key = '$_visitCountPrefix${trip.id}';
      final visits = prefs.getInt(key) ?? 0;
      if (visits > maxVisits) {
        maxVisits = visits;
        mostVisited = trip;
      }
    }

    return mostVisited;
  }
}
