import 'package:aligned_dialog/aligned_dialog.dart' as alignedDialog;
import 'package:flutter/material.dart';

class PlatformDialogElements {
  static void showAlignedDialog(
      {double width = 200,
      required BuildContext context,
      Function(dynamic)? onDialogResult,
      required Widget Function(BuildContext context) widgetBuilder,
      required GlobalKey widgetKey}) {
    if (widgetKey.currentContext == null) {
      return;
    }
    RenderBox renderBox =
        widgetKey.currentContext!.findRenderObject() as RenderBox;
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
}
