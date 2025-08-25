import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rive/rive.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/blocs/app/master_page_bloc.dart';
import 'package:wandrr/blocs/app/master_page_states.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/auth/models/status.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/app/theming/dark_theme_data.dart';
import 'package:wandrr/presentation/app/theming/light_theme_data.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider/trip_provider.dart';

class MasterPage extends StatelessWidget {
  const MasterPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<MasterPageBloc>(
        create: (context) => MasterPageBloc(),
        child: const _ContentPageRouter(),
      );
}

class _ContentPageRouter extends StatefulWidget {
  const _ContentPageRouter();

  @override
  State<_ContentPageRouter> createState() => _MasterContentPageLoader();
}

class _MasterContentPageLoader extends State<_ContentPageRouter> {
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
      buildWhen: (previousState, currentState) =>
          previousState != currentState && currentState is LoadedRepository ||
          currentState is Loading,
      listener: (BuildContext context, MasterPageState state) {
        if (state is Loading) {
          _tryStartWalkAnimation();
        }
      },
    );
  }

  Widget _createAnimatedLoadingScreen(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            RiveAnimation.asset(
              Assets.walkAnimation,
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

  void _tryStartWalkAnimation() {
    _hasMinimumWalkAnimationTimePassed = false;
    Future.delayed(_minimumWalkAnimationTime, () {
      if (mounted) {
        setState(() {
          _hasMinimumWalkAnimationTimePassed = true;
        });
      }
    });
  }
}

class _ContentPage extends StatelessWidget {
  static const String _appTitle = 'Wandrr';

  const _ContentPage();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MasterPageBloc, MasterPageState>(
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
        buildWhen: (previousState, currentState) =>
            currentState is ActiveLanguageChanged ||
            currentState is ActiveThemeModeChanged ||
            (currentState is AuthStateChanged &&
                (currentState.authStatus == AuthStatus.loggedIn ||
                    currentState.authStatus == AuthStatus.loggedOut)),
        listener: (BuildContext context, MasterPageState state) {},
      );
}
