import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';

abstract class AbstractPlatformDatePicker extends StatefulWidget {
  const AbstractPlatformDatePicker({super.key});

  void showDatePickerDialog(
      BuildContext widgetContext, Function(DateTime) onDateSelected,
      {CalendarDatePicker2WithActionButtonsConfig Function(
              BuildContext dialogContext)?
          calendarConfigCreator}) {
    return PlatformDialogElements.showAlignedDialog(
      context: widgetContext,
      dialogContentCreator: (dialogContext) => SizedBox(
        width: _calculateDialogWidth(widgetContext),
        child: Material(
          elevation: 5.0,
          child: CalendarDatePicker2WithActionButtons(
            config: calendarConfigCreator != null
                ? calendarConfigCreator(dialogContext)
                : createDatePickerConfig(dialogContext, widgetContext),
            value: [DateTime.now()],
            onValueChanged: (dateTimes) {
              Navigator.of(dialogContext).pop();
              if (dateTimes.length == 1) {
                onDateSelected(dateTimes.single!);
              }
            },
          ),
        ),
      ),
    );
  }

  CalendarDatePicker2WithActionButtonsConfig createDatePickerConfig(
      BuildContext dialogContext, BuildContext parentContext) {
    var isLightTheme = parentContext.isLightTheme;
    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.single,
      firstDayOfWeek: 1,
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
      cancelButton: TextButton(
        onPressed: () {
          Navigator.of(dialogContext).pop();
        },
        style: TextButton.styleFrom(
          foregroundColor: !isLightTheme ? Colors.black54 : Colors.white70,
        ),
        child: Text(parentContext.localizations.cancel),
      ),
      okButton: IgnorePointer(
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: !isLightTheme ? Colors.black54 : Colors.white70,
          ),
          child: const Text('OK'),
        ),
      ),
    );
  }

  double _calculateDialogWidth(BuildContext parentContext) {
    var isBigLayout = parentContext.isBigLayout;
    var renderBox = parentContext.findRenderObject() as RenderBox;

    double width;
    if (isBigLayout) {
      width = 400;
    } else {
      if (renderBox.size.width <= 300) {
        width = 300.0;
      } else {
        width = renderBox.size.width;
      }
    }
    return width;
  }
}

class PlatformDatePicker extends AbstractPlatformDatePicker {
  final DateTime? initialDateTime;
  final Function(DateTime) callBack;

  const PlatformDatePicker(
      {required this.callBack, super.key, this.initialDateTime});

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
        _dateTime != null ? _dateFormat.format(_dateTime!) : 'Date:       ';
    return TextButton.icon(
      onPressed: () {
        widget.showDatePickerDialog(context, _updateDate);
      },
      label: Text(buttonText),
      icon: const Icon(Icons.date_range_rounded),
      key: _widgetKey,
    );
  }

  void _updateDate(DateTime dateTime) {
    setState(() {
      _dateTime = dateTime;
      widget.callBack(_dateTime!);
    });
  }
}
