import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_bloc.dart';
import 'package:wandrr/presentation/app/blocs/master_page/master_page_states.dart';
import 'package:wandrr/presentation/app/pages/startup_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_provider.dart';

class MasterPage extends StatefulWidget {
  MasterPage({Key? key}) : super(key: key);

  @override
  State<MasterPage> createState() => _MasterPageState();
}

class _MasterPageState extends State<MasterPage> {
  MasterPageBloc? _masterPageBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MasterPageBloc>(
      create: (BuildContext context) {
        _masterPageBloc ??= MasterPageBloc();
        return _masterPageBloc!;
      },
      child: BlocConsumer<MasterPageBloc, MasterPageState>(
        builder: (BuildContext context, MasterPageState state) {
          if (state is LoadedRepository) {
            return RepositoryProvider<AppDataFacade>(
              create: (BuildContext context) => state.appData,
              child: _ContentPage(),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        buildWhen: (previousState, currentState) {
          return currentState is LoadedRepository || currentState is Loading;
        },
        listener: (BuildContext context, MasterPageState state) {},
      ),
    );
  }

  @override
  void dispose() {
    _masterPageBloc?.close();
    super.dispose();
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
          darkTheme: _createDarkThemeData(context),
          themeMode: currentTheme,
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

  ThemeData _createDarkThemeData(BuildContext context) {
    return ThemeData(
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
      progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.green),
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
      popupMenuTheme: PopupMenuThemeData(),
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
        labelStyle: Theme.of(context).textTheme.headlineMedium,
        unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
        indicatorColor: Colors.white10,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
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
    );
  }
}
