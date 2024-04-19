import 'package:flutter/material.dart';

import 'login_page.dart';
import 'onboarding_page.dart';

class StartupPage extends StatefulWidget {
  StartupPage({Key? key}) : super(key: key);

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool _shouldNavigateToLoginScreen = false;

  Widget _buildLayoutForBigScreen(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OnBoardingPage(),
        ),
        const Expanded(child: LoginPage())
      ],
    );
  }

  Widget _performLayout(BuildContext context, BoxConstraints constraints) {
    if (constraints.minWidth > 1000) {
      return SingleChildScrollView(
        child: Container(
            constraints: BoxConstraints(
                minWidth: constraints.minWidth,
                maxWidth: constraints.maxWidth,
                minHeight:
                    constraints.minHeight < 600 ? 600 : constraints.minHeight,
                maxHeight:
                    constraints.maxHeight < 600 ? 600 : constraints.maxHeight),
            child: _buildLayoutForBigScreen(context)),
      );
    } else {
      var pageToRender = _shouldNavigateToLoginScreen
          ? LoginPage()
          : OnBoardingPage(
              loginCallback: () {
                setState(() {
                  _shouldNavigateToLoginScreen = true;
                });
              },
            );
      return SingleChildScrollView(
        child: Container(
            constraints: BoxConstraints(
                minWidth: 550,
                maxWidth: 550,
                minHeight:
                    constraints.minHeight < 600 ? 600 : constraints.minHeight,
                maxHeight:
                    constraints.maxHeight < 600 ? 600 : constraints.maxHeight),
            child: pageToRender),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return _performLayout(context, constraints);
    });
  }
}
