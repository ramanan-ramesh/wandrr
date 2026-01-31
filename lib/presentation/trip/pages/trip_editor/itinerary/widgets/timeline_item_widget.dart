import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_theme_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart';

/// Constants for timeline styling
class TimelineConstants {
  static const double iconSize = 20;
  static const double iconContainerSize = 40;
  static const double connectorWidth = 3;
  static const double cardBorderWidth = 1;
  static const double cardRadius = 12;
  static const double cardPadding = 12;
  static const double spacing = 12;
  static const int notesMaxLength = 120;
}

/// Widget for displaying a single timeline item
class TimelineItemWidget extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const TimelineItemWidget({
    required this.event,
    required this.isLast,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: GestureDetector(
        onTap: () => event.onPressed(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimelineIconColumn(event: event, isLast: isLast),
            Expanded(child: _TimelineEventCard(event: event)),
          ],
        ),
      ),
    );
  }
}

/// Timeline icon column with connector
class _TimelineIconColumn extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineIconColumn({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          _TimelineIcon(event: event),
          if (!isLast) _TimelineConnector(),
        ],
      ),
    );
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

/// Card displaying event details
class _TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;

  const _TimelineEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    return Container(
      margin: const EdgeInsets.only(
        left: 8,
        bottom: TimelineConstants.spacing,
      ),
      padding: const EdgeInsets.all(TimelineConstants.cardPadding),
      decoration: BoxDecoration(
        color: themeHelper.getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(TimelineConstants.cardRadius),
        border: Border.all(
          color: themeHelper.getCardBorderColor(),
          width: TimelineConstants.cardBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: themeHelper.getCardShadowColor(),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventHeader(event: event),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.subtitle.isNotEmpty)
                      _EventSubtitle(subtitle: event.subtitle),
                    if (event.confirmationId?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      _ConfirmationChip(confirmationId: event.confirmationId!),
                    ],
                  ],
                ),
              ),
              if (event.notes?.isNotEmpty ?? false) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: _EventNotes(notes: event.notes!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Event header with title and delete button
class _EventHeader extends StatelessWidget {
  final TimelineEvent event;

  const _EventHeader({required this.event});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            event.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: themeHelper.getTextColor(),
                ),
          ),
        ),
        const SizedBox(width: 8),
        _DeleteButton(event: event),
      ],
    );
  }
}

/// Delete button for event
class _DeleteButton extends StatelessWidget {
  final TimelineEvent event;

  const _DeleteButton({required this.event});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    return GestureDetector(
      onTap: () => event.onDelete(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: themeHelper.getDeleteButtonBackgroundColor(),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.delete_outline,
          size: 18,
          color: AppColors.error,
        ),
      ),
    );
  }
}

/// Event subtitle text
class _EventSubtitle extends StatelessWidget {
  final String subtitle;

  const _EventSubtitle({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeHelper.getSubtitleColor(),
            ),
      ),
    );
  }
}

/// Confirmation ID chip
class _ConfirmationChip extends StatelessWidget {
  final String confirmationId;

  const _ConfirmationChip({required this.confirmationId});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = context.isLightTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: isLightTheme ? 0.12 : 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: isLightTheme ? 0.4 : 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_rounded,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              confirmationId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Event notes display
class _EventNotes extends StatelessWidget {
  final String notes;

  const _EventNotes({required this.notes});

  String _truncateNotes(String notes) {
    if (notes.length <= TimelineConstants.notesMaxLength) {
      return notes;
    }
    return '${notes.substring(0, TimelineConstants.notesMaxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeHelper.getNotesBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _truncateNotes(notes),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeHelper.getSubtitleColor(),
              fontStyle: FontStyle.italic,
            ),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Widget for displaying connected transit journey legs
/// Shows connection lines between legs and layover information
class ConnectedTimelineItemWidget extends StatelessWidget {
  final ConnectedTransitTimelineEvent event;
  final bool isLastInTimeline;

  const ConnectedTimelineItemWidget({
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
          child: GestureDetector(
            onTap: () => event.onPressed(context),
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
        ),
      ],
    );
  }
}

/// Icon column for connected transit legs
class _ConnectedTimelineIconColumn extends StatelessWidget {
  final ConnectedTransitTimelineEvent event;
  final bool isLastInTimeline;

  const _ConnectedTimelineIconColumn({
    required this.event,
    required this.isLastInTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final showConnector = !isLastInTimeline || event.hasConnectionAfter;

    return SizedBox(
      width: 48,
      child: Column(
        children: [
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
  final ConnectedTransitTimelineEvent event;

  const _ConnectedTimelineIcon({required this.event});

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);

    // Different styling based on position
    final isEndpoint = event.position == ConnectionPosition.start ||
        event.position == ConnectionPosition.end;

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

    return Container(
      margin: const EdgeInsets.only(left: 22),
      child: Row(
        children: [
          // Vertical dotted/dashed connection
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Layover duration badge
          if (layoverDuration != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
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
      ),
    );
  }
}

/// Compact card for connected transit legs
class _ConnectedTransitCard extends StatelessWidget {
  final ConnectedTransitTimelineEvent event;

  const _ConnectedTransitCard({required this.event});

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(TimelineConstants.cardRadius);
    switch (event.position) {
      case ConnectionPosition.start:
        return const BorderRadius.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        );
      case ConnectionPosition.middle:
        return BorderRadius.circular(4);
      case ConnectionPosition.end:
        return const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: radius,
          bottomRight: radius,
        );
      case ConnectionPosition.standalone:
        return BorderRadius.circular(TimelineConstants.cardRadius);
    }
  }

  String _getPositionLabel() {
    switch (event.position) {
      case ConnectionPosition.start:
        return 'LEG 1';
      case ConnectionPosition.middle:
        final legIndex = event.journey.legs.indexOf(event.data) + 1;
        return 'LEG $legIndex';
      case ConnectionPosition.end:
        return 'FINAL';
      case ConnectionPosition.standalone:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeHelper = TimelineThemeHelper(context);
    final isLightTheme = context.isLightTheme;
    final isPartOfJourney = event.position != ConnectionPosition.standalone;
    final positionLabel = _getPositionLabel();

    return Container(
      margin: EdgeInsets.only(
        left: 8,
        bottom: event.hasConnectionAfter ? 0 : TimelineConstants.spacing,
        top: event.hasConnectionBefore ? 0 : 0,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeHelper.getCardBackgroundColor(),
        borderRadius: _getBorderRadius(),
        border: Border.all(
          color: isPartOfJourney
              ? AppColors.info.withValues(alpha: 0.6)
              : AppColors.info.withValues(alpha: 0.4),
          width: isPartOfJourney ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeHelper.getCardShadowColor(),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Journey position indicator (for multi-leg journeys)
          if (isPartOfJourney && positionLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLightTheme
                          ? AppColors.info.withValues(alpha: 0.15)
                          : AppColors.infoLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.connecting_airports_rounded,
                          size: 10,
                          color: isLightTheme
                              ? AppColors.info
                              : AppColors.infoLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          positionLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isLightTheme
                                        ? AppColors.info
                                        : AppColors.infoLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Total legs indicator (on first leg only)
                  if (event.position == ConnectionPosition.start)
                    Text(
                      '${event.journey.legs.length} stops',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isLightTheme
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                            fontSize: 10,
                          ),
                    ),
                ],
              ),
            ),
          // Main content row
          Row(
            children: [
              // Transit icon
              Icon(
                event.icon,
                size: 18,
                color: event.iconColor,
              ),
              const SizedBox(width: 10),
              // Route info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isLightTheme
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                    ),
                  ],
                ),
              ),
              // Confirmation ID badge (compact)
              if (event.confirmationId?.isNotEmpty ?? false)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.confirmationId!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                  ),
                ),
              const SizedBox(width: 4),
              // Chevron for tap indication
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
