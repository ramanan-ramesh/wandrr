//Align the dialog against the button that was pressed, rather than showing as bottomModalSheet
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:wandrr/app_presentation/extensions.dart';

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

  @override
  void initState() {
    super.initState();
    _dateTime = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    var placeHolderString = context.withLocale().dateTimeSelection;
    var dateTimeText = _dateTime != null
        ? '${_dateTime!.day}/${_dateTime!.month}/${_dateTime!.year} ${_dateTime!.hour}:${_dateTime!.minute}'
        : placeHolderString;
    return TextButton(
      onPressed: () {
        bool shouldRebuild = false;
        DatePicker.showDateTimePicker(context, showTitleActions: true,
                onConfirm: (date) {
          if (_dateTime == null) {
            _dateTime = date;
            shouldRebuild = true;
          } else {
            if (!_dateTime!.isAtSameMomentAs(date)) {
              _dateTime = date;
              shouldRebuild = true;
            }
          }
        }, currentTime: _dateTime ?? DateTime.now())
            .then(
          (selectedDateTime) {
            if (shouldRebuild) {
              widget.dateTimeUpdated?.call(_dateTime!);
              setState(() {});
            }
          },
        );
      },
      child: Text(dateTimeText),
    );
  }
}
