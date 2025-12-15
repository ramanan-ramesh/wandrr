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

  print('Screenshot dimensions: ${screenshot.width}x${screenshot.height}');

  // Define expected screenshot dimensions for each device type
  final expectedWidth = isPhone ? 1080 : 2560;
  final expectedHeight = isPhone ? 2337 : 1600;

  // Check if screenshot needs to be resized to match expected dimensions
  img.Image finalScreenshot = screenshot;
  if (screenshot.width != expectedWidth ||
      screenshot.height != expectedHeight) {
    print(
        'Warning: Screenshot dimensions (${screenshot.width}x${screenshot.height}) '
        'do not match expected ($expectedWidth x$expectedHeight)');
    print('Resizing screenshot to fit frame...');
    finalScreenshot = img.copyResize(
      screenshot,
      width: expectedWidth,
      height: expectedHeight,
      interpolation: img.Interpolation.linear,
    );
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

  print('Frame dimensions: ${frame.width}x${frame.height}');

  // Calculate position to place the screenshot on the frame
  // Phone: Frame 1198x2539, Screenshot 1080x2337
  // Tablet: Frame 2798x1837, Screenshot 2560x1600
  final int offsetX;
  final int offsetY;

  if (isPhone) {
    // Phone frame dimensions: 1198x2539
    // Expected screenshot: ~1080x2337
    // The frame has bezels and a notch. The screen area is NOT centered due to the notch.

    // Horizontal: center the screenshot
    offsetX = (frame.width - finalScreenshot.width) ~/ 2;

    // Vertical positioning:
    // For phone frames with notches, the screen area typically starts below the notch
    // and the top bezel is thicker than the bottom bezel.
    // With 202px total space, if top bezel is ~117px and bottom is ~85px,
    // the screen content area starts at offsetY = 117.
    // This positions the screenshot below the notch area.
    offsetY = 117;

    print(
        'Phone positioning: notch-adjusted with offsets ($offsetX, $offsetY)');
  } else {
    // Tablet frame dimensions: 2798x1837, screenshot: 2560x1600
    offsetX = (frame.width - finalScreenshot.width) ~/ 2; // Center horizontally
    offsetY = (frame.height - finalScreenshot.height) ~/ 2; // Center vertically

    print('Tablet positioning: centered with offsets ($offsetX, $offsetY)');
  }

  print('Positioning screenshot at offset: ($offsetX, $offsetY)');

  // Composite the screenshot onto the frame
  final composite = img.compositeImage(
    frame,
    finalScreenshot,
    dstX: offsetX,
    dstY: offsetY,
  );

  // Encode the final image as PNG
  final finalBytes = img.encodePng(composite);
  return finalBytes;
}
