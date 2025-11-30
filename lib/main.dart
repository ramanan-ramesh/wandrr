import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/app/pages/master_page/master_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  var sharedPreferences = await SharedPreferences.getInstance();
  runApp(MasterPage(sharedPreferences));
}
