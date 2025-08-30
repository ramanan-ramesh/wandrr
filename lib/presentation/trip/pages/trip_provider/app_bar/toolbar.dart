import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/app/master_page_bloc.dart';
import 'package:wandrr/blocs/app/master_page_events.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';
import 'package:wandrr/presentation/trip/widgets/delete_trip_dialog.dart';

class Toolbar extends StatefulWidget {
  const Toolbar({super.key});

  @override
  State<Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<Toolbar> with TickerProviderStateMixin {
  late final AnimationController _settingsAnimationController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 280));
  late final Animation<double> _settingsTurnAnimation = CurvedAnimation(
      parent: _settingsAnimationController, curve: Curves.easeOut);

  late final _MenuControllerWrapper _mainMenuWrapper;

  @override
  void initState() {
    super.initState();
    _mainMenuWrapper = _MenuControllerWrapper();
  }

  @override
  void dispose() {
    _settingsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _mainMenuWrapper.controller,
      alignmentOffset: Offset(0, 7),
      style: const MenuStyle(
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(vertical: 6)),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15))),
        ),
      ),
      onClose: () {
        _settingsAnimationController.forward(from: 0.0);
      },
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: _toggleMainMenu,
          icon: RotationTransition(
            turns:
                Tween<double>(begin: 0, end: 1).animate(_settingsTurnAnimation),
            child: const Icon(Icons.settings),
          ),
        );
      },
      menuChildren: <Widget>[
        if (context.tripRepository.activeTrip != null)
          _createDeleteTripMenuEntry(context),
        _createThemeSwitcherMenuEntry(context),
        _createLanguageSwitcherMenuEntry(),
        _createLogoutMenuEntry(context),
      ],
    );
  }

  _MenuItem _createLogoutMenuEntry(BuildContext context) {
    return _MenuItem(
      milliseconds: 500,
      child: MenuItemButton(
        leadingIcon: const Icon(Icons.logout),
        onPressed: () {
          context.addMasterPageEvent(Logout());
        },
        child: Text(context.localizations.logout),
      ),
    );
  }

  _MenuItem _createLanguageSwitcherMenuEntry() {
    return _MenuItem(
      milliseconds: 400,
      child: _LanguageSubmenu(),
    );
  }

  _MenuItem _createThemeSwitcherMenuEntry(BuildContext context) {
    return _MenuItem(
      milliseconds: 300,
      child: MenuItemButton(
        child: Row(
          children: <Widget>[
            Icon(context.appDataRepository.activeThemeMode == ThemeMode.light
                ? Icons.brightness_6
                : Icons.brightness_6_outlined),
            const SizedBox(width: 12),
            Text(context.localizations.darkTheme),
            const Spacer(),
            Switch.adaptive(
              value: !context.isLightTheme,
              onChanged: (bool value) {
                context.addMasterPageEvent(ChangeTheme(
                    themeModeToChangeTo:
                        value ? ThemeMode.dark : ThemeMode.light));
                _closeMenuAfterFrame();
              },
            ),
          ],
        ),
      ),
    );
  }

  _MenuItem _createDeleteTripMenuEntry(BuildContext context) {
    return _MenuItem(
      milliseconds: 200,
      child: MenuItemButton(
        leadingIcon: Icon(Icons.delete_rounded),
        child: Text(context.localizations.deleteTrip),
        onPressed: () {
          var tripMetadataToDelete = context.activeTrip.tripMetadata;
          PlatformDialogElements.showAlertDialog(context, (dialogContext) {
            return DeleteTripDialog(
                widgetContext: context,
                tripMetadataFacade: tripMetadataToDelete);
          });
        },
      ),
    );
  }

  void _openMenuAfterFrame() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _mainMenuWrapper.open());
  }

  void _closeMenuAfterFrame() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _mainMenuWrapper.close());
  }

  void _toggleMainMenu() {
    _settingsAnimationController.forward(from: 0.0);
    if (_mainMenuWrapper.isOpen) {
      _closeMenuAfterFrame();
    } else {
      _openMenuAfterFrame();
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.milliseconds,
    required this.child,
  });

  final int milliseconds;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOut,
      builder: (BuildContext context, double t, Widget? _) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.95 + 0.05 * t, child: child),
      ),
    );
  }
}

class _LanguageSubmenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var languageMetadatas = context.appDataRepository.languageMetadatas;
    return SubmenuButton(
      menuStyle: const MenuStyle(
        alignment: Alignment.centerRight,
        elevation: WidgetStatePropertyAll<double>(14),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
      ),
      leadingIcon: const Icon(Icons.translate),
      child: Text(context.localizations.language),
      menuChildren: <Widget>[
        Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languageMetadatas
                .map((languageMetadata) =>
                    _createLanguageEntry(languageMetadata, context))
                .toList(),
          ),
        )
      ],
    );
  }

  Widget _createLanguageEntry(
      LanguageMetadata languageMetadata, BuildContext context) {
    var masterPageBloc = context.read<MasterPageBloc>();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MenuItemButton(
        leadingIcon: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Image.asset(
            languageMetadata.flagAssetLocation,
            width: 35,
            height: 35,
            fit: BoxFit.fill,
          ),
        ),
        onPressed: () {
          masterPageBloc
              .add(ChangeLanguage(languageToChangeTo: languageMetadata.locale));
        },
        child: Text(languageMetadata.name),
      ),
    );
  }
}

class _MenuControllerWrapper {
  final MenuController _internalController = MenuController();

  _MenuControllerWrapper();

  MenuController get controller => _internalController;

  void open() => _internalController.open();

  bool get isOpen => _internalController.isOpen;

  void close() {
    _internalController.close();
  }
}
