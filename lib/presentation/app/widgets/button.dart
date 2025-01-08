import 'package:flutter/material.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/presentation/app/blocs/bloc_extensions.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_events.dart';

class PlatformTabBar extends StatefulWidget {
  final Map<String, Widget> tabBarItems;
  static const double _roundedCornerRadius = 25.0;
  TabController? tabController;
  double? maxTabViewHeight;

  PlatformTabBar(
      {super.key,
      required this.tabBarItems,
      this.tabController,
      this.maxTabViewHeight});

  @override
  State<PlatformTabBar> createState() => _PlatformTabBarState();
}

class _PlatformTabBarState extends State<PlatformTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = widget.tabController ??
        TabController(length: widget.tabBarItems.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _createTabBar(context),
          const SizedBox(height: 16.0),
          Flexible(
            child: Container(
              constraints: widget.maxTabViewHeight == null
                  ? null
                  : BoxConstraints(maxHeight: widget.maxTabViewHeight!),
              child: Center(
                child: TabBarView(
                  controller: _tabController,
                  children: widget.tabBarItems.values.toList(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _createTabBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PlatformTabBar._roundedCornerRadius),
      clipBehavior: Clip.hardEdge,
      child: TabBar(
        controller: _tabController,
        tabs: widget.tabBarItems.keys
            .map((tabTitle) => FittedBox(child: Tab(text: tabTitle)))
            .toList(),
      ),
    );
  }
}

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
  VoidCallback? callbackOnClickWhileDisabled;

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
    var isLightTheme =
        context.appDataRepository.activeThemeMode == ThemeMode.light;
    return FloatingActionButton(
      onPressed: widget.isSubmitted || !canEnable
          ? () {
              if (widget.callbackOnClickWhileDisabled != null) {
                widget.callbackOnClickWhileDisabled!();
              }
            }
          : _onPressed,
      splashColor: !canEnable
          ? (isLightTheme ? Colors.grey.shade400 : Colors.white30)
          : null,
      backgroundColor:
          !canEnable ? (isLightTheme ? Colors.grey : Colors.white10) : null,
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

class LanguageSwitcher extends StatefulWidget {
  LanguageSwitcher({super.key});

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
          child: Icon(
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
