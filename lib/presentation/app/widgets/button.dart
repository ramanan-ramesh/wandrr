import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';

//TODO: Refactor this class and analyze the behaviour. Keep a timer in this class after submitting, so that it takes 1.5 seconds to go from CircularProgressIndicator to Icon.
class PlatformSubmitterFAB extends StatefulWidget {
  final IconData icon;
  final BuildContext context;
  final VoidCallback? callback;
  VoidCallback? validationFailureCallback;
  VoidCallback? validationSuccessCallback;
  GlobalKey<FormState>? formState;
  bool isSubmitted;
  ValueNotifier<bool>? valueNotifier;
  final bool isConditionallyVisible;
  final bool isEnabledInitially;
  VoidCallback? callbackOnClickWhileDisabled;
  final bool isElevationRequired;

  PlatformSubmitterFAB(
      {required this.icon,
      required this.context,
      super.key,
      this.isElevationRequired = true,
      this.callback,
      this.isSubmitted = false,
      this.isEnabledInitially = false})
      : isConditionallyVisible = false;

  PlatformSubmitterFAB.form(
      {required this.icon,
      required this.context,
      super.key,
      this.isElevationRequired = true,
      this.callback,
      this.formState,
      this.validationFailureCallback,
      this.validationSuccessCallback,
      this.isSubmitted = false,
      this.isEnabledInitially = false})
      : isConditionallyVisible = false;

  PlatformSubmitterFAB.conditionallyEnabled(
      {required this.icon,
      required this.context,
      required ValueNotifier<bool> this.valueNotifier,
      super.key,
      this.isElevationRequired = true,
      this.callback,
      this.formState,
      this.validationFailureCallback,
      this.validationSuccessCallback,
      this.isSubmitted = false,
      this.isConditionallyVisible = false,
      this.callbackOnClickWhileDisabled,
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
    var isLightTheme = context.isLightTheme;
    return FloatingActionButton(
      onPressed: widget.isSubmitted || !canEnable
          ? () {
              widget.callbackOnClickWhileDisabled?.call();
            }
          : _onPressed,
      elevation: widget.isElevationRequired
          ? Theme.of(context).floatingActionButtonTheme.elevation
          : 0,
      splashColor: !canEnable
          ? (isLightTheme ? Colors.grey.shade400 : Colors.white30)
          : null,
      backgroundColor: !canEnable
          ? (isLightTheme ? Colors.grey : Colors.grey.shade700)
          : null,
      child: widget.isSubmitted
          ? const CircularProgressIndicator()
          : Icon(widget.icon),
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
          widget.isSubmitted = true;
          setState(() {});
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
