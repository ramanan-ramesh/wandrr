class NavigationSections {
  static const String tripOverview = 'trip_overview';
  static const String itinerary = 'itinerary';
  static const String lodging = 'lodging';
  static const String transit = 'transit';
  static const String budgeting = 'budgeting';
}

class NavAnimationDurations {
  static const Duration navigateToSection = Duration(milliseconds: 1000);
  static const Duration delayedTripEntitySectionOpen =
      Duration(milliseconds: 1250);

  static const Duration delayedNavigateToDateInSection =
      Duration(milliseconds: 500);
}
