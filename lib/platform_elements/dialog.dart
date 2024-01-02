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
    double distanceFromLeft = widgetPosition.dx;
    double distanceFromTop = widgetPosition.dy;
    double distanceFromRight = screenSize.width - widgetPosition.dx;
    double distanceFromBottom = screenSize.height - widgetPosition.dy;

    var widgetToScreenBottomDistance =
        (distanceFromBottom - widgetSize.height).abs();
    if (widgetToScreenBottomDistance >= distanceFromTop) {
      alignedDialog
          .showAlignedDialog(
        context: context,
        builder: widgetBuilder,
        followerAnchor: Alignment.topLeft,
        targetAnchor: Alignment.bottomLeft,
        barrierColor: Colors.transparent,
      )
          .then((value) {
        if (onDialogResult != null) {
          onDialogResult(value);
        }
      });
    } else {
      alignedDialog
          .showAlignedDialog(
        context: context,
        builder: widgetBuilder,
        followerAnchor: Alignment.bottomLeft,
        targetAnchor: Alignment.topLeft,
        barrierColor: Colors.transparent,
      )
          .then((value) {
        if (onDialogResult != null) {
          onDialogResult(value);
        }
      });
    }
  }
}
