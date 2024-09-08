import 'package:flutter/material.dart';
import 'package:wandrr/contracts/app_level_data.dart';
import 'package:wandrr/contracts/extensions.dart';

import 'login_page.dart';
import 'onboarding_page.dart';

class StartupPage extends StatefulWidget {
  StartupPage({Key? key}) : super(key: key);

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool _shouldNavigateToLoginScreen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return _buildLayout(context, constraints);
    });
  }

  Widget _buildLayout(BuildContext context, BoxConstraints constraints) {
    BoxConstraints boxConstraints;
    Widget pageToRender;
    double minHeight =
        constraints.minHeight < 600 ? 600 : constraints.minHeight;
    double maxHeight =
        constraints.maxHeight < 600 ? 600 : constraints.maxHeight;
    var appLevelData = context.getAppLevelData() as AppLevelDataModifier;
    if (constraints.minWidth > 1000) {
      boxConstraints = BoxConstraints(
          minWidth: constraints.minWidth,
          maxWidth: constraints.maxWidth,
          minHeight: minHeight,
          maxHeight: maxHeight);
      pageToRender = _buildLayoutForBigScreen(context);
      appLevelData.updateLayoutType(true);
    } else {
      pageToRender = _shouldNavigateToLoginScreen
          ? LoginPage()
          : OnBoardingPage(
              loginCallback: () {
                setState(() {
                  _shouldNavigateToLoginScreen = true;
                });
              },
            );
      boxConstraints = BoxConstraints(
          minWidth: 550,
          maxWidth: 550,
          minHeight: minHeight,
          maxHeight: maxHeight);
      appLevelData.updateLayoutType(false);
    }
    return SingleChildScrollView(
      child: Container(constraints: boxConstraints, child: pageToRender),
    );
  }

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
}
