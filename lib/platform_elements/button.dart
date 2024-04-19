import 'package:flutter/material.dart';

class PlatformButtonElements {
  static Widget createExtendedFAB(
      {required IconData iconData,
      required String text,
      required BuildContext context,
      VoidCallback? onPressed,
      bool enabled = true}) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.black,
      onPressed: onPressed,
      icon: Icon(
        iconData,
        color: Colors.white,
      ),
      label: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  static Widget createTextButtonWithIcon(
      {required String text,
      required IconData iconData,
      required BuildContext context,
      Key? key,
      VoidCallback? onPressed}) {
    return TextButton.icon(
      key: key,
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) return Colors.black;
            if (states.contains(MaterialState.pressed)) return Colors.black;
            return Colors.white24;
          },
        ),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) return Colors.white24;
            if (states.contains(MaterialState.pressed)) return Colors.white24;
            return Colors.transparent;
          },
        ),
        splashFactory: NoSplash.splashFactory,
      ),
      onPressed: onPressed,
      icon: Icon(
        iconData,
      ),
      label: Text(
        text,
      ),
    );
  }

  static Widget createFAB(
      {required IconData icon,
      required BuildContext context,
      VoidCallback? callback}) {
    return FloatingActionButton(
      // backgroundColor: Colors.black,
      onPressed: callback,
      child: Icon(
        icon,
        // color: Colors.white,
      ),
    );
  }
}

class PlatformSubmitterFAB extends StatefulWidget {
  final IconData icon;
  final BuildContext context;
  final Color? backgroundColor;
  final VoidCallback? callback;

  PlatformSubmitterFAB(
      {super.key,
      required this.icon,
      required this.context,
      this.backgroundColor,
      this.callback});

  @override
  State<PlatformSubmitterFAB> createState() => _PlatformSubmitterFABState();
}

class _PlatformSubmitterFABState extends State<PlatformSubmitterFAB> {
  var _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: widget.backgroundColor,
      onPressed: _isSubmitted
          ? null
          : () {
              if (widget.callback != null && !_isSubmitted) {
                widget.callback!();
                setState(() {
                  _isSubmitted = true;
                });
              }
            },
      child: _isSubmitted
          ? CircularProgressIndicator()
          : Icon(
              widget.icon,
              color: Colors.white,
            ),
    );
  }
}
