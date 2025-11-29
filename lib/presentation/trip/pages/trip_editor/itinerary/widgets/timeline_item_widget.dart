import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/helpers/timeline_theme_helper.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/timeline_event.dart';

/// Constants for timeline styling
class TimelineConstants {
  static const double iconSize = 24;
  static const double iconContainerSize = 48;
  static const double connectorWidth = 4;
  static const double cardBorderWidth = 1.5;
  static const double cardRadius = 16;
  static const double cardPadding = 16;
  static const double spacing = 16;
  static const int notesMaxLength = 150;
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
      width: 60,
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
            color: event.iconColor.withValues(alpha: 0.3),
            blurRadius: 8,
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventHeader(event: event),
          if (event.subtitle.isNotEmpty)
            _EventSubtitle(subtitle: event.subtitle),
          if (event.confirmationId?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _ConfirmationChip(confirmationId: event.confirmationId!),
            const SizedBox(height: 8),
          ],
          if (event.notes?.isNotEmpty ?? false)
            _EventNotes(notes: event.notes!),
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

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
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
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
