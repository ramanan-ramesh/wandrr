import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_theme_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/transit_journey_timeline_event.dart';

import 'constants.dart';

/// Widget for displaying connected transit journey legs
/// Shows connection lines between legs and layover information
class TransitJourneyTimelineItem extends StatelessWidget {
  final TransitJourneyTimelineEvent event;
  final bool isLastInTimeline;

  const TransitJourneyTimelineItem({
    required this.event,
    required this.isLastInTimeline,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show incoming connection line with layover (for middle/end positions)
        if (event.hasConnectionBefore)
          _JourneyConnectionLine(
            layoverDuration: event.layoverDuration,
          ),

        // The actual transit card
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConnectedTimelineIconColumn(
                event: event,
                isLastInTimeline: isLastInTimeline,
              ),
              Expanded(
                child: _ConnectedTransitCard(event: event),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Icon column for connected transit legs — includes departure time
class _ConnectedTimelineIconColumn extends StatelessWidget {
  final TransitJourneyTimelineEvent event;
  final bool isLastInTimeline;

  const _ConnectedTimelineIconColumn({
    required this.event,
    required this.isLastInTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final showConnector = !isLastInTimeline || event.hasConnectionAfter;
    final isLight = context.isLightTheme;
    final depTime = event.data.departureDateTime;
    final timeLabel = depTime?.hourMinuteAmPmFormat ?? '';

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          // Departure time above the icon
          if (timeLabel.isNotEmpty)
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
          if (timeLabel.isNotEmpty) const SizedBox(height: 4),
          _ConnectedTimelineIcon(event: event),
          if (showConnector)
            Expanded(
              child: _JourneyConnector(
                isPartOfJourney: event.hasConnectionAfter,
              ),
            ),
        ],
      ),
    );
  }
}

/// Icon for connected transit with journey indicator
class _ConnectedTimelineIcon extends StatelessWidget {
  final TransitJourneyTimelineEvent event;

  const _ConnectedTimelineIcon({required this.event});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    // Different styling based on position
    final isEndpoint = event.position == TravelLegConnectionPosition.start ||
        event.position == TravelLegConnectionPosition.end;

    return Container(
      width: TimelineConstants.iconContainerSize,
      height: TimelineConstants.iconContainerSize,
      decoration: BoxDecoration(
        color: themeHelper.getIconBackgroundColor(event.iconColor),
        shape: BoxShape.circle,
        border: Border.all(
          color: event.iconColor,
          width: isEndpoint ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: event.iconColor.withValues(alpha: 0.3),
            blurRadius: isEndpoint ? 8 : 4,
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

/// Connector line for journey legs
class _JourneyConnector extends StatelessWidget {
  final bool isPartOfJourney;

  const _JourneyConnector({required this.isPartOfJourney});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isPartOfJourney ? 4 : TimelineConstants.connectorWidth,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isPartOfJourney
            ? AppColors.info
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Connection line with layover duration between journey legs
class _JourneyConnectionLine extends StatelessWidget {
  final String? layoverDuration;

  const _JourneyConnectionLine({this.layoverDuration});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.isLightTheme;

    return Row(
      children: [
        // Spacer matching the icon column width (56) so we align with the card area
        const SizedBox(width: 56),
        // Layover duration badge shifted into the card region
        if (layoverDuration != null)
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? AppColors.warning.withValues(alpha: 0.15)
                    : AppColors.warningLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isLightTheme
                      ? AppColors.warning.withValues(alpha: 0.4)
                      : AppColors.warningLight.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 12,
                    color: isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Layover: $layoverDuration',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? AppColors.warning
                              : AppColors.warningLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact card for connected transit legs — unified surface with left accent bar
class _ConnectedTransitCard extends StatelessWidget {
  final TransitJourneyTimelineEvent event;

  const _ConnectedTransitCard({required this.event});

  String? _getPlatformSeatText(BuildContext context) {
    final activeUserName = context.activeUser?.userName;
    final isFlight = event.data.transitOption == TransitOption.flight;
    final label = isFlight ? 'Terminal' : 'Platform';
    final dep = event.data.departurePlatform;
    final arr = event.data.arrivalPlatform;

    final parts = <String>[];

    if (!event.isMultiDay) {
      final hasArrival = arr != null && arr.isNotEmpty;
      final hasDeparture = dep != null && dep.isNotEmpty;
      if (hasDeparture && hasArrival) {
        parts.add('$label: $dep → $arr');
      } else if (hasDeparture) {
        parts.add('Dep $label: $dep');
      } else if (hasArrival) {
        parts.add('Arr $label: $arr');
      }
    } else {
      final platform = event.isDepartureDayView ? dep : arr;
      if (platform != null && platform.isNotEmpty) {
        parts.add('$label: $platform');
      }
    }

    final seatNumbers = event.data.seatNumbers;
    if (seatNumbers != null && activeUserName != null) {
      final mySeat = seatNumbers[activeUserName];
      if (mySeat != null && mySeat.isNotEmpty) {
        parts.add('Seat: $mySeat');
      }
    }

    return parts.isEmpty ? null : parts.join(' • ');
  }

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(TimelineConstants.cardRadius);
    switch (event.position) {
      case TravelLegConnectionPosition.start:
        return const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        );
      case TravelLegConnectionPosition.middle:
        return BorderRadius.circular(4);
      case TravelLegConnectionPosition.end:
        return const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: radius,
          bottomRight: radius,
        );
      case TravelLegConnectionPosition.standalone:
        return BorderRadius.circular(TimelineConstants.cardRadius);
    }
  }

  String _getPositionLabel() {
    switch (event.position) {
      case TravelLegConnectionPosition.start:
        return '1';
      case TravelLegConnectionPosition.middle:
        final legIndex = event.journey.legs.indexOf(event.data) + 1;
        return '$legIndex';
      case TravelLegConnectionPosition.end:
        return '✓';
      case TravelLegConnectionPosition.standalone:
        return '';
    }
  }

  Color _positionBadgeColor(bool isLightTheme) {
    if (event.isMultiDay) {
      return event.isDepartureDayView
          ? (isLightTheme ? AppColors.success : AppColors.successLight)
          : (isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandPrimaryLight);
    }
    return isLightTheme ? AppColors.info : AppColors.infoLight;
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.isLightTheme;
    final isPartOfJourney =
        event.position != TravelLegConnectionPosition.standalone;
    final positionLabel = _getPositionLabel();

    final arrTime = event.data.arrivalDateTime;
    final depLocation = event.data.departureLocation?.toString() ?? '?';
    final arrLocation = event.data.arrivalLocation?.toString() ?? '?';

    // Arrival card = multi-day leg shown on the arrival day
    final isArrivalCard = event.isMultiDay && !event.isDepartureDayView;

    final subtitleColor =
        isLightTheme ? AppColors.neutral600 : AppColors.neutral400;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(
        left: 6,
        bottom: event.hasConnectionAfter ? 0 : TimelineConstants.spacing,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isLightTheme ? Colors.white : AppColors.darkSurface,
        borderRadius: _getBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: isLightTheme
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
          splashColor: AppColors.info.withValues(alpha: 0.15),
          highlightColor: AppColors.info.withValues(alpha: 0.08),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar (info blue for transit)
                  Container(width: 4, color: AppColors.info),
                  // Content — right padding reserves space for delete button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 40, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Compact leg position badge — just number or ✓, no extra labels
                          if (isPartOfJourney && positionLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _positionBadgeColor(isLightTheme),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: positionLabel == '✓'
                                    ? const Icon(Icons.check_rounded,
                                        size: 12, color: Colors.white)
                                    : Text(
                                        positionLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                              ),
                            ),

                          // ── Location lines ──
                          if (isArrivalCard) ...[
                            // Multi-day arrival card: "Arrive at Y" + "from X"
                            Text(
                              'Arrive at $arrLocation',
                              style: textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'from $depLocation',
                              style: textTheme.bodySmall
                                  ?.copyWith(color: subtitleColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else ...[
                            // Same-day or multi-day departure: "Depart from X"
                            Text(
                              'Depart from $depLocation',
                              style: textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // "Arrive at Y on <time>"
                            if (arrTime != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Arrive at $arrLocation on '
                                '${arrTime.hourMinuteAmPmFormat}',
                                style: textTheme.bodySmall
                                    ?.copyWith(color: subtitleColor),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],

                          // Operator / subtitle
                          if (event.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              event.subtitle,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: subtitleColor),
                            ),
                          ],

                          // Platform / seat info
                          if (_getPlatformSeatText(context) != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getPlatformSeatText(context)!,
                              style: textTheme.bodySmall?.copyWith(
                                color: isLightTheme
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          // Confirmation / notes indicators
                          if ((event.confirmationId?.isNotEmpty ?? false) ||
                              (event.notes?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (event.confirmationId?.isNotEmpty ?? false)
                                  Tooltip(
                                    message: event.confirmationId!,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                          Icons.confirmation_number_rounded,
                                          size: 14,
                                          color: AppColors.success),
                                    ),
                                  ),
                                if (event.notes?.isNotEmpty ?? false)
                                  Tooltip(
                                    message: event.notes!.length > 80
                                        ? '${event.notes!.substring(0, 80)}…'
                                        : event.notes!,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      child: Icon(Icons.sticky_note_2_rounded,
                                          size: 14,
                                          color: isLightTheme
                                              ? AppColors.neutral500
                                              : AppColors.neutral400),
                                    ),
                                  ),
                              ],
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
                child: Material(
                  color: AppColors.error
                      .withValues(alpha: isLightTheme ? 0.12 : 0.22),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => event.onDelete(context),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_rounded,
                          size: 14, color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
