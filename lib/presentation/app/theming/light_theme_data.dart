import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/theming/constants.dart';

ThemeData createLightThemeData(BuildContext context) {
  return ThemeData(
    brightness: Brightness.light,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: AppColors.lightColorScheme,
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.brandPrimary),
      trackColor: WidgetStateProperty.all(AppColors.neutral300),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.brandPrimary),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors
                .brandSecondary; // Both text and icon use this when disabled
          }
          return Colors.white;
        }),
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.brandSecondary;
          }
          return Colors.white;
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
      backgroundColor: AppColors.neutral400, // Pale mint for strong contrast
      elevation: 12, // Increased elevation for better prominence
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
        side: BorderSide(
          color: AppColors.neutral200, // Subtle border for definition
          width: 1,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ThemeConstants.cardBorderRadius),
        ),
      ),
      elevation: 10,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brandPrimary,
      circularTrackColor: AppColors.neutral300,
    ),
    listTileTheme: ListTileThemeData(
      tileColor: AppColors.neutral200,
      textColor: AppColors.brandSecondary,
      iconColor: AppColors.brandPrimary,
      selectedTileColor: AppColors.brandPrimary.withValues(alpha: 0.85),
      selectedColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppColors.brandPrimary,
          width: 2.0,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.hardEdge,
      color: AppColors.brandPrimaryLight,
      // Vibrant light emerald for cards
      elevation: 10,
      // Even higher elevation for more shadow
      shadowColor: AppColors.withOpacity(AppColors.brandSecondary, 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius),
        ),
        side: BorderSide(
          color: AppColors.neutral500,
          width: 2,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.neutral400,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(Colors.white),
        backgroundColor: WidgetStatePropertyAll(AppColors.brandPrimary),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.brandSecondary),
    // Dark charcoal for better contrast
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.brandSecondary,
      // Dark charcoal background
      foregroundColor: Colors.white,
      elevation: 6,
      // Higher elevation for better visibility
      focusElevation: 8,
      hoverElevation: 8,
      splashColor: AppColors.withOpacity(Colors.white, 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.brandPrimary, // Green border for contrast
          width: 2,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(ThemeConstants.tabIndicatorRadius),
        gradient: AppColors.brandGradient,
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      unselectedLabelStyle: Theme.of(context).textTheme.headlineMedium,
      indicatorColor: Colors.transparent,
      unselectedLabelColor: AppColors.neutral600,
      labelColor: Colors.white,
      dividerColor: AppColors.neutral300,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.brandPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: AppColors.withOpacity(AppColors.brandPrimaryDark, 0.22),
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.brandPrimary,
      selectionColor: AppColors.withOpacity(AppColors.brandPrimary, 0.3),
      selectionHandleColor: AppColors.brandPrimary,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.lightSurface),
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
      fillColor: AppColors.lightSurfaceVariant,
      floatingLabelStyle: TextStyle(
        color: AppColors.brandSecondary,
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
          color: AppColors.neutral600,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(ThemeConstants.cardBorderRadius / 2),
        ),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      iconColor: AppColors.brandPrimary,
      prefixIconColor: AppColors.brandPrimary,
      suffixIconColor: AppColors.brandPrimary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandPrimary;
        }
        return AppColors.neutral200;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.brandPrimaryLight;
        }
        return AppColors.neutral400;
      }),
      overlayColor: WidgetStateProperty.all(
          AppColors.brandPrimary.withValues(alpha: 0.08)),
      splashRadius: 18,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      mouseCursor: WidgetStateMouseCursor.clickable,
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check, size: 14, color: Colors.white);
        }
        return null;
      }),
      // Add a slight shadow to the thumb for a modern look
    ),
  );
}
