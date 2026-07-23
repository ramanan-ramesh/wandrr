import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'constants.dart';

ThemeData createDarkThemeData(BuildContext context) {
  final textTheme = AppTypography.textTheme(AppColors.darkColorScheme);
  return ThemeData(
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: AppColors.darkColorScheme,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.brandPrimaryLight),
      trackColor: WidgetStateProperty.all(AppColors.neutral700),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor:
            const WidgetStatePropertyAll(AppColors.brandPrimaryLight),
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
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: Colors.white,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.neutral100,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
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
        side: const BorderSide(
          color: AppColors.brandPrimaryLight,
          width: 2.0,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurfaceHeader,
      // More pronounced, lighter dark shade
      foregroundColor: Colors.white,
      elevation: 6,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.hardEdge,
      color: AppColors.darkSurface,
      // Explicit color for better contrast
      elevation: 10,
      // Match light theme elevation
      shadowColor: AppColors.withOpacity(Colors.black, 0.5),
      shape: const RoundedRectangleBorder(
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
        iconColor: const WidgetStatePropertyAll(AppColors.brandSecondary),
        backgroundColor:
            const WidgetStatePropertyAll(AppColors.brandPrimaryLight),
        foregroundColor: const WidgetStatePropertyAll(AppColors.brandSecondary),
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
        gradient: const LinearGradient(
          colors: [AppColors.brandPrimaryLight, AppColors.brandAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: textTheme.titleSmall?.copyWith(
        color: AppColors.brandSecondary,
      ),
      unselectedLabelStyle: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.neutral400,
      ),
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
        backgroundColor: const WidgetStatePropertyAll(AppColors.darkSurface),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: AppColors.neutral500,
      ),
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.neutral600,
          width: 1.5,
        ),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.neutral600,
          width: 1.5,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.brandPrimaryLight,
          width: 2,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.errorLight,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
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
