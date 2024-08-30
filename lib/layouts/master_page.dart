import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_states.dart';
import 'package:wandrr/repositories/platform_data_repository.dart';

import 'startup_page.dart';
import 'trip_provider/trip_provider.dart';

class MasterPage extends StatefulWidget {
  MasterPage({Key? key}) : super(key: key);

  @override
  State<MasterPage> createState() => _MasterPageState();
}

class _MasterPageState extends State<MasterPage> {
  static const String _appTitle = 'Wandrr';

  PlatformDataRepositoryFacade? _platformDataRepository;

  MasterPageBloc? _masterPageBloc;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PlatformDataRepository.create(),
      initialData: _platformDataRepository,
      builder: (BuildContext context,
          AsyncSnapshot<PlatformDataRepositoryFacade> snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done &&
            _platformDataRepository == null) {
          _platformDataRepository = snapshot.data!;
        }
        if (_platformDataRepository != null) {
          return _buildMasterPage(_platformDataRepository!);
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  @override
  void dispose() {
    _masterPageBloc?.close();
    super.dispose();
  }

  Widget _buildMasterPage(PlatformDataRepositoryFacade platformDataRepository) {
    return RepositoryProvider<PlatformDataRepositoryFacade>(
      create: (context) => platformDataRepository,
      child: BlocProvider<MasterPageBloc>(
        create: (context) {
          if (_masterPageBloc != null) {
            return _masterPageBloc!;
          }
          _masterPageBloc = MasterPageBloc(
              platformDataRepository:
                  RepositoryProvider.of<PlatformDataRepositoryFacade>(context));
          return _masterPageBloc!;
        },
        child: BlocConsumer<MasterPageBloc, MasterPageState>(
          listener: (context, state) {},
          builder: (context, state) {
            print('builder of masterpage called for state-${state}');
            var currentTheme =
                RepositoryProvider.of<PlatformDataRepositoryFacade>(context)
                    .appData
                    .activeThemeMode;
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
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                scrollbarTheme: ScrollbarThemeData(
                  thumbColor: WidgetStateProperty.all(Colors.green),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Colors.black),
                    foregroundColor: WidgetStatePropertyAll(Colors
                        .green), //TODO: Is this the right way to set text color? Note: TextStyle(color: Colors.black) doesn't work, so how else to theme the color?
                  ),
                ),
                progressIndicatorTheme:
                    ProgressIndicatorThemeData(color: Colors.green),
                listTileTheme: ListTileThemeData(
                  tileColor: Colors.grey.shade900,
                  textColor: Colors.green,
                  iconColor: Colors.green,
                  selectedTileColor: Colors.white10,
                  selectedColor: Colors.green,
                ),
                cardTheme: CardTheme(color: Colors.grey.shade900),
                dividerTheme: DividerThemeData(
                  color: Colors.green,
                  indent: 20,
                  endIndent: 20,
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: ButtonStyle(
                    iconColor: WidgetStatePropertyAll(Colors.green),
                    backgroundColor: WidgetStatePropertyAll(Colors.black),
                    foregroundColor: WidgetStatePropertyAll(Colors.green),
                  ),
                ),
                iconTheme: IconThemeData(color: Colors.green),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  splashColor: Colors.grey,
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.green,
                ),
                tabBarTheme: TabBarTheme(
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: TextStyle(color: Colors.white),
                  indicator: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.green),
                      bottom: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                appBarTheme: AppBarTheme(
                  color: Colors.grey.shade900,
                  iconTheme: IconThemeData(
                    color: Colors.black,
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  floatingLabelStyle: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  iconColor: Colors.green,
                ),
              ),
              themeMode: currentTheme,
              home: Material(
                  child: DropdownButtonHideUnderline(
                      child: _buildContentPage(state))),
            );
          },
          buildWhen: (previousState, currentState) {
            return previousState != currentState;
          },
        ),
      ),
    );
  }

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
}
