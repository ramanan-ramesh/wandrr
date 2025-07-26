import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/constants.dart';

ThemeData createLightThemeData(BuildContext context) {
  return ThemeData(
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
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
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.green),
        foregroundColor: WidgetStatePropertyAll(Colors.black),
        //TODO: Is this the right way to set text color? Note: TextStyle(color: Colors.black) doesn't work, so how else to theme the color?
        iconColor: WidgetStatePropertyAll(Colors.black),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.teal.shade400,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Colors.black),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.teal.shade300,
      textColor: Colors.black,
      iconColor: Colors.black,
      selectedTileColor: Colors.teal,
      selectedColor: Colors.black,
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.hardEdge,
      color: Colors.teal.shade500,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(Constants.cardBorderRadius),
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.black,
      indent: 20,
      endIndent: 20,
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(Colors.black),
        backgroundColor: WidgetStatePropertyAll(Colors.green),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      splashColor: Colors.grey,
      backgroundColor: Colors.green,
      foregroundColor: Colors.black,
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(Constants.tabIndicatorRadius),
        border: Border.all(color: Colors.black),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: Theme.of(context).textTheme.headlineMedium,
      unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
      indicatorColor: Colors.teal,
      unselectedLabelColor: Colors.black,
      labelColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      color: Colors.teal,
      foregroundColor: Colors.black,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.teal.shade300),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(8.0),
      hintStyle: const TextStyle(
        fontStyle: FontStyle.italic,
      ),
      filled: true,
      fillColor: Colors.teal.shade200,
      floatingLabelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      border: const OutlineInputBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(Constants.cardBorderRadius)),
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      iconColor: Colors.black,
    ),
    switchTheme: const SwitchThemeData(
      trackColor: WidgetStatePropertyAll(Colors.green),
      thumbColor: WidgetStatePropertyAll(Colors.black),
    ),
  );
}
