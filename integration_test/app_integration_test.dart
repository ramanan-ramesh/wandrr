import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/firebase_emulator_helper.dart';
import 'tests/authentication/authentication_comprehensive_test.dart' as auth;
import 'tests/budgeting/budgeting_page_test.dart' as budgeting;
import 'tests/conflict_detection_test.dart' as conflict_detection;
import 'tests/crud_operations/crud_operations_test.dart' as crud;
import 'tests/home_page_test.dart' as home;
import 'tests/itinerary_viewer/itinerary_viewer_test.dart' as itinerary;
import 'tests/multi_collaborator_test.dart' as multi_collaborator;
import 'tests/startup_page_test.dart' as startup;
import 'tests/trip_editor_page_test.dart' as trip_editor;
import 'tests/trip_metadata_update_test.dart' as trip_metadata;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Wandrr Travel Planner Integration Tests', () {
    late SharedPreferences sharedPreferences;

    setUpAll(() async {
      sharedPreferences = await SharedPreferences.getInstance();
      SharedPreferences.setMockInitialValues({});
      await sharedPreferences.clear();
      try {
        await Firebase.initializeApp();
      } on Exception catch (e) {
        print('Firebase already initialized or initialization skipped: $e');
      }
      await FirebaseEmulatorHelper.configureEmulators();
      print('✓ Firebase emulators configured for integration tests');
    });

    tearDownAll(() async {
      FirebaseEmulatorHelper.reset();
      SharedPreferences.setMockInitialValues({});
      await sharedPreferences.clear();
    });

    group('Startup Page Tests', startup.runTests);

    group('Authentication & Firestore - UserManagement Tests', auth.runTests);

    group('Home Page Tests', home.runTests);

    group('Trip Editor Page Tests', trip_editor.runTests);

    group('Itinerary Viewer Tests', itinerary.runTests);

    group('Budgeting Page Tests', budgeting.runTests);

    group('TripEntity CRUD Tests', crud.runTests);

    group('Multi-Collaborator Tests', multi_collaborator.runTests);

    group('Trip Metadata Update Tests', trip_metadata.runTests);

    group('Conflict Detection Tests', conflict_detection.runTests);
  });
}
