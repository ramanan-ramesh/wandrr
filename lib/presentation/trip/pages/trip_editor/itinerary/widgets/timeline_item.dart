import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/location.dart';
import 'package:wandrr/data/trip/models/location/location_timezone_date_time.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_theme_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart';

import 'constants.dart';

/// Widget for displaying a single timeline item
class TimelineItem extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const TimelineItem({
    required this.event,
    required this.isLast,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineIconColumn(event: event, isLast: isLast),
          Expanded(child: _TimelineEventCard(event: event)),
        ],
      ),
    );
  }
}

/// Timeline icon column with connector and time label
class _TimelineIconColumn extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineIconColumn({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = LocationTimezoneDateTime.formatHourMinuteAmPm(
      storedDateTime: event.time,
      location: _eventLocation(event),
    );
    final isLight = context.isLightTheme;

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          // Time label above the icon
          Text(
            timeLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isLight ? AppColors.neutral700 : AppColors.neutral300,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          _TimelineIcon(event: event),
          if (!isLast) _TimelineConnector(),
        ],
      ),
    );
  }

  LocationFacade? _eventLocation(TimelineEvent event) {
    final data = event.data;
    if (data is LodgingFacade) {
      return data.location;
    }
    if (data is SightFacade) {
      return data.location;
    }
    return null;
  }
}

/// Timeline icon with styled container
class _TimelineIcon extends StatelessWidget {
  final TimelineEvent event;

  const _TimelineIcon({required this.event});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    return Container(
      width: TimelineConstants.iconContainerSize,
      height: TimelineConstants.iconContainerSize,
      decoration: BoxDecoration(
        color: themeHelper.getIconBackgroundColor(event.iconColor),
        shape: BoxShape.circle,
        border: Border.all(
          color: event.iconColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: event.iconColor.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        event.icon,
        color: event.iconColor,
        size: TimelineConstants.iconSize,
      ),
    );
  }
}

/// Connector line between timeline icons
class _TimelineConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    return Expanded(
      child: Container(
        width: TimelineConstants.connectorWidth,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: themeHelper.getTimelineConnectorColor(),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Card displaying event details — immersive surface with left accent bar
class _TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;

  const _TimelineEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);
    final isLight = context.isLightTheme;

    return Container(
      margin: const EdgeInsets.only(
        left: 6,
        bottom: TimelineConstants.spacing,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // White cards against grey scaffold → strong contrast
        color: isLight ? Colors.white : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(TimelineConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => event.onPressed(context),
          splashColor: event.iconColor.withValues(alpha: 0.15),
          highlightColor: event.iconColor.withValues(alpha: 0.08),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: event.iconColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(TimelineConstants.cardRadius),
                        bottomLeft:
                            Radius.circular(TimelineConstants.cardRadius),
                      ),
                    ),
                  ),
                  // Content — right padding reserves space for the delete button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 38, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title row with indicator icons (no delete here)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: themeHelper.getTextColor(),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Icon-only indicators for confirmation & notes
                              if (event.confirmationId?.isNotEmpty ?? false)
                                _IconIndicator(
                                  icon: Icons.confirmation_number_rounded,
                                  color: AppColors.success,
                                  tooltip: event.confirmationId!,
                                ),
                              if (event.notes?.isNotEmpty ?? false)
                                _IconIndicator(
                                  icon: Icons.sticky_note_2_rounded,
                                  color: themeHelper.getSubtitleColor(),
                                  tooltip: event.notes!.length > 80
                                      ? '${event.notes!.substring(0, 80)}…'
                                      : event.notes!,
                                ),
                            ],
                          ),
                          if (event.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              event.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: themeHelper.getSubtitleColor(),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Delete button always pinned to top-right corner
              Positioned(
                top: 4,
                right: 4,
                child: _DeleteButton(event: event),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact icon indicator with tooltip (for confirmation ID, notes)
class _IconIndicator extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;

  const _IconIndicator({
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Delete button for event — prominent with clear contrast and adequate tap target
class _DeleteButton extends StatelessWidget {
  final TimelineEvent event;

  const _DeleteButton({required this.event});

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          AppColors.error.withValues(alpha: context.isLightTheme ? 0.12 : 0.22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => event.onDelete(context),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.delete_rounded,
            size: 16,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}
