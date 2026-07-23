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
    var startDateText =
        _startDate?.dayDateMonthFormat ?? context.localizations.select;
    var endDateText =
        _endDate?.dayDateMonthFormat ?? context.localizations.select;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: _dateRangePickerKey,
        onTap: _showDateRangePickerDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _createDateColumn(
                        context.localizations.dateRangePickerStart,
                        startDateText,
                        _startDate != null,
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _createDateColumn(
                        context.localizations.dateRangePickerEnd,
                        endDateText,
                        _endDate != null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createDateColumn(String label, String dateText, bool hasValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          dateText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                color: hasValue
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
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
    final textTheme = Theme.of(context).textTheme;
    return CalendarDatePicker2WithActionButtonsConfig(
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      closeDialogOnCancelTapped: true,
      closeDialogOnOkTapped: true,
      firstDayOfWeek: 1,
      calendarType: CalendarDatePicker2Type.range,
      centerAlignModePicker: true,
      controlsTextStyle: textTheme.titleSmall
          ?.copyWith(color: isLightTheme ? Colors.black87 : Colors.white),
      dayTextStyle: textTheme.bodyMedium
          ?.copyWith(color: isLightTheme ? Colors.black87 : Colors.white),
      selectedDayHighlightColor: AppColors.brandPrimary,
      selectedDayTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      selectedRangeHighlightColor: AppColors.brandPrimaryLight,
      selectedRangeDayTextStyle: textTheme.bodyMedium
          ?.copyWith(color: isLightTheme ? Colors.black87 : Colors.white),
      todayTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandPrimaryLight),
      okButtonTextStyle:
          textTheme.labelLarge?.copyWith(color: AppColors.brandPrimary),
      cancelButtonTextStyle: textTheme.labelLarge
          ?.copyWith(color: !isLightTheme ? Colors.black54 : Colors.white70),
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
