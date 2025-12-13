import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
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
      bool isPhone = false;
      bool isTablet = false;

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
          if (name == 'phone') isPhone = true;
          if (name == 'tablet') isTablet = true;
        }
      });

      // Create device-specific subdirectory
      final Directory deviceDir =
          Directory('${screenshotDir.path}/$folderName');
      if (!await deviceDir.exists()) {
        await deviceDir.create(recursive: true);
      }

      // Post-process: overlay screenshot onto device frame
      List<int> finalImageBytes = screenshotBytes;

      if (isPhone || isTablet) {
        try {
          finalImageBytes = await _overlayScreenshotOnFrame(
            screenshotBytes,
            isPhone: isPhone,
          );
          print('Successfully processed screenshot with device frame');
        } catch (e) {
          print('Error processing screenshot: $e');
          print('Saving original screenshot without frame');
        }
      }

      final File imageFile = File('${deviceDir.path}/$cleanFileName.png');
      await imageFile.writeAsBytes(finalImageBytes);

      print('Saved screenshot to: ${imageFile.path}');
      return true;
    },
  );
}

/// Overlays a screenshot onto a device frame image
///
/// Phone specs: Frame 1198x2539, Screenshot 1080x2337
/// Tablet specs: Frame 2798x1837, Screenshot 2560x1600
Future<List<int>> _overlayScreenshotOnFrame(
  List<int> screenshotBytes, {
  required bool isPhone,
}) async {
  // Load the screenshot
  final screenshotUint8List = Uint8List.fromList(screenshotBytes);
  final screenshot = img.decodeImage(screenshotUint8List);
  if (screenshot == null) {
    throw Exception('Failed to decode screenshot');
  }

  // Load the appropriate device frame
  final framePath = isPhone
      ? 'integration_test/screenshot_capturer/phone_frame.png'
      : 'integration_test/screenshot_capturer/tablet_frame.png';

  final frameFile = File(framePath);
  if (!await frameFile.exists()) {
    throw Exception('Device frame not found at: $framePath');
  }

  final frameBytes = await frameFile.readAsBytes();
  final frame = img.decodeImage(frameBytes);
  if (frame == null) {
    throw Exception('Failed to decode device frame');
  }

  // Calculate position to center the screenshot on the frame
  // Phone: Frame 1198x2539, Screenshot 1080x2337
  // Tablet: Frame 2798x1837, Screenshot 2560x1600
  final int offsetX;
  final int offsetY;

  if (isPhone) {
    // Phone frame dimensions: 1198x2539, screenshot: 1080x2337
    offsetX = (1198 - 1080) ~/ 2; // Center horizontally
    offsetY = (2539 - 2337) ~/ 2; // Center vertically
  } else {
    // Tablet frame dimensions: 2798x1837, screenshot: 2560x1600
    offsetX = (2798 - 2560) ~/ 2; // Center horizontally
    offsetY = (1837 - 1600) ~/ 2; // Center vertically
  }

  // Composite the screenshot onto the frame
  final composite = img.compositeImage(
    frame,
    screenshot,
    dstX: offsetX,
    dstY: offsetY,
  );

  // Encode the final image as PNG
  final finalBytes = img.encodePng(composite);
  return finalBytes;
}
