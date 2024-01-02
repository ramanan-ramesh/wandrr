import 'package:flutter/material.dart';

import 'login_page.dart';
import 'onboarding_page.dart';

class StartupPage extends StatelessWidget {
  const StartupPage({Key? key}) : super(key: key);

  Widget _buildLayoutForBigScreen(
      BuildContext context, BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
          child: OnBoardingPage(),
        ),
        const Expanded(child: LoginPage())
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        color: Colors.white,
        child: _buildLayoutForBigScreen(context, constraints),
      );
    });
  }
}
