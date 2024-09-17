import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension DateTimeExt on DateTime {
  int calculateDaysInBetween(DateTime dateTime,
      {bool includeExtraDay = false}) {
    var startDate = DateTime(year, month, day);
    var endDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    var numberOfDaysOfTrip = startDate.difference(endDate).inDays;
    return numberOfDaysOfTrip.abs() + (includeExtraDay ? 1 : 0);
  }

  bool isOnSameDayAs(DateTime dateTime) {
    return year == dateTime.year &&
        month == dateTime.month &&
        day == dateTime.day;
  }
}

extension AppLocalizationsExt on BuildContext {
  AppLocalizations withLocale() {
    return AppLocalizations.of(this)!;
  }
}
