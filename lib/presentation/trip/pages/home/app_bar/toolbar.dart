import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/app/bloc.dart';
import 'package:wandrr/blocs/app/events.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
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

  final MenuController _menuController = MenuController();

  @override
  void dispose() {
    _settingsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: Offset(0, 7),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          !context.isLightTheme ? AppColors.darkSurface : null,
        ),
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
          style: context.isLightTheme
              ? ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(AppColors.brandSecondary),
                )
              : null,
          icon: RotationTransition(
            turns:
                Tween<double>(begin: 0, end: 1).animate(_settingsTurnAnimation),
            child: Icon(
              Icons.settings,
            ),
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
      animationDurationMs: 500,
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
      animationDurationMs: 400,
      child: _LanguageSubmenu(),
    );
  }

  _MenuItem _createThemeSwitcherMenuEntry(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    return _MenuItem(
      animationDurationMs: 300,
      child: MenuItemButton(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(onSurfaceColor),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              context.appDataRepository.activeThemeMode == ThemeMode.light
                  ? Icons.brightness_6
                  : Icons.brightness_6_outlined,
              color: onSurfaceColor,
            ),
            const SizedBox(width: 12),
            Text(context.localizations.darkTheme),
            const Spacer(),
            Switch.adaptive(
              value: !context.isLightTheme,
              onChanged: (bool value) {
                context.addMasterPageEvent(ChangeTheme(
                    themeModeToChangeTo:
                        value ? ThemeMode.dark : ThemeMode.light));
              },
            ),
          ],
        ),
      ),
    );
  }

  _MenuItem _createDeleteTripMenuEntry(BuildContext context) {
    return _MenuItem(
      animationDurationMs: 200,
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _menuController.open());
  }

  void _closeMenuAfterFrame() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _menuController.close());
  }

  void _toggleMainMenu() {
    _settingsAnimationController.forward(from: 0.0);
    if (_menuController.isOpen) {
      _closeMenuAfterFrame();
    } else {
      _openMenuAfterFrame();
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.animationDurationMs,
    required this.child,
  });

  final int animationDurationMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: animationDurationMs),
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
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          !context.isLightTheme ? AppColors.darkSurface : null,
        ),
        alignment: Alignment.centerRight,
        elevation: WidgetStatePropertyAll<double>(14),
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
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
            children: List<Widget>.generate(
              languageMetadatas.length,
              (index) => _LanguageSubMenuEntry(
                  languageMetadata: languageMetadatas.elementAt(index),
                  index: index),
            ),
          ),
        )
      ],
    );
  }
}

class _LanguageSubMenuEntry extends StatelessWidget {
  const _LanguageSubMenuEntry({
    required this.languageMetadata,
    required this.index,
  });

  final LanguageMetadata languageMetadata;
  final int index;

  @override
  Widget build(BuildContext context) {
    var masterPageBloc = context.read<MasterPageBloc>();
    final delay = Duration(milliseconds: 100 * index);
    final isCurrentLocale =
        Localizations.localeOf(context).languageCode == languageMetadata.locale;
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        final shouldAnimate = snapshot.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: shouldAnimate ? 1 : 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: child,
            ),
          ),
          child: Directionality(
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
              style: isCurrentLocale
                  ? ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll<Color>(
                          Theme.of(context).colorScheme.primary.withValues(
                              alpha: context.isLightTheme ? 0.7 : 0.4)),
                    )
                  : null,
              onPressed: () {
                masterPageBloc.add(ChangeLanguage(
                    languageToChangeTo: languageMetadata.locale));
              },
              child: Text(languageMetadata.name),
            ),
          ),
        );
      },
    );
  }
}
