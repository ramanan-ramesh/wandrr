import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class PlatformSubmitterFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback? callback;
  final VoidCallback? validationFailureCallback;
  final VoidCallback? validationSuccessCallback;
  final GlobalKey<FormState>? formState;
  final bool isSubmitted;
  final ValueNotifier<bool>? valueNotifier;
  final bool isConditionallyVisible;
  final bool isEnabledInitially;
  final VoidCallback? callbackOnClickWhileDisabled;
  final bool isElevationRequired;
  final Duration minimumLoadingDuration;

  const PlatformSubmitterFAB({
    required this.icon,
    super.key,
    this.isElevationRequired = true,
    this.callback,
    this.isSubmitted = false,
    this.isEnabledInitially = false,
    this.minimumLoadingDuration = const Duration(milliseconds: 1500),
    this.callbackOnClickWhileDisabled,
  })  : isConditionallyVisible = false,
        valueNotifier = null,
        formState = null,
        validationFailureCallback = null,
        validationSuccessCallback = null;

  const PlatformSubmitterFAB.form({
    required this.icon,
    super.key,
    this.isElevationRequired = true,
    this.callback,
    this.formState,
    this.validationFailureCallback,
    this.validationSuccessCallback,
    this.isSubmitted = false,
    this.isEnabledInitially = false,
    this.minimumLoadingDuration = const Duration(milliseconds: 1500),
    this.callbackOnClickWhileDisabled,
  })  : isConditionallyVisible = false,
        valueNotifier = null;

  const PlatformSubmitterFAB.conditionallyEnabled({
    required this.icon,
    required this.valueNotifier,
    super.key,
    this.isElevationRequired = true,
    this.callback,
    this.formState,
    this.validationFailureCallback,
    this.validationSuccessCallback,
    this.isSubmitted = false,
    this.isConditionallyVisible = false,
    this.callbackOnClickWhileDisabled,
    this.isEnabledInitially = false,
    this.minimumLoadingDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<PlatformSubmitterFAB> createState() => _PlatformSubmitterFABState();
}

class _PlatformSubmitterFABState extends State<PlatformSubmitterFAB> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isSubmitted;
  }

  @override
  void didUpdateWidget(PlatformSubmitterFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to original state when widget rebuilds unless explicitly submitted
    if (!widget.isSubmitted && _isLoading) {
      _setLoadingState(false);
    }
  }

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
    return _buildFloatingActionButton(_isEnabled);
  }

  FloatingActionButton _buildFloatingActionButton(bool canEnable) {
    var isLightTheme = context.isLightTheme;
    final bool isButtonEnabled = canEnable && !_isLoading;

    return FloatingActionButton(
      onPressed: _isLoading || !canEnable
          ? () {
              widget.callbackOnClickWhileDisabled?.call();
            }
          : _onPressed,
      elevation: widget.isElevationRequired
          ? Theme.of(context).floatingActionButtonTheme.elevation
          : 0,
      splashColor: !isButtonEnabled
          ? (isLightTheme
              ? AppColors.neutral400
              : AppColors.withOpacity(AppColors.neutral100, 0.3))
          : null,
      backgroundColor: !isButtonEnabled
          ? (isLightTheme ? AppColors.neutral500 : AppColors.neutral700)
          : null,
      child: _isLoading ? const CircularProgressIndicator() : Icon(widget.icon),
    );
  }

  void _setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  bool get _isCallbackNull => widget.formState != null
      ? (widget.validationSuccessCallback == null)
      : widget.callback == null;

  bool get _isEnabled {
    if (widget.valueNotifier != null) {
      return widget.valueNotifier!.value;
    }
    return !_isCallbackNull && widget.isEnabledInitially;
  }

  Future<void> _onPressed() async {
    if (_isCallbackNull || _isLoading) {
      return;
    }

    // Start loading state
    _setLoadingState(true);

    // Start the minimum duration timer
    final minimumDurationFuture = Future.delayed(widget.minimumLoadingDuration);

    try {
      if (widget.formState != null) {
        if (widget.formState!.currentState != null) {
          if (widget.formState!.currentState!.validate()) {
            widget.validationSuccessCallback?.call();

            await minimumDurationFuture;
          } else {
            widget.validationFailureCallback?.call();
            await minimumDurationFuture;
          }
        }
      } else {
        widget.callback?.call();
        await minimumDurationFuture;
      }
    } finally {
      if (mounted) {
        _setLoadingState(false);
      }
    }
  }
}
