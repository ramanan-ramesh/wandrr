import 'package:flutter/material.dart';
import 'package:wandrr/app_data/models/app_level_data.dart';
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';

import 'login_page.dart';
import 'onboarding_page.dart';

class StartupPage extends StatefulWidget {
  StartupPage({Key? key}) : super(key: key);

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool _shouldNavigateToLoginScreen = false;
  static const _cutOffSize = 600.0;
  static const _smallScreenSize = 550.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        BoxConstraints constraintsToApply;
        Widget pageToRender;
        double minHeight = constraints.minHeight < _cutOffSize
            ? _cutOffSize
            : constraints.minHeight;
        double maxHeight = constraints.maxHeight < _cutOffSize
            ? _cutOffSize
            : constraints.maxHeight;
        var appLevelData = context.getAppLevelData() as AppLevelDataModifier;
        if (constraints.minWidth > 1000) {
          constraintsToApply = BoxConstraints(
              minWidth: constraints.minWidth,
              maxWidth: constraints.maxWidth,
              minHeight: minHeight,
              maxHeight: maxHeight);
          appLevelData.updateLayoutType(true);
          pageToRender = _getPageToRender(true);
        } else {
          appLevelData.updateLayoutType(false);
          pageToRender = _getPageToRender(false);
          constraintsToApply = BoxConstraints(
              minWidth: _smallScreenSize,
              maxWidth: _smallScreenSize,
              minHeight: minHeight,
              maxHeight: maxHeight);
        }
        return SingleChildScrollView(
          child:
              Container(constraints: constraintsToApply, child: pageToRender),
        );
      },
    );
  }

  Widget _getPageToRender(bool isBigLayout) {
    if (isBigLayout) {
      return Row(
        children: [
          Expanded(
            child: OnBoardingPage(),
          ),
          const Expanded(child: LoginPage())
        ],
      );
    }

    return _shouldNavigateToLoginScreen
        ? LoginPage()
        : OnBoardingPage(
            onNavigateToNextPage: () {
              setState(() {
                _shouldNavigateToLoginScreen = true;
              });
            },
          );
  }
}
