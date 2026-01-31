import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_message_builder.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/widgets/stay_date_time_range_editor.dart';

/// Section for displaying and editing conflicting stays
class ConflictingStaysSection extends StatefulWidget {
  final List<EntityChange<LodgingFacade>> conflictingStays;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final VoidCallback onChanged;

  const ConflictingStaysSection({
    super.key,
    required this.conflictingStays,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onChanged,
  });

  @override
  State<ConflictingStaysSection> createState() =>
      _ConflictingStaysSectionState();
}

class _ConflictingStaysSectionState extends State<ConflictingStaysSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.conflictingStays.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, isLightTheme),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _buildInfoMessage(context, isLightTheme),
            const SizedBox(height: 12),
            ...widget.conflictingStays
                .map((item) => _buildStayItem(context, item, isLightTheme)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isLightTheme) {
    return EditorTheme.createSectionHeader(
      context,
      icon: Icons.hotel_rounded,
      title: ConflictMessageBuilder.buildSectionHeader(
        entityType: 'stay',
        count: widget.conflictingStays.length,
      ),
      iconColor:
          isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight,
      trailing: IconButton(
        icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
        onPressed: () => setState(() => _isExpanded = !_isExpanded),
      ),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
    );
  }

  Widget _buildInfoMessage(BuildContext context, bool isLightTheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.infoLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.infoLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ConflictMessageBuilder.buildActionMessage(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLightTheme
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStayItem(
    BuildContext context,
    EntityChange<LodgingFacade> item,
    bool isLightTheme,
  ) {
    final stay = item.modifiedEntity;
    final isMarkedForDeletion = item.isMarkedForDeletion;

    return Opacity(
      opacity: isMarkedForDeletion ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMarkedForDeletion
              ? (isLightTheme
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.errorLight.withValues(alpha: 0.1))
              : (isLightTheme
                  ? Colors.grey.shade100
                  : Colors.grey.shade800.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMarkedForDeletion
                ? (isLightTheme ? AppColors.error : AppColors.errorLight)
                : (isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700),
            width: isMarkedForDeletion ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemHeader(context, item, isLightTheme),
            if (!isMarkedForDeletion) ...[
              const SizedBox(height: 12),
              StayDateTimeRangeEditor(
                checkinDateTime: stay.checkinDateTime,
                checkoutDateTime: stay.checkoutDateTime,
                tripStartDate: widget.tripStartDate,
                tripEndDate: widget.tripEndDate,
                location: stay.location,
                showOriginalTimes: true,
                originalCheckinDateTime: item.originalEntity.checkinDateTime,
                originalCheckoutDateTime: item.originalEntity.checkoutDateTime,
                onCheckinChanged: (newDateTime) {
                  setState(() {
                    stay.checkinDateTime = newDateTime;
                  });
                  widget.onChanged();
                },
                onCheckoutChanged: (newDateTime) {
                  setState(() {
                    stay.checkoutDateTime = newDateTime;
                  });
                  widget.onChanged();
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              _buildOriginalTimeChip(context, item, isLightTheme),
              const SizedBox(height: 12),
              _buildDeletionMessage(context, isLightTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(
    BuildContext context,
    EntityChange<LodgingFacade> item,
    bool isLightTheme,
  ) {
    final isMarkedForDeletion = item.isMarkedForDeletion;

    return Row(
      children: [
        Icon(
          Icons.hotel_rounded,
          size: 20,
          color: isLightTheme
              ? AppColors.brandPrimary
              : AppColors.brandPrimaryLight,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.conflictDescription ?? 'Stay',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration:
                      isMarkedForDeletion ? TextDecoration.lineThrough : null,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildActionToggle(context, item),
      ],
    );
  }

  Widget _buildOriginalTimeChip(
    BuildContext context,
    EntityChange<LodgingFacade> item,
    bool isLightTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 14,
            color: isLightTheme ? AppColors.warning : AppColors.warningLight,
          ),
          const SizedBox(width: 4),
          Text(
            'Original: ${item.originalTimeDescription ?? 'No dates set'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isLightTheme ? AppColors.warning : AppColors.warningLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToggle(
    BuildContext context,
    EntityChange<LodgingFacade> item,
  ) {
    final isMarkedForDeletion = item.isMarkedForDeletion;

    return IconButton(
      icon: Icon(
        isMarkedForDeletion ? Icons.restore : Icons.delete_outline,
      ),
      tooltip: isMarkedForDeletion ? 'Restore this stay' : 'Delete this stay',
      onPressed: () {
        setState(() {
          if (isMarkedForDeletion) {
            item.restore();
          } else {
            item.markForDeletion();
          }
        });
        widget.onChanged();
      },
    );
  }

  Widget _buildDeletionMessage(BuildContext context, bool isLightTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.errorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_forever_rounded,
            size: 18,
            color: isLightTheme ? AppColors.error : AppColors.errorLight,
          ),
          const SizedBox(width: 8),
          Text(
            'This stay will be deleted when you save',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isLightTheme ? AppColors.error : AppColors.errorLight,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
