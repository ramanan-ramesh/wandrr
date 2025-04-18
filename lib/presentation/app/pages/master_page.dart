import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rive/rive.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_bloc.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_states.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/app/theming/dark_theme_data.dart';
import 'package:wandrr/presentation/app/theming/light_theme_data.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider.dart';

class MasterPage extends StatelessWidget {
  const MasterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MasterPageBloc>(
      create: (context) => MasterPageBloc(),
      child: const _MasterContentPageRouter(),
    );
  }
}

class _MasterContentPageRouter extends StatefulWidget {
  const _MasterContentPageRouter();

  @override
  State<_MasterContentPageRouter> createState() => _MasterContentPageLoader();
}

class _MasterContentPageLoader extends State<_MasterContentPageRouter> {
  var _hasMinimumWalkAnimationTimePassed = false;
  static const _minimumWalkAnimationTime = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    if (BlocProvider.of<MasterPageBloc>(context).state is Loading) {
      if (!_hasMinimumWalkAnimationTimePassed) {
        _tryStartWalkAnimation();
      }
    }
    return BlocConsumer<MasterPageBloc, MasterPageState>(
      builder: (BuildContext context, MasterPageState state) {
        if (state is LoadedRepository && _hasMinimumWalkAnimationTimePassed) {
          return RepositoryProvider<AppDataFacade>(
            create: (BuildContext context) => state.appData,
            child: const _ContentPage(),
          );
        }
        return _createAnimatedLoadingScreen(context);
      },
      buildWhen: (previousState, currentState) {
        return previousState != currentState &&
                currentState is LoadedRepository ||
            currentState is Loading;
      },
      listener: (BuildContext context, MasterPageState state) {
        if (state is Loading) {
          _tryStartWalkAnimation();
        }
      },
    );
  }

  Widget _createAnimatedLoadingScreen(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          RiveAnimation.asset(
            'assets/walk_animation.riv',
            fit: BoxFit.fitHeight,
            controllers: [
              SimpleAnimation('Walk'),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              'Loading user data and theme',
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tryStartWalkAnimation() {
    _hasMinimumWalkAnimationTimePassed = false;
    Future.delayed(_minimumWalkAnimationTime, () {
      setState(() {
        _hasMinimumWalkAnimationTimePassed = true;
      });
    });
  }
}

class _ContentPage extends StatelessWidget {
  static const String _appTitle = 'Wandrr';

  const _ContentPage();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MasterPageBloc, MasterPageState>(
      builder: (BuildContext context, MasterPageState state) {
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
          home: Material(
            child: DropdownButtonHideUnderline(
              child: SafeArea(
                child: context.activeUser == null
                    ? const StartupPage()
                    : const TripProvider(),
              ),
            ),
          ),
        );
      },
      buildWhen: (previousState, currentState) {
        return currentState is ActiveLanguageChanged ||
            currentState is ActiveThemeModeChanged ||
            currentState is ActiveUserChanged;
      },
      listener: (BuildContext context, MasterPageState state) {},
    );
  }
}
