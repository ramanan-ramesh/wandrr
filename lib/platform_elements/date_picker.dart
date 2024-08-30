import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wandrr/platform_elements/button.dart';
import 'package:wandrr/platform_elements/dialog.dart';

class PlatformDateTimePicker extends StatefulWidget {
  final DateTime? initialDateTime;
  final Function(DateTime)? dateTimeUpdated;

  const PlatformDateTimePicker(
      {super.key, this.initialDateTime, this.dateTimeUpdated});

  @override
  State<PlatformDateTimePicker> createState() => _PlatformDateTimePickerState();
}

class _PlatformDateTimePickerState extends State<PlatformDateTimePicker> {
  DateTime? _dateTime;
  static const _placeHolderString = '                   ';
  var _timePickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dateTime = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0),
          child: PlatformDatePicker(
            initialDateTime: _dateTime,
            callBack: (updatedDateTime) {
              var shouldUpdate = false;
              if (_dateTime != null) {
                if (_dateTime!.compareTo(updatedDateTime) != 0) {
                  _dateTime = updatedDateTime.add(Duration(
                      hours: _dateTime!.hour, minutes: _dateTime!.minute));
                  shouldUpdate = true;
                }
              } else {
                _dateTime = updatedDateTime;
                shouldUpdate = true;
              }
              if (shouldUpdate) {
                setState(() {});
                if (widget.dateTimeUpdated != null) {
                  widget.dateTimeUpdated!(_dateTime!);
                }
              }
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.0),
          child: TextButton(
              key: _timePickerKey,
              child: Text(_dateTime != null
                  ? '${_dateTime!.hour} : ${_dateTime!.minute}'
                  : _placeHolderString),
              onPressed: widget.dateTimeUpdated == null
                  ? null
                  : () async {
                      PlatformDialogElements.showAlignedDialog(
                          context: context,
                          widgetBuilder: (context) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  elevation: 5.0,
                                  child: TimePickerDialog(
                                    initialTime: TimeOfDay(
                                        hour: _dateTime!.hour,
                                        minute: _dateTime!.minute),
                                  ),
                                ),
                              ],
                            );
                          },
                          widgetKey: _timePickerKey,
                          onDialogResult: (result) {
                            if (result is TimeOfDay) {
                              setState(() {
                                _dateTime ??= DateTime.now();
                                _dateTime = DateTime(_dateTime!.year,
                                        _dateTime!.month, _dateTime!.day)
                                    .add(Duration(
                                        hours: result.hour,
                                        minutes: result.minute));
                                if (widget.dateTimeUpdated != null) {
                                  widget.dateTimeUpdated!(_dateTime!);
                                }
                              });
                            }
                          });
                    }),
        )
      ],
    );
  }
}

class PlatformDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate, initialEndDate;
  final String? startDateLabelText, endDateLabelText;
  final Function(DateTime? start, DateTime? end)? callback;

  const PlatformDateRangePicker(
      {super.key,
      this.initialStartDate,
      this.initialEndDate,
      this.callback,
      this.startDateLabelText,
      this.endDateLabelText});

  @override
  State<PlatformDateRangePicker> createState() =>
      _PlatformDateRangePickerState();
}

class _PlatformDateRangePickerState extends State<PlatformDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _dateFormat = intl.DateFormat.MMMEd();
  final _dateRangePickerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    //TODO: Track focus and then decide whether to overlay the date range picker
    String startDateTime = '';
    if (_startDate != null) {
      startDateTime = _dateFormat.format(_startDate!);
    }
    String endDateTime = '';
    if (_endDate != null) {
      endDateTime = _dateFormat.format(_endDate!);
    }
    return TextButton(
        key: _dateRangePickerKey,
        onPressed: () {
          PlatformDialogElements.showAlignedDialog(
              context: context,
              widgetBuilder: (context) {
                return SizedBox(
                  width: 400,
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
                        selectedRangeDayTextStyle:
                            TextStyle(color: Colors.black),
                        todayTextStyle: TextStyle(color: Colors.white),
                        okButtonTextStyle: TextStyle(color: Colors.black),
                        cancelButtonTextStyle: TextStyle(color: Colors.black),
                        cancelButton: IgnorePointer(
                          child: TextButton(
                            onPressed: () {},
                            child:
                                Text(AppLocalizations.of(this.context)!.cancel),
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
                      onValueChanged: _tryUpdateDateRange,
                      value: [_startDate, _endDate],
                    ),
                  ),
                );
              },
              widgetKey: _dateRangePickerKey);
        },
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                  child: Text(
                      '${(widget.startDateLabelText ?? AppLocalizations.of(context)!.dateRangePickerStart)} $startDateTime')),
              Expanded(
                  child: Text(
                      '${(widget.endDateLabelText ?? AppLocalizations.of(context)!.dateRangePickerEnd)} $endDateTime'))
            ],
          ),
        ));
  }

  void _tryUpdateDateRange(List<DateTime?> dates) {
    if (dates.length == 1) {
      _startDate = dates.first;
      _endDate = null;
      setState(() {});
      if (widget.callback != null) {
        widget.callback!(_startDate, _endDate);
      }
    }
    if (dates.length == 2) {
      _startDate = dates.first;
      _endDate = dates.elementAt(1);
      setState(() {});
      if (widget.callback != null) {
        widget.callback!(_startDate, _endDate);
      }
    }
  }
}

//TODO: Harmonize the themes between PlatformDateRangePicker and  PlatformFABDateRangePicker
class PlatformFABDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate, initialEndDate;
  final Function(DateTime? start, DateTime? end)? callback;

  const PlatformFABDateRangePicker(
      {super.key, this.initialStartDate, this.initialEndDate, this.callback});

  @override
  State<PlatformFABDateRangePicker> createState() =>
      _PlatformFABDateRangePickerState();
}

class _PlatformFABDateRangePickerState
    extends State<PlatformFABDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _dateFormat = intl.DateFormat.MMMEd();
  final _dateRangePickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Track focus and then decide whether to overlay the date range picker
    String startDateTime = '';
    if (_startDate == null) {
      // var dateTimeValue = _dateFormat.format(DateTime.now());
      // dateTime = dateTimeValue.repl aceAll(from, replace)
    } else {
      startDateTime = _dateFormat.format(_startDate!);
    }
    String endDateTime = '';
    if (_endDate == null) {
      // var dateTimeValue = _dateFormat.format(DateTime.now());
      // dateTime = dateTimeValue.repl aceAll(from, replace)
    } else {
      endDateTime = _dateFormat.format(_endDate!);
    }
    var dateRangeText = '$startDateTime to $endDateTime';
    return PlatformButtonElements.createExtendedFAB(
        iconData: Icons.date_range_rounded,
        context: context,
        text: dateRangeText,
        widgetKey: _dateRangePickerKey,
        onPressed: () {
          PlatformDialogElements.showAlignedDialog(
              context: context,
              widgetBuilder: (context) {
                return SizedBox(
                  width: 400,
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
                        selectedRangeDayTextStyle:
                            TextStyle(color: Colors.black),
                        todayTextStyle: TextStyle(color: Colors.white),
                        okButtonTextStyle: TextStyle(color: Colors.black),
                        cancelButtonTextStyle: TextStyle(color: Colors.black),
                        cancelButton: IgnorePointer(
                          child: TextButton(
                            onPressed: () {},
                            child:
                                Text(AppLocalizations.of(this.context)!.cancel),
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
                      onValueChanged: _tryUpdateDateRange,
                      value: [_startDate, _endDate],
                    ),
                  ),
                );
              },
              widgetKey: _dateRangePickerKey);
        });
  }

  void _tryUpdateDateRange(List<DateTime?> dates) {
    if (dates.length == 1) {
      _startDate = dates.first;
    }
    if (dates.length == 2) {
      _startDate = dates.first;
      _endDate = dates.elementAt(1);
      if (widget.callback != null) {
        setState(() {});
        widget.callback!(_startDate, _endDate);
      }
    }
  }
}

class PlatformDatePicker extends StatefulWidget {
  final DateTime? initialDateTime;
  final Function(DateTime) callBack;

  const PlatformDatePicker(
      {super.key, this.initialDateTime, required this.callBack});

  @override
  State<PlatformDatePicker> createState() => _PlatformDatePickerState();
}

class _PlatformDatePickerState extends State<PlatformDatePicker> {
  final _dateFormat = intl.DateFormat.yMMMd();
  late DateTime? _dateTime;

  final GlobalKey _widgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dateTime = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    var buttonText =
        _dateTime != null ? _dateFormat.format(_dateTime!) : '            ';
    return PlatformButtonElements.createTextButtonWithIcon(
        key: _widgetKey,
        text: buttonText,
        iconData: Icons.date_range_rounded,
        onPressed: () {
          PlatformDialogElements.showAlignedDialog(
              context: context,
              widgetBuilder: (context) => Container(
                    width: 400,
                    child: Material(
                      elevation: 5.0,
                      child: CalendarDatePicker2WithActionButtons(
                        config: CalendarDatePicker2WithActionButtonsConfig(
                          calendarType: CalendarDatePicker2Type.single,
                          firstDayOfWeek: 1,
                          centerAlignModePicker: true,
                        ),
                        value: [DateTime.now()],
                        onValueChanged: (dateTimes) {
                          if (dateTimes.length == 1) {
                            setState(() {
                              _dateTime = dateTimes.single!;
                              widget.callBack(_dateTime!);
                            });
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
              widgetKey: _widgetKey);
        });
  }
}
