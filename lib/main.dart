import 'package:flutter/material.dart';

import 'presentation/app/pages/master_page.dart';

void main() async {
  runApp(const WandrrApp());
}

class WandrrApp extends StatelessWidget {
  const WandrrApp({super.key});

  @override
  Widget build(BuildContext context) => const MasterPage();
}
