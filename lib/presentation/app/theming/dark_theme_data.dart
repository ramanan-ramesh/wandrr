import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'constants.dart';

ThemeData createDarkThemeData(BuildContext context) {
  return ThemeData(
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: AppColors.darkColorScheme,
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.brandPrimaryLight),
      trackColor: WidgetStateProperty.all(AppColors.neutral700),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.brandPrimaryLight),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.neutral100; // More pronounced for disabled
          }
          return AppColors.brandSecondary;
        }),
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.neutral100; // More pronounced for disabled
          }
          return AppColors.brandSecondary;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.cardBorderRadius / 2),
          ),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeConstants.cardBorderRadius),
        ),
      ),
      elevation: 10,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brandPrimaryLight,
      circularTrackColor: AppColors.neutral600,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: AppColors.darkSurface,
      textColor: AppColors.neutral100,
      iconColor: AppColors.brandPrimaryLight,
      selectedTileColor: AppColors.brandPrimaryLight.withValues(alpha: 0.85),
      selectedColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppColors.brandPrimaryLight,
          width: 2.0,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurfaceHeader,
      // More pronounced, lighter dark shade
      foregroundColor: Colors.white,
      elevation: 6,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.hardEdge,
      color: AppColors.darkSurface,
      // Explicit color for better contrast
      elevation: 10,
      // Match light theme elevation
      shadowColor: AppColors.withOpacity(Colors.black, 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius),
        ),
        side: BorderSide(
          color: AppColors.neutral500,
          width: 2, // Match light theme border width
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.neutral600,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(AppColors.brandSecondary),
        backgroundColor: WidgetStatePropertyAll(AppColors.brandPrimaryLight),
        foregroundColor: WidgetStatePropertyAll(AppColors.brandSecondary),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.brandPrimaryLight),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.brandPrimaryLight,
      foregroundColor: AppColors.brandSecondary,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 6,
      splashColor: AppColors.withOpacity(AppColors.brandSecondary, 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(ThemeConstants.tabIndicatorRadius),
        gradient: LinearGradient(
          colors: [AppColors.brandPrimaryLight, AppColors.brandAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
      indicatorColor: Colors.transparent,
      labelColor: AppColors.brandSecondary,
      unselectedLabelColor: AppColors.neutral400,
      dividerColor: AppColors.neutral600,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.brandPrimaryLight,
      selectionColor: AppColors.withOpacity(AppColors.brandPrimaryLight, 0.3),
      selectionHandleColor: AppColors.brandPrimaryLight,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.darkSurface),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: TextStyle(
        fontStyle: FontStyle.italic,
        color: AppColors.neutral500,
      ),
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      floatingLabelStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.neutral600,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.neutral600,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.brandPrimaryLight,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.errorLight,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.errorLight,
          width: 2,
        ),
      ),
      iconColor: AppColors.brandPrimaryLight,
      prefixIconColor: AppColors.brandPrimaryLight,
      suffixIconColor: AppColors.brandPrimaryLight,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandSecondary;
        }
        return AppColors.neutral500;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandPrimaryLight;
        }
        return AppColors.neutral600;
      }),
      overlayColor: WidgetStateProperty.all(
          AppColors.brandPrimaryLight.withValues(alpha: 0.08)),
      splashRadius: 18,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      mouseCursor: WidgetStateMouseCursor.clickable,
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check, size: 14, color: Colors.white);
        }
        return null;
      }),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      color: AppColors.neutral400,
      selectedColor: AppColors.brandPrimaryLight,
      fillColor: AppColors.brandPrimaryLight.withValues(alpha: 0.15),
      splashColor: AppColors.brandPrimaryLight.withValues(alpha: 0.1),
      borderColor: AppColors.neutral600,
      selectedBorderColor: AppColors.brandPrimaryLight,
      borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius / 2),
    ),
  );
}
