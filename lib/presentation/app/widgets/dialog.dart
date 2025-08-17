import 'dart:async';
import 'dart:ui';

import 'package:aligned_dialog/aligned_dialog.dart' as aligned_dialog;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as routes show showGeneralDialog;

class PlatformDialogElements {
  static void showAlignedDialog(
      {required BuildContext context,
      required Widget Function(BuildContext context) widgetBuilder,
      double width = 200,
      Function(dynamic)? onDialogResult}) {
    if (!context.mounted) {
      return;
    }
    var renderBox = context.findRenderObject() as RenderBox;
    var widgetPosition = renderBox.localToGlobal(Offset.zero);

    var widgetSize = renderBox.size;
    var screenSize = MediaQuery.of(context).size;
    var distanceOfWidgetTopFromScreenTop = widgetPosition.dy;
    var distanceOfWidgetBottomFromScreenBottom =
        screenSize.height - widgetPosition.dy;
    var distanceOfWidgetEndFromScreenEnd =
        screenSize.width - (widgetPosition.dx + widgetSize.width);
    var distanceOfWidgetStartFromScreenStart = widgetPosition.dx;
    Alignment targetAnchor, followerAnchor;
    if (distanceOfWidgetTopFromScreenTop >
        distanceOfWidgetBottomFromScreenBottom) {
      if (distanceOfWidgetStartFromScreenStart >
          distanceOfWidgetEndFromScreenEnd) {
        targetAnchor = Alignment.topRight;
        followerAnchor = Alignment.bottomRight;
      } else {
        targetAnchor = Alignment.topLeft;
        followerAnchor = Alignment.bottomLeft;
      }
    } else {
      if (distanceOfWidgetStartFromScreenStart >
          distanceOfWidgetEndFromScreenEnd) {
        targetAnchor = Alignment.bottomRight;
        followerAnchor = Alignment.topRight;
      } else {
        targetAnchor = Alignment.bottomLeft;
        followerAnchor = Alignment.topLeft;
      }
    }
    unawaited(aligned_dialog
        .showAlignedDialog(
      transitionsBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: AnimatedOpacity(
          opacity: anim1.value,
          curve: Curves.easeOutBack,
          duration: const Duration(milliseconds: 1000),
          child: child,
        ),
      ),
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.8,
            ),
            child: widgetBuilder(context),
          ),
        );
      },
      followerAnchor: followerAnchor,
      targetAnchor: targetAnchor,
      barrierColor: Colors.transparent,
      avoidOverflow: true,
    )
        .then((value) {
      if (onDialogResult != null) {
        onDialogResult(value);
      }
    }));
  }

  static void showGeneralDialog(
      BuildContext scaffoldContext, Widget dialogContent,
      {bool isDismissible = false}) {
    unawaited(routes.showGeneralDialog(
      context: scaffoldContext,
      barrierDismissible: isDismissible,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Material(
          child: Dialog(
            child: dialogContent,
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
        child: AnimatedOpacity(
          opacity: anim1.value,
          curve: Curves.easeInOutBack,
          duration: const Duration(milliseconds: 500),
          child: child,
        ),
      ),
    ));
  }

  static void showAlertDialog(
      BuildContext scaffoldContext, WidgetBuilder dialogContentCreator,
      {bool isDismissible = false}) {
    unawaited(routes.showGeneralDialog(
      context: scaffoldContext,
      barrierDismissible: isDismissible,
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return Material(
          child: dialogContentCreator(context),
        );
      },
      transitionBuilder: (context, a1, a2, widget) {
        return Opacity(
          opacity: a1.value,
          child: Transform.scale(
            scale: a1.value,
            child: widget,
          ),
        );
      },
    ));
  }
}
