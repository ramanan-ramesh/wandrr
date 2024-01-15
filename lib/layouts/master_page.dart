import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_states.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';

import 'startup_page.dart';
import 'trip_provider/trip_provider.dart';

class MasterPage extends StatelessWidget {
  MasterPage({Key? key}) : super(key: key);
  static const String _appTitle = 'Wandrr';

  PlatformDataRepository? _platformDataRepository;

  Widget _buildContentPage(MasterPageState masterPageState) {
    if (masterPageState is Startup) {
      var activeUser = masterPageState.appLevelData.activeUser;
      if (activeUser == null) {
        return StartupPage();
      } else {
        return TripProvider();
      }
    } else if (masterPageState is ActiveUserChanged) {
      if (masterPageState.user != null) {
        return TripProvider();
      } else {
        return StartupPage();
      }
    }

    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PlatformDataRepository.create(),
      initialData: _platformDataRepository,
      builder: (BuildContext context,
          AsyncSnapshot<PlatformDataRepository> snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return _buildMasterPage(snapshot.data!);
        } else {
          if (_platformDataRepository != null) {
            return _buildMasterPage(_platformDataRepository!);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildMasterPage(PlatformDataRepository platformDataRepository) {
    return RepositoryProvider<PlatformDataRepository>(
      create: (context) => platformDataRepository,
      child: BlocProvider<MasterPageBloc>(
        create: (context) => MasterPageBloc(
            platformDataRepository:
                RepositoryProvider.of<PlatformDataRepository>(context)),
        child: BlocConsumer<MasterPageBloc, MasterPageState>(
          listener: (context, state) {},
          builder: (context, state) {
            print('builder of masterpage called for state-${state}');
            return MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              title: _appTitle,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
              ),
              themeMode: ThemeMode.dark,
              home: Material(child: _buildContentPage(state)),
            );
          },
        ),
      ),
    );
  }
}
