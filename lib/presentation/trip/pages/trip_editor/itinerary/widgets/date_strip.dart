import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// Horizontal scrollable date strip that shows all trip days as compact chips.
/// Each chip has two lines: day name abbreviation + date number (e.g. "Sat" / "30")
/// and a subtitle showing the month (e.g. "Jan").
/// Rounded chevron buttons at each end for quick scrolling.
class DateStrip extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateStrip({
    required this.startDate,
    required this.endDate,
    required this.selectedDate,
    required this.onDateSelected,
    super.key,
  });

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  late final ScrollController _scrollController;
  static const double _chipWidth = 56.0;
  static const double _chipSpacing = 6.0;

  List<DateTime> get _dates {
    final dates = <DateTime>[];
    var d = DateTime(
        widget.startDate.year, widget.startDate.month, widget.startDate.day);
    final end =
        DateTime(widget.endDate.year, widget.endDate.month, widget.endDate.day);
    while (!d.isAfter(end)) {
      dates.add(d);
      d = d.add(const Duration(days: 1));
    }
    return dates;
  }

  int get _selectedIndex {
    final dates = _dates;
    for (var i = 0; i < dates.length; i++) {
      if (dates[i].isOnSameDayAs(widget.selectedDate)) {
        return i;
      }
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant DateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selectedDate.isOnSameDayAs(widget.selectedDate)) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) {
      return;
    }
    final index = _selectedIndex;
    final offset = index * (_chipWidth + _chipSpacing) -
        (_scrollController.position.viewportDimension / 2) +
        (_chipWidth / 2);
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      (_scrollController.offset + delta)
          .clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    final dates = _dates;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // Pure white on light / slightly elevated dark surface — distinct from
        // the grey timeline area below and the AppBar above.
        color: isLight ? Colors.white : AppColors.darkSurfaceHeader,
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left chevron
          _ChevronButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () => _scrollBy(-(_chipWidth + _chipSpacing) * 3),
          ),
          // Scrollable date chips
          Expanded(
            child: SizedBox(
              height: 58,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: dates.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: _chipSpacing),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isSelected = date.isOnSameDayAs(widget.selectedDate);
                  final isToday = date.isOnSameDayAs(DateTime.now());
                  return _DateChip(
                    date: date,
                    isSelected: isSelected,
                    isToday: isToday,
                    width: _chipWidth,
                    onTap: () => widget.onDateSelected(date),
                  );
                },
              ),
            ),
          ),
          // Right chevron
          _ChevronButton(
            icon: Icons.chevron_right_rounded,
            onPressed: () => _scrollBy((_chipWidth + _chipSpacing) * 3),
          ),
        ],
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ChevronButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isLight ? AppColors.neutral200 : AppColors.darkSurface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 22,
              color: isLight ? AppColors.neutral700 : AppColors.neutral300,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final double width;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = context.isLightTheme;
    final dayLabel = date.dayFormat; // "Sat"
    final dateNum = date.day.toString(); // "30"
    final monthLabel = date.monthFormat; // "Jan"

    final selectedBg =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
    final todayBorder =
        isLight ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: width,
        decoration: BoxDecoration(
          color: isSelected
              ? selectedBg
              : (isLight ? Colors.white : AppColors.darkSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? selectedBg
                : isToday
                    ? todayBorder
                    : (isLight ? AppColors.neutral300 : AppColors.neutral600),
            width: isSelected || isToday ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Sat 30"
            Text(
              '$dayLabel $dateNum',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isLight ? Colors.white : AppColors.brandSecondary)
                    : (isLight ? AppColors.neutral800 : AppColors.neutral200),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            // "Jan"
            Text(
              monthLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? (isLight
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.brandSecondary.withValues(alpha: 0.7))
                    : (isLight ? AppColors.neutral500 : AppColors.neutral400),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
