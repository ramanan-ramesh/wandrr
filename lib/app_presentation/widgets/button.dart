import 'package:flutter/material.dart';

class HoverableDeleteButton extends StatefulWidget {
  VoidCallback callBack;

  HoverableDeleteButton({super.key, required this.callBack});

  @override
  State<HoverableDeleteButton> createState() => HoverableDeleteButtonState();
}

class HoverableDeleteButtonState extends State<HoverableDeleteButton> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: InkWell(
        onTap: null,
        splashFactory: NoSplash.splashFactory,
        child: IconButton(
          icon: Icon(Icons.delete_rounded),
          color: _isHovered ? Colors.black : Colors.white,
          onPressed: () {
            widget.callBack();
          },
        ),
      ),
    );
  }
}

class PlatformSubmitterFAB extends StatefulWidget {
  final IconData icon;
  final BuildContext context;
  final VoidCallback? callback;
  VoidCallback? validationFailureCallback;
  VoidCallback? validationSuccessCallback;
  final Color? iconColor;
  GlobalKey<FormState>? formState;
  bool isSubmitted;
  ValueNotifier<bool>? valueNotifier;
  bool isConditionallyVisible;
  bool isEnabledInitially;

  PlatformSubmitterFAB(
      {super.key,
      required this.icon,
      required this.context,
      this.iconColor,
      this.callback,
      this.isSubmitted = false,
      this.isEnabledInitially = false})
      : isConditionallyVisible = false;

  PlatformSubmitterFAB.form(
      {super.key,
      required this.icon,
      required this.context,
      this.iconColor,
      this.callback,
      this.formState,
      this.validationFailureCallback,
      this.validationSuccessCallback,
      this.isSubmitted = false,
      this.isEnabledInitially = false})
      : isConditionallyVisible = false;

  PlatformSubmitterFAB.conditionallyEnabled(
      {super.key,
      required this.icon,
      required this.context,
      this.iconColor,
      this.callback,
      this.formState,
      this.validationFailureCallback,
      this.validationSuccessCallback,
      required ValueNotifier<bool> this.valueNotifier,
      this.isSubmitted = false,
      this.isConditionallyVisible = false,
      this.isEnabledInitially = false});

  @override
  State<PlatformSubmitterFAB> createState() => _PlatformSubmitterFABState();
}

class _PlatformSubmitterFABState extends State<PlatformSubmitterFAB> {
  bool get _isCallbackNull => widget.formState != null
      ? (widget.validationSuccessCallback == null)
      : widget.callback == null;

  @override
  Widget build(BuildContext context) {
    if (widget.valueNotifier != null) {
      return ValueListenableBuilder(
        valueListenable: widget.valueNotifier!,
        builder: (BuildContext context, bool value, Widget? child) {
          if (widget.isConditionallyVisible) {
            return Visibility(
              visible: value,
              child: _buildFloatingActionButton(value),
            );
          }
          return _buildFloatingActionButton(value);
        },
      );
    }
    return _buildFloatingActionButton(
        !_isCallbackNull && widget.isEnabledInitially);
  }

  FloatingActionButton _buildFloatingActionButton(bool canEnable) {
    return FloatingActionButton(
      onPressed: widget.isSubmitted || !canEnable ? () {} : _onPressed,
      splashColor: !canEnable ? Colors.white30 : null,
      backgroundColor: !canEnable ? Colors.white10 : null,
      child:
          widget.isSubmitted ? CircularProgressIndicator() : Icon(widget.icon),
    );
  }

  void _onPressed() {
    if (_isCallbackNull) {
      return;
    }
    if (widget.formState != null) {
      if (widget.formState!.currentState != null) {
        if (widget.formState!.currentState!.validate()) {
          widget.validationSuccessCallback?.call();
        } else {
          widget.validationFailureCallback?.call();
          widget.isSubmitted = false;
          setState(() {});
        }
      }
      return;
    }
    setState(() {
      widget.isSubmitted = true;
      widget.callback!();
    });
  }
}
