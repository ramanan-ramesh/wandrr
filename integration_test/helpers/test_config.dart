/// Test configuration and constants
class TestConfig {
  // Test user credentials
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'testPassword123';
  static const String testUserId = 'test_user_id';
  static const String testUserDisplayName = 'Test User';

  // Test trip data
  static const String testTripId = 'test_trip_id';
  static const String testTripName = 'Test Trip to Paris';
  static const String testTripThumbnail = 'roadTrip';
  static const String testTripCurrency = 'INR';
  static const double testTripBudget = 50000.0;

  // Timeout durations
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration loadingAnimationDuration = Duration(seconds: 2);

  // Screen size breakpoints
  static const double bigLayoutBreakpoint = 1000.0;
  static const double mediumLayoutBreakpoint = 600.0;

  // Test data
  static Map<String, dynamic> getTestUserData() {
    return {
      'uid': testUserId,
      'email': testEmail,
      'displayName': testUserDisplayName,
      'createdAt': DateTime.now().toIso8601String(),
      'preferences': {
        'language': 'en',
        'themeMode': 'system',
      },
    };
  }

  static Map<String, dynamic> getTestTripData() {
    final now = DateTime.now();
    final startDate = now.add(const Duration(days: 30));
    final endDate = startDate.add(const Duration(days: 7));

    return {
      'id': testTripId,
      'name': testTripName,
      'thumbnail': testTripThumbnail,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': {
        'amount': testTripBudget,
        'currency': testTripCurrency,
      },
      'userId': testUserId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'itinerary': [],
      'expenses': [],
    };
  }

  static List<Map<String, dynamic>> getTestTripsData() {
    return [
      getTestTripData(),
      {
        ...getTestTripData(),
        'id': 'test_trip_2',
        'name': 'Beach Vacation',
        'thumbnail': 'beach',
      },
    ];
  }

  // Feature flags for tests
  static const bool enableFirebaseMocks = true;
  static const bool enableNetworkMocks = true;
  static const bool skipAnimations = false;

  // Supported languages for testing
  static const List<String> supportedLanguages = ['en', 'hi', 'ta'];

  // Supported currencies for testing
  static const List<String> supportedCurrencies = ['INR', 'USD', 'EUR', 'GBP'];

  // Widget keys for testing
  static const String loginSubmitButtonKey = 'login_submit_button';
  static const String planTripButtonKey = 'plan_trip_button';
  static const String tripListViewKey = 'trip_list_view';
  static const String itineraryNavigatorKey = 'itinerary_navigator';
  static const String budgetingPageKey = 'budgeting_page';
}
