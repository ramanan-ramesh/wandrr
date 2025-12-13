import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Test driver for integration tests
///
/// This file is the entry point for running integration tests on devices/emulators.
/// It uses the integration_test_driver which handles communication between the test
/// and the app running on the device.
///
/// To run the test, use:
/// flutter drive --driver=integration_test/screenshot_capturer/driver.dart --target=integration_test/screenshot_capturer/main.dart
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes,
        [Map<String, Object?>? args]) async {
      final Directory screenshotDir = Directory('screenshots');
      if (!await screenshotDir.exists()) {
        await screenshotDir.create(recursive: true);
      }

      // Determine folder and clean filename based on prefix
      String folderName;
      String cleanFileName;

      final prefixMap = {
        'phone_': 'phone',
        'tablet_': 'tablet',
      };
      folderName = 'other';
      cleanFileName = screenshotName;
      prefixMap.forEach((prefix, name) {
        if (screenshotName.startsWith(prefix)) {
          folderName = name;
          cleanFileName = screenshotName.substring(prefix.length);
        }
      });

      // Create device-specific subdirectory
      final Directory deviceDir =
          Directory('${screenshotDir.path}/$folderName');
      if (!await deviceDir.exists()) {
        await deviceDir.create(recursive: true);
      }

      final File imageFile = File('${deviceDir.path}/$cleanFileName.png');
      await imageFile.writeAsBytes(screenshotBytes);

      print('Saved screenshot to: ${imageFile.path}');
      return true;
    },
  );
}
