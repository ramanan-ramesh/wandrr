import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';

class DateTimeSelector extends StatefulWidget {
  final DateTime? checkinDateTime;
  final DateTime? checkoutDateTime;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onCheckinChanged;
  final ValueChanged<DateTime> onCheckoutChanged;
  final int defaultCheckinHour;
  final int defaultCheckoutHour;

  const DateTimeSelector({
    required this.checkinDateTime,
    required this.checkoutDateTime,
    required this.firstDate,
    required this.lastDate,
    required this.onCheckinChanged,
    required this.onCheckoutChanged,
    this.defaultCheckinHour = 8,
    this.defaultCheckoutHour = 8,
    super.key,
  });

  @override
  State<DateTimeSelector> createState() => _DateTimeSelectorState();
}

class _DateTimeSelectorState extends State<DateTimeSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateRangePicker(),
        if (_areDatesSelected) ...[
          const SizedBox(height: 20),
          _buildTimeSliders(),
          const SizedBox(height: 16),
          _DurationIndicator(
            startDateTime: widget.checkinDateTime!,
            endDateTime: widget.checkoutDateTime!,
          ),
        ],
      ],
    );
  }

  bool get _areDatesSelected =>
      widget.checkinDateTime != null && widget.checkoutDateTime != null;

  Widget _buildDateRangePicker() {
    return PlatformDateRangePicker(
      startDate: widget.checkinDateTime,
      endDate: widget.checkoutDateTime,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      callback: _handleDateRangeChanged,
    );
  }

  void _handleDateRangeChanged(DateTime? newStartDate, DateTime? newEndDate) {
    if (newStartDate == null || newEndDate == null) return;
    final checkinHour =
        widget.checkinDateTime?.hour ?? widget.defaultCheckinHour;
    final checkinMinute = widget.checkinDateTime?.minute ?? 0;
    final checkoutHour =
        widget.checkoutDateTime?.hour ?? widget.defaultCheckoutHour;
    final checkoutMinute = widget.checkoutDateTime?.minute ?? 0;
    widget.onCheckinChanged(DateTime(
      newStartDate.year,
      newStartDate.month,
      newStartDate.day,
      checkinHour,
      checkinMinute,
    ));
    widget.onCheckoutChanged(DateTime(
      newEndDate.year,
      newEndDate.month,
      newEndDate.day,
      checkoutHour,
      checkoutMinute,
    ));
  }

  Widget _buildTimeSliders() {
    return Column(
      children: [
        _TimeSlider(
          label: 'Check-in at',
          icon: Icons.login_rounded,
          iconColor: AppColors.success,
          dateTime: widget.checkinDateTime!,
          onChanged: (newHour) {
            final current = widget.checkinDateTime!;
            widget.onCheckinChanged(DateTime(
              current.year,
              current.month,
              current.day,
              newHour.toInt(),
              0,
            ));
          },
        ),
        const SizedBox(height: 20),
        _TimeSlider(
          label: 'Check-out at',
          icon: Icons.logout_rounded,
          iconColor: AppColors.warning,
          dateTime: widget.checkoutDateTime!,
          onChanged: (newHour) {
            final current = widget.checkoutDateTime!;
            widget.onCheckoutChanged(DateTime(
              current.year,
              current.month,
              current.day,
              newHour.toInt(),
              0,
            ));
          },
        ),
      ],
    );
  }
}

class _TimeSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final DateTime dateTime;
  final ValueChanged<double> onChanged;
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _slowAnimationDuration = Duration(milliseconds: 400);

  const _TimeSlider({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.dateTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final hour = dateTime.hour;
    final timeString = _formatTime(hour);
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
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
          _buildHeader(context, isLightTheme, timeString),
          const SizedBox(height: 12),
          _buildSlider(),
          _buildTimeLabels(context, isLightTheme),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isLightTheme, String timeString) {
    return Row(
      children: [
        _buildAnimatedIcon(),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isLightTheme ? AppColors.neutral700 : AppColors.neutral300,
              ),
        ),
        const SizedBox(width: 8),
        _buildTimeBadge(context, timeString),
      ],
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      duration: _animationDuration,
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildTimeBadge(BuildContext context, String timeString) {
    return AnimatedSwitcher(
      duration: _slowAnimationDuration,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(timeString),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Text(
          timeString,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return Builder(
      builder: (context) {
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: iconColor,
            inactiveTrackColor: iconColor.withValues(alpha: 0.2),
            thumbColor: iconColor,
            overlayColor: iconColor.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: dateTime.hour.toDouble(),
            min: 0,
            max: 23,
            divisions: 23,
            onChanged: onChanged,
          ),
        );
      },
    );
  }

  Widget _buildTimeLabels(BuildContext context, bool isLightTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeLabel(context, '12 AM', isLightTheme),
          _buildTimeLabel(context, '12 PM', isLightTheme),
          _buildTimeLabel(context, '11 PM', isLightTheme),
        ],
      ),
    );
  }

  Widget _buildTimeLabel(
      BuildContext context, String label, bool isLightTheme) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.neutral500,
            fontSize: 10,
          ),
    );
  }

  String _formatTime(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
}

class _DurationIndicator extends StatelessWidget {
  final DateTime startDateTime;
  final DateTime endDateTime;
  static const Duration _scaleAnimationDuration = Duration(milliseconds: 600);
  static const Duration _containerAnimationDuration =
      Duration(milliseconds: 400);
  static const Duration _textAnimationDuration = Duration(milliseconds: 400);
  static const Duration _rotationAnimationDuration =
      Duration(milliseconds: 800);

  const _DurationIndicator({
    required this.startDateTime,
    required this.endDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final durationText = _calculateDurationText();
    return TweenAnimationBuilder<double>(
      duration: _scaleAnimationDuration,
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: _containerAnimationDuration,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: _buildDecoration(isLightTheme),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRotatingIcon(isLightTheme),
                const SizedBox(width: 12),
                _buildDurationText(context, isLightTheme, durationText),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildDecoration(bool isLightTheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.info.withValues(alpha: isLightTheme ? 0.15 : 0.25),
          AppColors.infoLight.withValues(alpha: isLightTheme ? 0.08 : 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.3)
            : AppColors.infoLight.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.info.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildRotatingIcon(bool isLightTheme) {
    return TweenAnimationBuilder<double>(
      duration: _rotationAnimationDuration,
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 6.28,
          child: Icon(
            Icons.schedule_rounded,
            size: 22,
            color: isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
        );
      },
    );
  }

  Widget _buildDurationText(
      BuildContext context, bool isLightTheme, String durationText) {
    return AnimatedSwitcher(
      duration: _textAnimationDuration,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        durationText,
        key: ValueKey(durationText),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLightTheme ? AppColors.info : AppColors.infoLight,
              letterSpacing: 0.3,
            ),
      ),
    );
  }

  String _calculateDurationText() {
    final days = endDateTime.calculateDaysInBetween(startDateTime);
    return '$days ${days == 1 ? 'day' : 'days'}';
  }
}
