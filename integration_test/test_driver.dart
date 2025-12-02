import 'package:integration_test/integration_test_driver.dart';

/// Test driver for integration tests
///
/// This file is the entry point for running integration tests on devices/emulators.
/// It uses the integration_test_driver which handles communication between the test
/// and the app running on the device.
///
/// To run the test, use:
/// flutter drive --driver=integration_test/test_driver.dart --target=integration_test/app_integration_test.dart
Future<void> main() => integrationDriver();
