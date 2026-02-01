import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_message_builder.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';

/// Section for displaying and editing conflicting sights
class ConflictingSightsSection extends StatefulWidget {
  final List<EntityChange<SightFacade>> conflictingSights;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final VoidCallback onChanged;

  const ConflictingSightsSection({
    super.key,
    required this.conflictingSights,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onChanged,
  });

  @override
  State<ConflictingSightsSection> createState() =>
      _ConflictingSightsSectionState();
}

class _ConflictingSightsSectionState extends State<ConflictingSightsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.conflictingSights.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.place_rounded,
            title: ConflictMessageBuilder.buildSectionHeader(
              entityType: 'sight',
              count: widget.conflictingSights.length,
            ),
            iconColor:
                isLightTheme ? AppColors.success : AppColors.successLight,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _buildInfoMessage(context, isLightTheme),
            const SizedBox(height: 12),
            ...widget.conflictingSights
                .map((item) => _buildSightItem(context, item)),
          ],
        ],
      ),
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

  Widget _buildSightItem(BuildContext context, EntityChange<SightFacade> item) {
    final sight = item.modifiedEntity;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
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
            Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 18,
                  color:
                      isLightTheme ? AppColors.success : AppColors.successLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.conflictDescription ?? sight.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isMarkedForDeletion
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Day: ${sight.day.dayDateMonthFormat}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isLightTheme
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildActionToggle(context, item),
              ],
            ),
            const SizedBox(height: 8),
            _buildOriginalTimeInfo(
                context, item.originalTimeDescription ?? 'No time set'),
            if (!isMarkedForDeletion) ...[
              const SizedBox(height: 12),
              _buildVisitTimeRow(context, sight),
            ] else ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Will be deleted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isLightTheme
                            ? AppColors.error
                            : AppColors.errorLight,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTimeRow(BuildContext context, SightFacade sight) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 18,
          color: isLightTheme ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          'Visit time:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        PlatformDateTimePicker(
          currentDateTime: sight.visitTime,
          startDateTime: DateTime(
            sight.day.year,
            sight.day.month,
            sight.day.day,
            0,
            0,
          ),
          endDateTime: DateTime(
            sight.day.year,
            sight.day.month,
            sight.day.day,
            23,
            59,
          ),
          dateTimeUpdated: (newDateTime) {
            setState(() {
              sight.visitTime = newDateTime;
            });
            widget.onChanged();
          },
        ),
        const SizedBox(width: 8),
        if (sight.visitTime != null)
          IconButton(
            icon: Icon(
              Icons.clear_rounded,
              size: 18,
              color: isLightTheme ? AppColors.warning : AppColors.warningLight,
            ),
            tooltip: 'Clear time',
            onPressed: () {
              setState(() {
                sight.visitTime = null;
              });
              widget.onChanged();
            },
          ),
      ],
    );
  }

  Widget _buildActionToggle(
      BuildContext context, EntityChange<SightFacade> item) {
    final isMarkedForDeletion = item.isMarkedForDeletion;

    return IconButton(
      icon: Icon(
        isMarkedForDeletion ? Icons.restore : Icons.delete_outline,
      ),
      tooltip: isMarkedForDeletion ? 'Restore' : 'Delete',
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

  Widget _buildOriginalTimeInfo(BuildContext context, String originalTime) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
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
            'Was: $originalTime',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isLightTheme ? AppColors.warning : AppColors.warningLight,
                ),
          ),
        ],
      ),
    );
  }
}
