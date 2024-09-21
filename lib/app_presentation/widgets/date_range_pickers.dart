import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wandrr/app_data/platform_data_repository_extensions.dart';
import 'package:wandrr/app_presentation/extensions.dart';

import 'dialog.dart';

abstract class DateRangePickerData extends StatefulWidget {
  final dateFormat = intl.DateFormat.MMMEd();
  DateTime? startDate, endDate, firstDate, lastDate;
  final Function(DateTime? start, DateTime? end)? callback;

  DateRangePickerData(
      {super.key,
      this.startDate,
      this.endDate,
      this.callback,
      this.firstDate,
      this.lastDate});

  void showDateRangePickerDialog(GlobalKey widgetKey, BuildContext context,
      void Function(VoidCallback fn) setState) {
    var isBigLayout = context.isBigLayout();
    PlatformDialogElements.showAlignedDialog(
        context: context,
        widgetBuilder: (context) {
          var dateRangePickerButtonRenderBox =
              widgetKey.currentContext!.findRenderObject() as RenderBox;
          double width;
          if (isBigLayout) {
            width = 400;
          } else {
            if (dateRangePickerButtonRenderBox.size.width <= 300) {
              width = 300.0;
            } else {
              width = dateRangePickerButtonRenderBox.size.width;
            }
          }
          return SizedBox(
            width: width > 400 ? 400 : width,
            //TODO: Make this work for android, by setting a max height
            child: Material(
              elevation: 5.0,
              child: CalendarDatePicker2WithActionButtons(
                onCancelTapped: () {
                  Navigator.of(context).pop();
                },
                onOkTapped: () {
                  Navigator.of(context).pop();
                },
                config: CalendarDatePicker2WithActionButtonsConfig(
                  closeDialogOnCancelTapped: true,
                  closeDialogOnOkTapped: true,
                  firstDayOfWeek: 1,
                  calendarType: CalendarDatePicker2Type.range,
                  centerAlignModePicker: true,
                  controlsTextStyle: TextStyle(color: Colors.white),
                  dayTextStyle: TextStyle(color: Colors.white),
                  selectedDayHighlightColor: Colors.green,
                  selectedDayTextStyle: TextStyle(color: Colors.black),
                  selectedRangeHighlightColor: Colors.green,
                  selectedRangeDayTextStyle: TextStyle(color: Colors.black),
                  todayTextStyle: TextStyle(color: Colors.white),
                  okButtonTextStyle: TextStyle(color: Colors.black),
                  cancelButtonTextStyle: TextStyle(color: Colors.black),
                  cancelButton: IgnorePointer(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ),
                  okButton: IgnorePointer(
                    child: TextButton(
                      onPressed: () {},
                      child: Text('OK'),
                    ),
                  ),
                ),
                // value: _dates,
                onValueChanged: (dates) => _tryUpdateDateRange(dates, setState),
                value: [startDate, endDate],
              ),
            ),
          );
        },
        widgetKey: widgetKey);
  }

  void _tryUpdateDateRange(
      List<DateTime?> dates, void Function(VoidCallback fn) setState) {
    if (dates.length == 1) {
      startDate = dates.first;
      endDate = null;
      setState(() {
        if (callback != null) {
          callback!(startDate, endDate);
        }
      });
    }
    if (dates.length == 2) {
      startDate = dates.first;
      endDate = dates.elementAt(1);
      setState(() {
        if (callback != null) {
          callback!(startDate, endDate);
        }
      });
    }
  }
}

class PlatformDateRangePicker extends DateRangePickerData {
  PlatformDateRangePicker(
      {super.key,
      super.startDate,
      super.endDate,
      super.callback,
      super.firstDate,
      super.lastDate});

  @override
  State<PlatformDateRangePicker> createState() =>
      _PlatformDateRangePickerState();
}

class _PlatformDateRangePickerState extends State<PlatformDateRangePicker> {
  final _dateRangePickerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    //TODO: Track focus and then decide whether to overlay the date range picker
    String startDateTime = '';
    if (widget.startDate != null) {
      startDateTime = widget.dateFormat.format(widget.startDate!);
    }
    String endDateTime = '';
    if (widget.endDate != null) {
      endDateTime = widget.dateFormat.format(widget.endDate!);
    }
    return TextButton(
        key: _dateRangePickerKey,
        onPressed: () {
          widget.showDateRangePickerDialog(
              _dateRangePickerKey, context, setState);
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                  child: Text(
                      '${(context.withLocale().dateRangePickerStart)} $startDateTime')),
              Expanded(
                  child: Text(
                      '${(context.withLocale().dateRangePickerEnd)} $endDateTime'))
            ],
          ),
        ));
  }
}

class PlatformFABDateRangePicker extends DateRangePickerData {
  PlatformFABDateRangePicker(
      {super.key,
      super.startDate,
      super.endDate,
      super.callback,
      super.firstDate,
      super.lastDate});

  @override
  State<PlatformFABDateRangePicker> createState() =>
      _PlatformFABDateRangePickerState();
}

class _PlatformFABDateRangePickerState
    extends State<PlatformFABDateRangePicker> {
  final _dateRangePickerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    //TODO: Track focus and then decide whether to overlay the date range picker
    String startDateTime = '';
    if (widget.startDate == null) {
      // var dateTimeValue = _dateFormat.format(DateTime.now());
      // dateTime = dateTimeValue.repl aceAll(from, replace)
    } else {
      startDateTime = widget.dateFormat.format(widget.startDate!);
    }
    String endDateTime = '';
    if (widget.endDate == null) {
      // var dateTimeValue = _dateFormat.format(DateTime.now());
      // dateTime = dateTimeValue.repl aceAll(from, replace)
    } else {
      endDateTime = widget.dateFormat.format(widget.endDate!);
    }
    var dateRangeText = '$startDateTime to $endDateTime';
    return FloatingActionButton.extended(
      onPressed: () => widget.showDateRangePickerDialog(
          _dateRangePickerKey, context, setState),
      key: _dateRangePickerKey,
      icon: Icon(
        Icons.date_range_rounded,
      ),
      label: Text(
        dateRangeText,
      ),
    );
  }
}
