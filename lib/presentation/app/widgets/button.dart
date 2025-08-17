import 'package:flutter/material.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/bloc/bloc_extensions.dart';
import 'package:wandrr/presentation/app/bloc/master_page_events.dart';

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
      {super.key,
      required this.icon,
      required this.context,
      this.isElevationRequired = true,
      this.callback,
      this.isSubmitted = false,
      this.isEnabledInitially = false})
      : isConditionallyVisible = false;

  PlatformSubmitterFAB.form(
      {super.key,
      required this.icon,
      required this.context,
      this.isElevationRequired = true,
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
      this.isElevationRequired = true,
      this.callback,
      this.formState,
      this.validationFailureCallback,
      this.validationSuccessCallback,
      required ValueNotifier<bool> this.valueNotifier,
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
              if (widget.callbackOnClickWhileDisabled != null) {
                widget.callbackOnClickWhileDisabled!();
              }
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

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key});

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  List<Widget> _buildLanguageButtons() {
    return context.appDataRepository.languageMetadatas
        .map((e) => _LanguageButton(
            languageMetadata: e,
            visible: _isExpanded,
            onLanguageSelected: _toggleExpand))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._buildLanguageButtons().map((e) => Container(
              padding: const EdgeInsets.all(4),
              child: e,
            )),
        FloatingActionButton.large(
          onPressed: _toggleExpand,
          child: const Icon(
            Icons.translate,
            size: 75,
          ),
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final VoidCallback onLanguageSelected;

  const _LanguageButton(
      {required LanguageMetadata languageMetadata,
      required bool visible,
      required this.onLanguageSelected})
      : _languageMetadata = languageMetadata,
        _visible = visible;

  final LanguageMetadata _languageMetadata;
  final bool _visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: _visible,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            curve: Curves.fastOutSlowIn,
            opacity: _visible ? 1 : 0,
            child: FloatingActionButton.extended(
              onPressed: () {
                onLanguageSelected();
                context.addMasterPageEvent(ChangeLanguage(
                    languageToChangeTo: _languageMetadata.locale));
              },
              label: Text(
                _languageMetadata.name,
                style: const TextStyle(fontSize: 16.0),
              ),
              icon: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: Image.asset(
                  _languageMetadata.flagAssetLocation,
                  width: 35,
                  height: 35,
                  fit: BoxFit.fill,
                ),
              ),
            )));
  }
}
