//Align the dialog against the button that was pressed, rather than showing as bottomModalSheet
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as app_data_picker;
import 'package:wandrr/l10n/extension.dart';

class PlatformDateTimePicker extends StatefulWidget {
  final DateTime? currentDateTime;
  final Function(DateTime)? dateTimeUpdated;
  final DateTime startDateTime, endDateTime;

  const PlatformDateTimePicker(
      {required this.startDateTime,
      required this.endDateTime,
      super.key,
      this.dateTimeUpdated,
      this.currentDateTime});

  @override
  State<PlatformDateTimePicker> createState() => _PlatformDateTimePickerState();
}

class _PlatformDateTimePickerState extends State<PlatformDateTimePicker> {
  DateTime? _dateTime;

  @override
  void initState() {
    super.initState();
    _dateTime = widget.currentDateTime;
  }

  @override
  Widget build(BuildContext context) {
    var placeHolderString = context.localizations.dateTimeSelection;
    var dateTimeText = _dateTime != null
        ? '${_dateTime!.day}/${_dateTime!.month}/${_dateTime!.year} ${_dateTime!.hour}:${_dateTime!.minute}'
        : placeHolderString;
    return TextButton(
      onPressed: () {
        var shouldRebuild = false;
        unawaited(app_data_picker.DatePicker.showDateTimePicker(
          //TODO: Theme the picker
          currentTime: _dateTime,
          context,
          showTitleActions: true,
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
          },
          minTime: widget.startDateTime,
          maxTime: widget.endDateTime,
        ).then(
          (selectedDateTime) {
            if (shouldRebuild) {
              widget.dateTimeUpdated?.call(_dateTime!);
              setState(() {});
            }
          },
        ));
      },
      child: Text(dateTimeText),
    );
  }
}
