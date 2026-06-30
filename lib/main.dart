import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:wandrr/data/app/implementations/firebase_options.dart';
import 'package:wandrr/presentation/app/pages/master_page/master_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeTimezone();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  var sharedPreferences = await SharedPreferences.getInstance();
  runApp(MasterPage(sharedPreferences));
}

Future<void> _initializeTimezone() async {
  tz.initializeTimeZones();
  try {
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
  } on Exception catch (_) {
    debugPrint('Could not get the local timezone');
  }
}
