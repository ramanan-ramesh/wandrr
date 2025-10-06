import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  int calculateDaysInBetween(DateTime dateTime,
      {bool includeExtraDay = false}) {
    var startDate = DateTime(year, month, day);
    var endDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    var numberOfDaysOfTrip = startDate.difference(endDate).inDays;
    return numberOfDaysOfTrip.abs() + (includeExtraDay ? 1 : 0);
  }

  bool isOnSameDayAs(DateTime dateTime) =>
      year == dateTime.year && month == dateTime.month && day == dateTime.day;

  String get itineraryDateFormat =>
      DateFormat('ddMMyyyy').format(this); // 24092025
  String get dayDateMonthFormat =>
      DateFormat.MMMEd().format(this); // Wed, Sep 24
  String get monthDateYearFormat =>
      DateFormat.yMMMd().format(this); // Sep 24, 2025
  String get monthFormat => DateFormat.MMM().format(this); // Sep
  String get dayFormat => DateFormat('EEE').format(this); // Wed
  String get dateMonthFormat => DateFormat('dd MMM').format(this); // 24 Sep
  String get hourMinuteAmPmFormat =>
      DateFormat('hh:mm a').format(this); // 08:30 AM
}
