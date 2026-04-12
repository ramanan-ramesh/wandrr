import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/trip/widgets/time_zone_indicator.dart';

/// A comprehensive widget for editing stay date ranges with:
/// - Date buttons that show date picker on tap
/// - Time sliders with half-hour increments
/// - Timezone indicator
/// - Duration indicator (nights)
///
/// Used in: LodgingEditor, AffectedStaysSection, ConflictingStaysSection
class StayDateTimeRangeEditor extends StatefulWidget {
  final DateTime? checkinDateTime;
  final DateTime? checkoutDateTime;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final LocationFacade? location;
  final void Function(DateTime checkin, DateTime checkout) onStayRangeChanged;

  /// Optional: Show original times for conflict resolution
  final DateTime? originalCheckinDateTime;
  final DateTime? originalCheckoutDateTime;
  final bool showOriginalTimes;

  const StayDateTimeRangeEditor({
    required this.checkinDateTime,
    required this.checkoutDateTime,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onStayRangeChanged,
    super.key,
    this.location,
    this.originalCheckinDateTime,
    this.originalCheckoutDateTime,
    this.showOriginalTimes = false,
  });

  @override
  State<StayDateTimeRangeEditor> createState() =>
      _StayDateTimeRangeEditorState();
}

class _StayDateTimeRangeEditorState extends State<StayDateTimeRangeEditor> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showOriginalTimes &&
            widget.originalCheckinDateTime != null &&
            widget.originalCheckoutDateTime != null)
          _buildOriginalTimesChip(context, isLightTheme: isLightTheme),
        _buildCheckinSection(context, isLightTheme: isLightTheme),
        const SizedBox(height: 16),
        _buildCheckoutSection(context, isLightTheme: isLightTheme),
        if (widget.checkinDateTime != null &&
            widget.checkoutDateTime != null) ...[
          const SizedBox(height: 12),
          _buildFooterIndicators(context, isLightTheme: isLightTheme),
        ],
      ],
    );
  }

  Widget _buildOriginalTimesChip(BuildContext context,
      {required bool isLightTheme}) {
    final originalCheckin = widget.originalCheckinDateTime!;
    final originalCheckout = widget.originalCheckoutDateTime!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.warningLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 16,
            color: isLightTheme ? AppColors.warning : AppColors.warningLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Original: ${originalCheckin.dayDateMonthFormat} ${_formatTimeFromDateTime(originalCheckin)} → '
              '${originalCheckout.dayDateMonthFormat} ${_formatTimeFromDateTime(originalCheckout)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinSection(BuildContext context,
      {required bool isLightTheme}) {
    return _DateTimeSection(
      label: 'Check-in',
      icon: Icons.login_rounded,
      iconColor: isLightTheme ? AppColors.success : AppColors.successLight,
      dateTime: widget.checkinDateTime,
      isLightTheme: isLightTheme,
      onDateButtonPressed: () => _showDateRangePicker(context),
      onTimeChanged: (time) {
        final date = widget.checkinDateTime!;
        widget.onStayRangeChanged(
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
          widget.checkoutDateTime!,
        );
      },
    );
  }

  Widget _buildCheckoutSection(BuildContext context,
      {required bool isLightTheme}) {
    return _DateTimeSection(
      label: 'Check-out',
      icon: Icons.logout_rounded,
      iconColor: isLightTheme ? AppColors.warning : AppColors.warningLight,
      dateTime: widget.checkoutDateTime,
      isLightTheme: isLightTheme,
      onDateButtonPressed: () => _showDateRangePicker(context),
      onTimeChanged: (time) {
        final date = widget.checkoutDateTime!;
        widget.onStayRangeChanged(
          widget.checkinDateTime!,
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
      },
    );
  }

  void _showDateRangePicker(BuildContext context) {
    final isLightTheme = context.isLightTheme;

    PlatformDialogElements.showAlignedDialog(
      context: context,
      dialogContentCreator: (dialogContext) {
        return SizedBox(
          width: 350,
          child: Material(
            elevation: 5.0,
            color: Theme.of(context).dialogTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            child: CalendarDatePicker2WithActionButtons(
              onCancelTapped: () {
                Navigator.of(dialogContext).pop();
              },
              onOkTapped: () {
                Navigator.of(dialogContext).pop();
              },
              config: _createCalendarConfig(isLightTheme: isLightTheme),
              onValueChanged: _handleDateRangeChanged,
              value: [widget.checkinDateTime, widget.checkoutDateTime],
            ),
          ),
        );
      },
    );
  }

  CalendarDatePicker2WithActionButtonsConfig _createCalendarConfig(
      {required bool isLightTheme}) {
    return CalendarDatePicker2WithActionButtonsConfig(
      firstDate: widget.tripStartDate,
      lastDate: widget.tripEndDate.add(const Duration(days: 1)),
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
      okButtonTextStyle: const TextStyle(color: AppColors.brandPrimary),
      cancelButtonTextStyle:
          TextStyle(color: !isLightTheme ? Colors.black54 : Colors.white70),
    );
  }

  void _handleDateRangeChanged(List<DateTime?> dates) {
    if (dates.isEmpty) {
      return;
    }

    var checkin = widget.checkinDateTime ?? DateTime.now();
    var checkout = widget.checkoutDateTime ?? DateTime.now();
    var changed = false;

    if (dates.isNotEmpty && dates.first != null) {
      final newCheckin = dates.first!;
      final currentCheckin = widget.checkinDateTime;
      final hour = currentCheckin?.hour ?? 14;
      final minute = currentCheckin?.minute ?? 0;
      checkin = DateTime(
        newCheckin.year,
        newCheckin.month,
        newCheckin.day,
        hour,
        minute,
      );
      changed = true;
    }

    if (dates.length >= 2 && dates[1] != null) {
      final newCheckout = dates[1]!;
      final currentCheckout = widget.checkoutDateTime;
      final hour = currentCheckout?.hour ?? 11;
      final minute = currentCheckout?.minute ?? 0;
      checkout = DateTime(
        newCheckout.year,
        newCheckout.month,
        newCheckout.day,
        hour,
        minute,
      );
      changed = true;
    }

    if (changed) {
      widget.onStayRangeChanged(checkin, checkout);
    }
  }

  Widget _buildFooterIndicators(BuildContext context,
      {required bool isLightTheme}) {
    final nights =
        widget.checkoutDateTime!.differenceInDays(widget.checkinDateTime!);

    return Row(
      children: [
        if (widget.location != null) ...[
          TimezoneIndicator(location: widget.location!),
          const SizedBox(width: 16),
        ],
        _buildDurationChip(context, nights, isLightTheme: isLightTheme),
      ],
    );
  }

  Widget _buildDurationChip(BuildContext context, int nights,
      {required bool isLightTheme}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.successLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.successLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.nights_stay_rounded,
            size: 16,
            color: isLightTheme ? AppColors.success : AppColors.successLight,
          ),
          const SizedBox(width: 6),
          Text(
            '$nights night${nights != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isLightTheme ? AppColors.success : AppColors.successLight,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _formatTimeFromDateTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final hourOfPeriod = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour < 12 ? 'AM' : 'PM';
    return '$hourOfPeriod:${minute.toString().padLeft(2, '0')} $period';
  }
}

/// A section for displaying and editing a single date-time (check-in or check-out)
class _DateTimeSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final DateTime? dateTime;
  final bool isLightTheme;
  final VoidCallback onDateButtonPressed;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _DateTimeSection({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.dateTime,
    required this.isLightTheme,
    required this.onDateButtonPressed,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? iconColor.withValues(alpha: 0.05)
            : iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (dateTime != null) ...[
            const SizedBox(height: 12),
            _TimeSlider(
              currentTime: TimeOfDay.fromDateTime(dateTime!),
              onTimeChanged: onTimeChanged,
              isLightTheme: isLightTheme,
              accentColor: iconColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color:
                    isLightTheme ? AppColors.neutral700 : AppColors.neutral300,
              ),
        ),
        const Spacer(),
        _buildDateButton(context),
        if (dateTime != null) ...[
          const SizedBox(width: 8),
          _buildTimeChip(context),
        ],
      ],
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return InkWell(
      onTap: onDateButtonPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLightTheme ? Colors.white : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              dateTime != null ? dateTime!.dayDateMonthFormat : 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dateTime != null
                        ? (isLightTheme
                            ? AppColors.neutral700
                            : AppColors.neutral300)
                        : (isLightTheme
                            ? Colors.grey.shade500
                            : Colors.grey.shade400),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context) {
    final time = TimeOfDay.fromDateTime(dateTime!);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$hour:$minute $period',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
      ),
    );
  }
}

/// A smooth time slider that supports half-hour increments (00, 30)
class _TimeSlider extends StatelessWidget {
  final TimeOfDay currentTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool isLightTheme;
  final Color accentColor;

  const _TimeSlider({
    required this.currentTime,
    required this.onTimeChanged,
    required this.isLightTheme,
    required this.accentColor,
  });

  // Convert TimeOfDay to slider value (0-47 for half-hour increments)
  double get _sliderValue =>
      currentTime.hour * 2 + (currentTime.minute >= 30 ? 1 : 0).toDouble();

  // Convert slider value to TimeOfDay
  TimeOfDay _valueToTime(double value) {
    final intValue = value.round();
    final hour = intValue ~/ 2;
    final minute = (intValue % 2) * 30;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: accentColor.withValues(alpha: 0.2),
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: _sliderValue,
            min: 0,
            max: 47,
            // 24 hours * 2 (half-hour increments) - 1
            divisions: 47,
            onChanged: (value) {
              onTimeChanged(_valueToTime(value));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeLabel(context, '12 AM'),
              _buildTimeLabel(context, '12 PM'),
              _buildTimeLabel(context, '11:30 PM'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
    );
  }
}

/// Reusable time slider that can be used independently
class TimeSliderWidget extends StatelessWidget {
  final String label;
  final TimeOfDay currentTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final Color? accentColor;

  const TimeSliderWidget({
    required this.label,
    required this.currentTime,
    required this.onTimeChanged,
    super.key,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final color = accentColor ??
        (isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLightTheme
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
          ),
        ),
        _TimeSlider(
          currentTime: currentTime,
          onTimeChanged: onTimeChanged,
          isLightTheme: isLightTheme,
          accentColor: color,
        ),
      ],
    );
  }
}
