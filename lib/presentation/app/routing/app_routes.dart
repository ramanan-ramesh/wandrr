class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String trips = '/trips';
  static const String tripEditor = '/trips/:tripId';
  static const String printTrip = '/trips/:tripId/print';

  static String tripEditorPath(String tripId) => '/trips/$tripId';

  static String printTripPath(String tripId) => '/trips/$tripId/print';
}
