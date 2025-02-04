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
  static const _tabIndicatorRadius = 25.0;
  static const _cardBorderRadius = 25.0;

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
          theme: _createLightThemeData(context),
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
      colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.grey.shade900,
          onPrimary: Colors.white,
          secondary: Colors.black,
          onSecondary: Colors.green,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white10,
          onSurface: Colors.white),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.green),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.black),
          foregroundColor: WidgetStatePropertyAll(Colors.green),
          iconColor: WidgetStatePropertyAll(Colors.black),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.grey.shade800,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.green),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.grey.shade900,
        textColor: Colors.green,
        iconColor: Colors.green,
        selectedTileColor: Colors.black,
        selectedColor: Colors.green,
      ),
      cardTheme: CardTheme(
        data: CardThemeData(
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardBorderRadius),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white,
        indent: 20,
        endIndent: 20,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStatePropertyAll(Colors.black),
          backgroundColor: WidgetStatePropertyAll(Colors.green),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
        ),
      ),
      iconTheme: IconThemeData(color: Colors.green),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        splashColor: Colors.grey,
        backgroundColor: Colors.black,
        foregroundColor: Colors.green,
      ),
      tabBarTheme: TabBarTheme(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(_tabIndicatorRadius),
          border: Border.all(color: Colors.green),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: Theme.of(context).textTheme.headlineMedium,
        unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
        indicatorColor: Colors.green,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
      ),
      appBarTheme: AppBarTheme(
        color: Colors.teal,
        foregroundColor: Colors.black,
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.black),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
              Colors.grey.shade800), //TODO: Not working in TransitOptionPicker
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          fontStyle: FontStyle.italic,
        ),
        filled: true,
        fillColor: Colors.grey.shade700,
        floatingLabelStyle: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_cardBorderRadius)),
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        iconColor: Colors.green,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStatePropertyAll(Colors.green),
        thumbColor: WidgetStatePropertyAll(Colors.black),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.grey.shade800,
        /*
        dayTextStyle: TextStyle(
                      color: isLightTheme ? Colors.black : Colors.white),
                  selectedDayHighlightColor: Colors.green,
                  selectedDayTextStyle: TextStyle(color: Colors.black),
                  selectedRangeHighlightColor: Colors.green,
                  selectedRangeDayTextStyle: TextStyle(color: Colors.black),
                  todayTextStyle: TextStyle(color: Colors.white),
                  okButtonTextStyle: TextStyle(color: Colors.black),
                  cancelButtonTextStyle: TextStyle(color: Colors.black),
                  cancelButton: IgnorePointer(
                    child: IconButton(
                      onPressed: null,
                      icon: Icon(Icons.cancel_rounded),
                    ),
                  ),
                  okButton: IgnorePointer(
                    child: IconButton(
                      onPressed: null,
                      icon: Icon(Icons.done_rounded),
                    ),
                  ),
         */
        //Convert these to suit DatePickerTheme's needs
        dayStyle: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  ThemeData _createLightThemeData(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.teal.shade400,
          onPrimary: Colors.black,
          secondary: Colors.green,
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.teal.shade200,
          //Scaffold background color
          onSurface: Colors.black),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.green),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.green),
          foregroundColor: WidgetStatePropertyAll(Colors.black),
          //TODO: Is this the right way to set text color? Note: TextStyle(color: Colors.black) doesn't work, so how else to theme the color?
          iconColor: WidgetStatePropertyAll(Colors.black),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.teal.shade300,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: Colors.black),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.teal.shade300,
        textColor: Colors.black,
        iconColor: Colors.black,
        selectedTileColor: Colors.teal,
        selectedColor: Colors.black,
      ),
      cardTheme: CardTheme(
        data: CardThemeData(
          color: Colors.teal.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardBorderRadius),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black,
        indent: 20,
        endIndent: 20,
      ),
      popupMenuTheme: PopupMenuThemeData(),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          iconColor: WidgetStatePropertyAll(Colors.black),
          backgroundColor: WidgetStatePropertyAll(Colors.green),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
        ),
      ),
      iconTheme: IconThemeData(color: Colors.black),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        splashColor: Colors.grey,
        backgroundColor: Colors.green,
        foregroundColor: Colors.black,
      ),
      tabBarTheme: TabBarTheme(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(_tabIndicatorRadius),
          border: Border.all(color: Colors.black),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: Theme.of(context).textTheme.headlineMedium,
        unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
        indicatorColor: Colors.teal,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        color: Colors.teal,
        foregroundColor: Colors.black,
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.black),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.teal.shade300),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          fontStyle: FontStyle.italic,
        ),
        filled: true,
        fillColor: Colors.teal.shade200,
        floatingLabelStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(_cardBorderRadius)),
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        iconColor: Colors.black,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStatePropertyAll(Colors.green),
        thumbColor: WidgetStatePropertyAll(Colors.black),
      ),
    );
  }
}
