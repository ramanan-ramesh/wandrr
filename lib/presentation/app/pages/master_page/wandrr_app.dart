import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wandrr/blocs/app/bloc.dart';
import 'package:wandrr/blocs/app/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/auth/models/status.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/app/theming/dark_theme_data.dart';
import 'package:wandrr/presentation/app/theming/light_theme_data.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/trip_provider.dart';

import 'update_dialog.dart';

class WandrrApp extends StatelessWidget {
  static const String _appTitle = 'Wandrr';

  const WandrrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MasterPageBloc, MasterPageState>(
      builder: (BuildContext pageContext, MasterPageState state) {
        var appLevelData = context.appDataRepository;
        var currentTheme = appLevelData.activeThemeMode;
        return MaterialApp(
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
          home: _ContentPage(),
        );
      },
      buildWhen: (previousState, currentState) =>
          currentState is ActiveLanguageChanged ||
          currentState is ActiveThemeModeChanged,
      listener: (BuildContext context, MasterPageState state) {},
    );
  }
}

class _ContentPage extends StatelessWidget {
  const _ContentPage();

  @override
  Widget build(BuildContext context) {
    var currentBlocState = BlocProvider.of<MasterPageBloc>(context).state;
    if (currentBlocState is LoadedRepository &&
        currentBlocState.updateInfo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog(
            context, UpdateAvailable(updateInfo: currentBlocState.updateInfo!));
      });
    }
    return BlocConsumer<MasterPageBloc, MasterPageState>(
      builder: (BuildContext pageContext, MasterPageState state) => Material(
        child: DropdownButtonHideUnderline(
          child: SafeArea(
            child: context.activeUser == null
                ? const StartupPage()
                : const TripProvider(),
          ),
        ),
      ),
      buildWhen: (previousState, currentState) =>
          currentState is AuthStateChanged &&
          (currentState.authStatus == AuthStatus.loggedIn ||
              currentState.authStatus == AuthStatus.loggedOut),
      listenWhen: (previousState, currentState) =>
          currentState is UpdateAvailable,
      listener: (BuildContext context, MasterPageState state) {
        if (state is UpdateAvailable) {
          _showUpdateDialog(context, state);
        }
      },
    );
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
