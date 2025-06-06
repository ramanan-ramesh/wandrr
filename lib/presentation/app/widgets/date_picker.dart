import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:wandrr/data/app/app_data_repository_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';

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
        _dateTime != null ? _dateFormat.format(_dateTime!) : 'Date:       ';
    return TextButton.icon(
      onPressed: () {
        var dialogWidth = _calculateDialogWidth();
        _showDatePickerDialog(context, dialogWidth);
      },
      label: Text(buttonText),
      icon: const Icon(Icons.date_range_rounded),
      key: _widgetKey,
    );
  }

  double _calculateDialogWidth() {
    var currentWidgetContext = _widgetKey.currentContext!;
    var isBigLayout = currentWidgetContext.isBigLayout;
    var renderBox = _widgetKey.currentContext!.findRenderObject() as RenderBox;

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

  void _showDatePickerDialog(BuildContext widgetContext, double dialogWidth) {
    return PlatformDialogElements.showAlignedDialog(
        context: widgetContext,
        widgetBuilder: (dialogContext) => SizedBox(
              width: dialogWidth,
              child: Material(
                elevation: 5.0,
                child: CalendarDatePicker2WithActionButtons(
                  config: CalendarDatePicker2WithActionButtonsConfig(
                    calendarType: CalendarDatePicker2Type.single,
                    firstDayOfWeek: 1,
                    centerAlignModePicker: true,
                    controlsTextStyle: const TextStyle(color: Colors.white),
                    dayTextStyle: const TextStyle(color: Colors.white),
                    selectedDayHighlightColor: Colors.green,
                    selectedDayTextStyle: const TextStyle(color: Colors.black),
                    selectedRangeHighlightColor: Colors.green,
                    selectedRangeDayTextStyle: const TextStyle(color: Colors.black),
                    todayTextStyle: const TextStyle(color: Colors.white),
                    okButtonTextStyle: const TextStyle(color: Colors.black),
                    cancelButtonTextStyle: const TextStyle(color: Colors.black),
                    cancelButton: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(context.localizations.cancel),
                    ),
                    okButton: IgnorePointer(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('OK'),
                      ),
                    ),
                  ),
                  value: [DateTime.now()],
                  onValueChanged: (dateTimes) {
                    if (dateTimes.length == 1) {
                      setState(() {
                        _dateTime = dateTimes.single!;
                        widget.callBack(_dateTime!);
                      });
                    }
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
            ),
        widgetKey: _widgetKey);
  }
}
