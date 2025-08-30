import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';

import 'login_page.dart';
import 'onboarding/onboarding_page.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({Key? key}) : super(key: key);

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool _shouldDisplayLoginScreen = false;
  static const _cutOffSize = 600.0;
  static const _smallScreenSize = 550.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        BoxConstraints constraintsToApply;
        Widget pageToRender;
        double minHeight = max(constraints.minHeight, _cutOffSize);
        double maxHeight = max(_cutOffSize, constraints.maxHeight);
        if (constraints.minWidth > 1000) {
          constraintsToApply = BoxConstraints(
              minWidth: constraints.minWidth,
              maxWidth: constraints.maxWidth,
              minHeight: minHeight,
              maxHeight: maxHeight);
          context.isBigLayout = true;
          pageToRender = _getPageToRender(true);
        } else {
          context.isBigLayout = false;
          pageToRender = _getPageToRender(false);
          constraintsToApply = BoxConstraints(
              minWidth: _smallScreenSize,
              maxWidth: _smallScreenSize,
              minHeight: minHeight,
              maxHeight: maxHeight);
        }
        return SingleChildScrollView(
          child: Container(
            constraints: constraintsToApply,
            child: pageToRender,
          ),
        );
      },
    );
  }

  Widget _getPageToRender(bool isBigLayout) {
    if (isBigLayout) {
      return const Row(
        children: [
          Expanded(
            child: OnBoardingPage(),
          ),
          Expanded(
            child: LoginPage(),
          )
        ],
      );
    }

    return _shouldDisplayLoginScreen
        ? const LoginPage()
        : OnBoardingPage(
            onNavigateToNextPage: () {
              setState(() {
                _shouldDisplayLoginScreen = true;
              });
            },
          );
  }
}
