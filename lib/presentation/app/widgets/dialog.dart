import 'dart:ui';

import 'package:aligned_dialog/aligned_dialog.dart' as alignedDialog;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as routes show showGeneralDialog;

class PlatformDialogElements {
  static void showAlignedDialog(
      {double width = 200,
      required BuildContext context,
      Function(dynamic)? onDialogResult,
      required Widget Function(BuildContext context) widgetBuilder}) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset widgetPosition = renderBox.localToGlobal(Offset.zero);

    var widgetSize = renderBox.size;
    Size screenSize = MediaQuery.of(context).size;
    double distanceOfWidgetTopFromScreenTop = widgetPosition.dy;
    double distanceOfWidgetBottomFromScreenBottom =
        screenSize.height - widgetPosition.dy;
    double distanceOfWidgetEndFromScreenEnd =
        screenSize.width - (widgetPosition.dx + widgetSize.width);
    double distanceOfWidgetStartFromScreenStart = widgetPosition.dx;
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
    alignedDialog
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
    )
        .then((value) {
      if (onDialogResult != null) {
        onDialogResult(value);
      }
    });
  }

  static void showGeneralDialog(
      BuildContext scaffoldContext, Widget dialogContent,
      {bool isDismissible = false}) {
    routes.showGeneralDialog(
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
    );
  }

  static void showAlertDialog(
      BuildContext scaffoldContext, WidgetBuilder dialogContentCreator,
      {bool isDismissible = false}) {
    routes.showGeneralDialog(
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
    );
  }
}
