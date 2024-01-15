import 'package:flutter/material.dart';

import 'layouts/master_page.dart';

void main() async {
  //for shared_prefs and firebase to work?
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WandrrApp());
}

class WandrrApp extends StatelessWidget {
  const WandrrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MasterPage();
  }
}
