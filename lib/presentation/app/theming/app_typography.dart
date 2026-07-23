import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography for Wandrr.
///
/// Two font families are used to give the app a fun, adventurous, yet
/// easy-to-read voice:
/// - "Baloo 2": a friendly, rounded display face used for headings, titles
///   and anything that should feel expressive (AppBar titles, dialog
///   titles, section headers, big numbers).
/// - "Nunito": a warm, highly-legible body face used for everything else
///   (list items, form fields, buttons, captions, hints).
///
/// Widgets should NEVER hardcode a [TextStyle]. Instead pick the
/// [TextTheme] role that matches the surface the text lives on:
///
/// | Surface / role                         | TextTheme role            |
/// |-----------------------------------------|----------------------------|
/// | Page/App title, big empty-state heading | displaySmall / headlineMedium |
/// | AppBar title, dialog title              | titleLarge                |
/// | Card title, section header              | titleMedium                |
/// | List item title, tab label              | titleSmall                 |
/// | Primary body copy, dialog content       | bodyLarge / bodyMedium     |
/// | List item subtitle, secondary info       | bodyMedium / bodySmall     |
/// | Button label                             | labelLarge                 |
/// | Chip / badge text                        | labelMedium                |
/// | Caption, hint, timestamp, helper text    | labelSmall / bodySmall     |
///
/// Use `Theme.of(context).textTheme.<role>` and, only when a color other
/// than the default `onSurface`/`onPrimary` is required (e.g. success,
/// error, muted), apply it via `copyWith(color: ...)` while keeping the
/// size/weight/family untouched.
class AppTypography {
  AppTypography._();

  static const String headingFontFamily = 'Baloo 2';
  static const String bodyFontFamily = 'Nunito';

  /// Builds the full [TextTheme] for the given [colorScheme].
  static TextTheme textTheme(ColorScheme colorScheme) {
    final baseBody = GoogleFonts.nunitoTextTheme();
    final baseHeading = GoogleFonts.baloo2TextTheme();

    return baseBody
        .copyWith(
          displayLarge: baseHeading.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displayMedium: baseHeading.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          displaySmall: baseHeading.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: baseHeading.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: baseHeading.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: baseHeading.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleLarge: baseHeading.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: baseHeading.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: baseHeading.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: baseBody.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: baseBody.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: baseBody.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
          labelLarge: baseBody.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: baseBody.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: baseBody.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
          decorationColor: colorScheme.onSurface,
        );
  }
}

