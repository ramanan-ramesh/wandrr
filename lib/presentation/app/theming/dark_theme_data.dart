import 'package:flutter/material.dart';

import 'constants.dart';

ThemeData createDarkThemeData(BuildContext context) {
  return ThemeData(
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.grey.shade900,
      onPrimary: Colors.white,
      secondary: Colors.black,
      onSecondary: Colors.green,
      error: Colors.red,
      onError: Colors.white,
      surface: Colors.grey.shade700,
      onSurface: Colors.white,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(Colors.green),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.black),
        foregroundColor: WidgetStatePropertyAll(Colors.green),
        iconColor: WidgetStatePropertyAll(Colors.green),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.grey.shade800,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Colors.green),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.grey.shade900,
      textColor: Colors.green,
      iconColor: Colors.green,
      selectedTileColor: Colors.black,
      selectedColor: Colors.green,
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.hardEdge,
      color: Colors.grey.shade900,
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white,
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
    iconTheme: const IconThemeData(color: Colors.green),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      splashColor: Colors.grey,
      backgroundColor: Colors.black,
      foregroundColor: Colors.green,
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(ThemeConstants.tabIndicatorRadius),
        border: Border.all(color: Colors.green),
      ),
      indicatorColor: Colors.green,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: Theme.of(context).textTheme.headlineMedium,
      unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
    ),
    appBarTheme: const AppBarTheme(
      color: Colors.teal,
      foregroundColor: Colors.black,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
            Colors.grey.shade800), //TODO: Not working in TransitOptionPicker
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(
        fontStyle: FontStyle.italic,
      ),
      filled: true,
      fillColor: Colors.grey.shade600,
      floatingLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      border: const OutlineInputBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(ThemeConstants.cardBorderRadius)),
        borderSide: BorderSide(color: Colors.white),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.transparent),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
      iconColor: Colors.green,
    ),
    switchTheme: const SwitchThemeData(
      trackColor: WidgetStatePropertyAll(Colors.green),
      thumbColor: WidgetStatePropertyAll(Colors.black),
    ),
  );
}
