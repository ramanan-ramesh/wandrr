import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/l10n/app_localizations.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_bloc.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_states.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/app/theming/dark_theme_data.dart';
import 'package:wandrr/presentation/app/theming/light_theme_data.dart';
import 'package:wandrr/presentation/app/widgets/shimmer.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider.dart';

class MasterPage extends StatelessWidget {
  const MasterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MasterPageBloc>(
      create: (context) => MasterPageBloc(),
      child: _MasterContentPageRouter(),
    );
  }
}

class _MasterContentPageRouter extends StatefulWidget {
  const _MasterContentPageRouter({super.key});

  @override
  State<_MasterContentPageRouter> createState() => _MasterContentPageLoader();
}

class _MasterContentPageLoader extends State<_MasterContentPageRouter> {
  var _hasMinimumShimmerTimePassed = false;
  static const _onBoardingImageAsset = 'assets/images/plan_itinerary.jpg';
  static const _minimumShimmerTime = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    if (BlocProvider.of<MasterPageBloc>(context).state is Loading) {
      if (!_hasMinimumShimmerTimePassed) {
        _tryTriggerStartAnimation();
      }
    }
    return BlocConsumer<MasterPageBloc, MasterPageState>(
      builder: (BuildContext context, MasterPageState state) {
        if (state is LoadedRepository && _hasMinimumShimmerTimePassed) {
          return RepositoryProvider<AppDataFacade>(
            create: (BuildContext context) => state.appData,
            child: _ContentPage(),
          );
        }
        return Center(
          child: Shimmer(
            child: Image(
              image: AssetImage(_onBoardingImageAsset),
              fit: BoxFit.fitHeight,
            ),
          ),
        );
      },
      buildWhen: (previousState, currentState) {
        return previousState != currentState &&
                currentState is LoadedRepository ||
            currentState is Loading;
      },
      listener: (BuildContext context, MasterPageState state) {
        if (state is Loading) {
          _tryTriggerStartAnimation();
        }
      },
    );
  }

  void _tryTriggerStartAnimation() {
    _hasMinimumShimmerTimePassed = false;
    Future.delayed(_minimumShimmerTime, () {
      setState(() {
        _hasMinimumShimmerTimePassed = true;
      });
    });
  }
}

class _ContentPage extends StatelessWidget {
  static const String _appTitle = 'Wandrr';

  const _ContentPage({super.key});

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
                child:
                    context.activeUser == null ? StartupPage() : TripProvider(),
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
