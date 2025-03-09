import 'package:flutter/material.dart';

import 'constants.dart';

ThemeData createDarkThemeData(BuildContext context) {
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
        surface: Colors.grey.shade800,
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
      backgroundColor: Colors.grey.shade700,
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
        color: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Constants.cardBorderRadius),
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
        borderRadius: BorderRadius.circular(Constants.tabIndicatorRadius),
        border: Border.all(color: Colors.green),
      ),
      indicatorColor: Colors.green,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: Theme.of(context).textTheme.headlineMedium,
      unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
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
      fillColor: Colors.grey.shade600,
      floatingLabelStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(Constants.cardBorderRadius)),
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
      //TODO: Convert these to suit DatePickerTheme's needs
      dayStyle: TextStyle(
        color: Colors.white,
      ),
    ),
  );
}
