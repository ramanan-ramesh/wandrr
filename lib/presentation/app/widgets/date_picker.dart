import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';

/// Shows a platform-adaptive date picker dialog.
///
/// By moving this to a top-level function, we decouple the dialog logic
/// from any specific widget, making it more reusable and testable.
Future<void> _showPlatformDatePicker(
  BuildContext context, {
  required Function(DateTime) onDateSelected,
  DateTime? initialDate,
  CalendarDatePicker2WithActionButtonsConfig? customConfig,
  Alignment? widgetAnchor,
  Alignment? dialogAnchor,
}) async {
  return PlatformDialogElements.showAlignedDialog(
    context: context,
    width: _calculateDialogWidth(context),
    widgetAnchor: widgetAnchor,
    dialogAnchor: dialogAnchor,
    dialogContentCreator: (dialogContext) {
      final defaultConfig =
          _createDefaultDatePickerConfig(dialogContext, context);

      final config = customConfig == null
          ? defaultConfig
          : defaultConfig.copyWith(
              calendarType: customConfig.calendarType,
              firstDate: customConfig.firstDate,
              lastDate: customConfig.lastDate,
              currentDate: customConfig.currentDate,
              firstDayOfWeek: customConfig.firstDayOfWeek,
              weekdayLabels: customConfig.weekdayLabels,
              weekdayLabelTextStyle: customConfig.weekdayLabelTextStyle,
              centerAlignModePicker: customConfig.centerAlignModePicker,
              customModePickerIcon: customConfig.customModePickerIcon,
              controlsTextStyle: customConfig.controlsTextStyle,
              dayTextStyle: customConfig.dayTextStyle,
              selectedDayTextStyle: customConfig.selectedDayTextStyle,
              selectedDayHighlightColor: customConfig.selectedDayHighlightColor,
              disabledDayTextStyle: customConfig.disabledDayTextStyle,
              todayTextStyle: customConfig.todayTextStyle,
              yearTextStyle: customConfig.yearTextStyle,
              selectedYearTextStyle: customConfig.selectedYearTextStyle,
              dayBorderRadius: customConfig.dayBorderRadius,
              yearBorderRadius: customConfig.yearBorderRadius,
              selectableDayPredicate: customConfig.selectableDayPredicate,
              dayBuilder: customConfig.dayBuilder,
              yearBuilder: customConfig.yearBuilder,
              disableModePicker: customConfig.disableModePicker,
              controlsHeight: customConfig.controlsHeight,
              lastMonthIcon: customConfig.lastMonthIcon,
              nextMonthIcon: customConfig.nextMonthIcon,
              okButton: customConfig.okButton,
              cancelButton: customConfig.cancelButton,
              okButtonTextStyle: customConfig.okButtonTextStyle,
              cancelButtonTextStyle: customConfig.cancelButtonTextStyle,
            );

      return SizedBox(
        width: _calculateDialogWidth(context),
        child: Material(
          elevation: 5.0,
          child: CalendarDatePicker2WithActionButtons(
            config: config,
            value: [initialDate ?? DateTime.now()],
            onValueChanged: (dateTimes) {
              Navigator.of(dialogContext).pop();
              if (dateTimes.length == 1) {
                onDateSelected(dateTimes.single!);
              }
            },
          ),
        ),
      );
    },
  );
}

class PlatformDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final CalendarDatePicker2WithActionButtonsConfig? calendarConfig;
  final Alignment? widgetAnchor, dialogAnchor;

  const PlatformDatePicker({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
    this.calendarConfig,
    this.widgetAnchor,
    this.dialogAnchor,
  });

  @override
  Widget build(BuildContext context) {
    var buttonText = selectedDate != null
        ? selectedDate!.monthDateYearFormat
        : 'Date:       ';
    return TextButton.icon(
      onPressed: () {
        _showPlatformDatePicker(
          context,
          onDateSelected: onDateSelected,
          initialDate: selectedDate,
          customConfig: calendarConfig,
          widgetAnchor: widgetAnchor,
          dialogAnchor: dialogAnchor,
        );
      },
      label: Text(buttonText),
      icon: const Icon(Icons.date_range_rounded),
    );
  }
}

CalendarDatePicker2WithActionButtonsConfig _createDefaultDatePickerConfig(
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
  var renderBox = parentContext.findRenderObject() as RenderBox;
  var isBigLayout = parentContext.isBigLayout;

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
