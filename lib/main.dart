import 'package:flutter/material.dart';

import 'layouts/master_page.dart';

void main() async {
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
