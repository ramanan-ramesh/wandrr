import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

import 'dialog.dart';

class PlatformDateRangePicker extends StatefulWidget {
  final DateTime? startDate, endDate;
  final DateTime? firstDate, lastDate;
  final Function(DateTime? start, DateTime? end)? callback;

  const PlatformDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    this.callback,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<PlatformDateRangePicker> createState() =>
      _PlatformDateRangePickerState();
}

class _PlatformDateRangePickerState extends State<PlatformDateRangePicker> {
  final _dateRangePickerKey = GlobalKey();
  DateTime? _startDate, _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  void didUpdateWidget(covariant PlatformDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStartDate = widget.startDate;
    final newEndDate = widget.endDate;
    if (oldWidget.startDate != newStartDate ||
        oldWidget.endDate != newEndDate) {
      setState(() {
        _startDate = newStartDate;
        _endDate = newEndDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBigLayout = context.isBigLayout;
    var startDateText = _startDate?.dayDateMonthFormat ?? '';
    var endDateText = _endDate?.dayDateMonthFormat ?? '';
    return IntrinsicHeight(
      child: TextButton(
        key: _dateRangePickerKey,
        onPressed: _showDateRangePickerDialog,
        child: isBigLayout
            ? _createButtonForBigLayout(startDateText, endDateText)
            : _createButtonForSmallLayout(startDateText, endDateText),
      ),
    );
  }

  Widget _createButtonForSmallLayout(String startDateText, String endDateText) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForSmallLayout(
                context.localizations.dateRangePickerStart, startDateText),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForSmallLayout(
                context.localizations.dateRangePickerEnd, endDateText),
          ),
        ),
      ],
    );
  }

  Widget _createButtonForBigLayout(String startDateText, String endDateText) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForBigLayout(
                context.localizations.dateRangePickerStart, startDateText),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: _createDateForBigLayout(
                context.localizations.dateRangePickerEnd, endDateText),
          ),
        ),
      ],
    );
  }

  Widget _createDateForBigLayout(String label, String startDateText) {
    return Container(
      alignment: Alignment.centerLeft,
      constraints: const BoxConstraints(minHeight: 24),
      child: Row(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: context.isLightTheme ? null : Colors.black),
          ),
          const SizedBox(width: 8),
          Text(
            startDateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: context.isLightTheme ? null : Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _createDateForSmallLayout(String label, String dateText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Container(
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints(minHeight: 24),
          child: Text(
            dateText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  void _showDateRangePickerDialog() {
    var isBigLayout = context.isBigLayout;
    PlatformDialogElements.showAlignedDialog(
        context: context,
        dialogContentCreator: (dialogContext) {
          var dateRangePickerButtonRenderBox =
              _dateRangePickerKey.currentContext!.findRenderObject()
                  as RenderBox;
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
              color: Theme.of(context).dialogTheme.backgroundColor,
              child: CalendarDatePicker2WithActionButtons(
                onCancelTapped: () {
                  Navigator.of(dialogContext).pop();
                },
                onOkTapped: () {
                  Navigator.of(dialogContext).pop();
                },
                config: _createCalendarConfig(),
                onValueChanged: (dates) => _tryUpdateDateRange(dates, setState),
                value: [_startDate, _endDate],
              ),
            ),
          );
        });
  }

  CalendarDatePicker2WithActionButtonsConfig _createCalendarConfig() {
    var isLightTheme = context.isLightTheme;
    return CalendarDatePicker2WithActionButtonsConfig(
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      closeDialogOnCancelTapped: true,
      closeDialogOnOkTapped: true,
      firstDayOfWeek: 1,
      calendarType: CalendarDatePicker2Type.range,
      centerAlignModePicker: true,
      controlsTextStyle:
          TextStyle(color: isLightTheme ? Colors.black87 : Colors.white),
      dayTextStyle:
          TextStyle(color: isLightTheme ? Colors.black87 : Colors.white),
      selectedDayHighlightColor: AppColors.brandPrimary,
      selectedDayTextStyle: const TextStyle(color: Colors.white),
      selectedRangeHighlightColor: AppColors.brandPrimaryLight,
      selectedRangeDayTextStyle:
          TextStyle(color: isLightTheme ? Colors.black87 : Colors.white),
      todayTextStyle: TextStyle(
          color: isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandPrimaryLight),
      okButtonTextStyle: TextStyle(color: AppColors.brandPrimary),
      cancelButtonTextStyle:
          TextStyle(color: !isLightTheme ? Colors.black54 : Colors.white70),
      cancelButton: IgnorePointer(
        child: IconButton(
          onPressed: null,
          icon: Icon(Icons.cancel_rounded,
              color: !isLightTheme ? Colors.black54 : Colors.white70),
        ),
      ),
      okButton: IgnorePointer(
        child: IconButton(
          onPressed: null,
          icon: Icon(Icons.done_rounded,
              color: !isLightTheme ? Colors.black54 : Colors.white70),
        ),
      ),
    );
  }

  void _tryUpdateDateRange(
      List<DateTime?> dates, void Function(VoidCallback fn) setState) {
    if (dates.length == 1) {
      _startDate = dates.first;
      _endDate = null;
      setState(() {});
    }
    if (dates.length == 2) {
      _startDate = dates.first;
      _endDate = dates.elementAt(1);
      setState(() {
        widget.callback?.call(_startDate, _endDate);
      });
    }
  }
}
