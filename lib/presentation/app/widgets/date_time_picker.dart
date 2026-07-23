import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as app_data_picker;
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

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
  void didUpdateWidget(covariant PlatformDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDateTime != widget.currentDateTime) {
      setState(() {
        _dateTime = widget.currentDateTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.isLightTheme;
    var placeHolderString = context.localizations.dateTimeSelection;
    var dateTimeText =
        _dateTime != null ? _dateTime!.hourMinuteDateFormat : placeHolderString;

    return TextButton(
      onPressed: () {
        var shouldRebuild = false;
        unawaited(app_data_picker.DatePicker.showDateTimePicker(
          currentTime: _dateTime,
          context,
          showTitleActions: true,
          theme: _createDatePickerTheme(context, isLightTheme),
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

  app_data_picker.DatePickerTheme _createDatePickerTheme(
      BuildContext context, bool isLightTheme) {
    final textTheme = Theme.of(context).textTheme;
    if (isLightTheme) {
      return app_data_picker.DatePickerTheme(
        backgroundColor: AppColors.lightSurface,
        headerColor: AppColors.brandPrimary,
        itemStyle: (textTheme.titleMedium ?? const TextStyle()).copyWith(
          color: AppColors.brandSecondary,
          fontWeight: FontWeight.w500,
        ),
        doneStyle: (textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        cancelStyle: (textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
        itemHeight: 48,
        containerHeight: 240,
      );
    } else {
      return app_data_picker.DatePickerTheme(
        backgroundColor: AppColors.darkSurface,
        headerColor: AppColors.darkSurfaceHeader,
        itemStyle: (textTheme.titleMedium ?? const TextStyle()).copyWith(
          color: AppColors.neutral100,
          fontWeight: FontWeight.w500,
        ),
        doneStyle: (textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: AppColors.brandPrimaryLight,
          fontWeight: FontWeight.w700,
        ),
        cancelStyle: (textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: AppColors.neutral400.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
        itemHeight: 48,
        containerHeight: 240,
      );
    }
  }
}
