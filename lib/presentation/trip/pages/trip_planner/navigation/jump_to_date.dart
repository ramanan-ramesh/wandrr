import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/trip_repository_extensions.dart';

class JumpToDateNavigator extends AbstractPlatformDatePicker {
  final List<DateTime> Function() retrieveDatesToDisplay;

  const JumpToDateNavigator({super.key, required this.retrieveDatesToDisplay});

  @override
  State<JumpToDateNavigator> createState() => _JumpToDateNavigatorState();
}

class _JumpToDateNavigatorState extends State<JumpToDateNavigator> {
  @override
  Widget build(BuildContext context) {
    var tripMetadata = context.activeTrip.tripMetadata;
    return FloatingActionButton.extended(
      elevation: 0,
      onPressed: () {
        var datesToDisplay = widget.retrieveDatesToDisplay();
        widget.showDatePickerDialog(
          context,
          (selectedDate) {},
          calendarConfigCreator: (dialogContext) => widget
              .createDatePickerConfig(dialogContext, context)
              .copyWith(
                firstDate: tripMetadata.startDate,
                lastDate: tripMetadata.endDate,
                selectableDayPredicate: (day) => datesToDisplay.contains(day),
              ),
        );
      },
      label: Text(context.localizations.jumpToDate),
      icon: Icon(Icons.assistant_navigation),
    );
  }
}
