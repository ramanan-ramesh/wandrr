import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/constants.dart';

class PlatformCard extends StatelessWidget {
  Color? borderColor;
  Color? color;
  final Widget child;

  PlatformCard({super.key, this.borderColor, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
