import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/blocs/app/bloc.dart';
import 'package:wandrr/blocs/app/states.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/auth/models/status.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/routing/app_router.dart';
import 'package:wandrr/presentation/app/theming/dark_theme_data.dart';
import 'package:wandrr/presentation/app/theming/light_theme_data.dart';

import 'update_dialog.dart';

class MasterPage extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  const MasterPage(this.sharedPreferences);

  @override
  Widget build(BuildContext context) => BlocProvider<MasterPageBloc>(
        create: (context) => MasterPageBloc(sharedPreferences),
        child: RepositoryProvider<AppDataFacade>(
          create: (BuildContext context) =>
              (BlocProvider.of<MasterPageBloc>(context).state
                      as LoadedRepository)
                  .appData,
          child: _ContentPageRouter(),
        ),
      );
}

class _ContentPageRouter extends StatefulWidget {
  const _ContentPageRouter();

  @override
  State<_ContentPageRouter> createState() => _ContentPageLoader();
}

class _ContentPageLoader extends State<_ContentPageRouter> {
  static const String _appTitle = 'Wandrr';
  AppRouter? _appRouter;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MasterPageBloc, MasterPageState>(
      builder: (BuildContext pageContext, MasterPageState state) {
        var appLevelData = context.appDataRepository;
        var currentTheme = appLevelData.activeThemeMode;

        // Initialize router lazily with app data repository
        _appRouter ??= AppRouter(appDataRepository: appLevelData);

        return MaterialApp.router(
          routerConfig: _appRouter!.router,
          locale: Locale(appLevelData.activeLanguage),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          title: _appTitle,
          debugShowCheckedModeBanner: false,
          darkTheme: createDarkThemeData(context),
          themeMode: currentTheme,
          theme: createLightThemeData(context),
        );
      },
      buildWhen: (previousState, currentState) =>
          currentState is ActiveLanguageChanged ||
          currentState is ActiveThemeModeChanged,
      listener: _handleAuthStateChange,
    );
  }

  void _handleAuthStateChange(BuildContext context, MasterPageState state) {
    if (state is AuthStateChanged) {
      if (state.authStatus == AuthStatus.loggedIn) {
        _appRouter?.router.go(AppRoutes.trips);
      } else if (state.authStatus == AuthStatus.loggedOut) {
        _appRouter?.router.go(AppRoutes.root);
      }
    } else if (state is UpdateAvailable) {
      _showUpdateDialog(context, state);
    }
  }

  void _showUpdateDialog(BuildContext context, UpdateAvailable state) {
    showDialog(
      context: context,
      barrierDismissible: !state.updateInfo.isForceUpdate,
      builder: (BuildContext dialogContext) {
        return UpdateDialog(
          updateInfo: state.updateInfo,
        );
      },
    );
  }
}
