import 'package:integration_test/integration_test_driver.dart';

/// Test driver for running integration tests
///
/// This file is used when running integration tests on real devices or emulators.
///
/// To run integration tests with this driver:
/// flutter drive \
///   --driver=integration_test/driver/integration_test_driver.dart \
///   --target=integration_test/app_integration_test.dart
Future<void> main() => integrationDriver();
