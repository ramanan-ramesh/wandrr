import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

import 'dialog.dart';

abstract class DateRangePickerBase extends StatefulWidget {
  DateTime? startDate, endDate;
  final DateTime? firstDate, lastDate;
  final Function(DateTime? start, DateTime? end)? callback;

  DateRangePickerBase({
    super.key,
    this.startDate,
    this.endDate,
    this.callback,
    this.firstDate,
    this.lastDate,
  });

  void showDateRangePickerDialog(GlobalKey widgetKey, BuildContext context,
      void Function(VoidCallback fn) setState) {
    var isBigLayout = context.isBigLayout;
    var isLightTheme = context.isLightTheme;
    PlatformDialogElements.showAlignedDialog(
        context: context,
        dialogContentCreator: (dialogContext) {
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
              color: Theme
                  .of(context)
                  .dialogTheme
                  .backgroundColor,
              child: CalendarDatePicker2WithActionButtons(
                onCancelTapped: () {
                  Navigator.of(dialogContext).pop();
                },
                onOkTapped: () {
                  Navigator.of(dialogContext).pop();
                },
                config: CalendarDatePicker2WithActionButtonsConfig(
                  firstDate: firstDate,
                  lastDate: lastDate,
                  closeDialogOnCancelTapped: true,
                  closeDialogOnOkTapped: true,
                  firstDayOfWeek: 1,
                  calendarType: CalendarDatePicker2Type.range,
                  centerAlignModePicker: true,
                  controlsTextStyle: TextStyle(
                      color: isLightTheme ? Colors.black87 : Colors.white),
                  dayTextStyle: TextStyle(
                      color: isLightTheme ? Colors.black87 : Colors.white),
                  selectedDayHighlightColor: AppColors.brandPrimary,
                  selectedDayTextStyle: const TextStyle(color: Colors.white),
                  selectedRangeHighlightColor: AppColors.brandPrimaryLight,
                  selectedRangeDayTextStyle: TextStyle(
                      color: isLightTheme ? Colors.black87 : Colors.white),
                  todayTextStyle: TextStyle(
                      color: isLightTheme
                          ? AppColors.brandPrimary
                          : AppColors.brandPrimaryLight),
                  okButtonTextStyle: TextStyle(color: AppColors.brandPrimary),
                  cancelButtonTextStyle: TextStyle(
                      color: !isLightTheme ? Colors.black54 : Colors.white70),
                  cancelButton: IgnorePointer(
                    child: IconButton(
                      onPressed: null,
                      icon: Icon(Icons.cancel_rounded,
                          color:
                          !isLightTheme ? Colors.black54 : Colors.white70),
                    ),
                  ),
                  okButton: IgnorePointer(
                    child: IconButton(
                      onPressed: null,
                      icon: Icon(Icons.done_rounded,
                          color:
                          !isLightTheme ? Colors.black54 : Colors.white70),
                    ),
                  ),
                ),
                onValueChanged: (dates) => _tryUpdateDateRange(dates, setState),
                value: [startDate, endDate],
              ),
            ),
          );
        });
  }

  void _tryUpdateDateRange(List<DateTime?> dates,
      void Function(VoidCallback fn) setState) {
    if (dates.length == 1) {
      startDate = dates.first;
      endDate = null;
      setState(() {});
    }
    if (dates.length == 2) {
      startDate = dates.first;
      endDate = dates.elementAt(1);
      setState(() {
        callback?.call(startDate, endDate);
      });
    }
  }
}

//TODO: Add the duration in days indicator as in LodgingEditor and TripDetailsEditor
class PlatformDateRangePicker extends DateRangePickerBase {
  PlatformDateRangePicker({super.key,
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
    final isBigLayout = context.isBigLayout;
    var startDateText =
    widget.startDate != null ? widget.startDate!.dayDateMonthFormat : '';
    var endDateText =
    widget.endDate != null ? widget.endDate!.dayDateMonthFormat : '';
    return IntrinsicHeight(
      child: TextButton(
        key: _dateRangePickerKey,
        onPressed: () {
          widget.showDateRangePickerDialog(
              _dateRangePickerKey, context, setState);
        },
        child: isBigLayout
            ? _createButtonForBigLayout(context, startDateText, endDateText)
            : _createButtonForSmallLayout(context, startDateText, endDateText),
      ),
    );
  }

  Widget _createButtonForSmallLayout(BuildContext context, String startDateText,
      String endDateText) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForSmallLayout(context,
                context.localizations.dateRangePickerStart, startDateText),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForSmallLayout(
                context, context.localizations.dateRangePickerEnd, endDateText),
          ),
        ),
      ],
    );
  }

  Widget _createButtonForBigLayout(BuildContext context, String startDateText,
      String endDateText) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForBigLayout(context,
                context.localizations.dateRangePickerStart, startDateText),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForBigLayout(
                context, context.localizations.dateRangePickerEnd, endDateText),
          ),
        ),
      ],
    );
  }

  Widget _createDateForBigLayout(BuildContext context, String label,
      String startDateText) {
    return Container(
      alignment: Alignment.centerLeft,
      constraints: const BoxConstraints(minHeight: 24),
      child: Text(
        '$label $startDateText',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _createDateForSmallLayout(BuildContext context, String label,
      String dateText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme
              .of(context)
              .textTheme
              .labelLarge,
        ),
        Container(
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints(minHeight: 24),
          child: Text(
            dateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium,
          ),
        ),
      ],
    );
  }
}

class PlatformFABDateRangePicker extends DateRangePickerBase {
  PlatformFABDateRangePicker({super.key,
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
    var startDateTime = context.localizations.dateRangePickerStart;
    if (widget.startDate != null) {
      startDateTime = widget.startDate!.dayDateMonthFormat;
    }
    var endDateTime = context.localizations.dateRangePickerEnd;
    if (widget.endDate != null) {
      endDateTime = widget.endDate!.dayDateMonthFormat;
    }
    var dateRangeText = '$startDateTime to $endDateTime';
    return FloatingActionButton.extended(
      onPressed: () =>
          widget.showDateRangePickerDialog(
              _dateRangePickerKey, context, setState),
      key: _dateRangePickerKey,
      icon: const Icon(
        Icons.date_range_rounded,
      ),
      label: Text(
        dateRangeText,
      ),
    );
  }
}
