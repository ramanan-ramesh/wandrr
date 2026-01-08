import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_model.dart';

class AffectedSightsSection extends StatefulWidget {
  final Iterable<AffectedEntityItem<SightFacade>> affectedSights;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final VoidCallback onChanged;

  const AffectedSightsSection({
    super.key,
    required this.affectedSights,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onChanged,
  });

  @override
  State<AffectedSightsSection> createState() => _AffectedSightsSectionState();
}

class _AffectedSightsSectionState extends State<AffectedSightsSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.affectedSights.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.attractions_rounded,
            title: 'Affected Sights (${widget.affectedSights.length})',
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
            _buildInfoMessage(context),
            const SizedBox(height: 12),
            ...widget.affectedSights
                .map((item) => _buildSightItem(context, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoMessage(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16,
                  color: isLightTheme ? AppColors.info : AppColors.infoLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These sights fall outside the new trip dates',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isLightTheme ? AppColors.info : AppColors.infoLight,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '• Visit dates have been cleared and need to be set again\n'
            '• Set new visit dates, or delete sights you no longer plan to visit\n'
            '• Sights without dates will remain in your itinerary but unscheduled',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLightTheme
                      ? Colors.grey.shade700
                      : Colors.grey.shade400,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSightItem(
      BuildContext context, AffectedEntityItem<SightFacade> item) {
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
                  child: Text(
                    sight.name.isNotEmpty ? sight.name : 'Unnamed Sight',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isMarkedForDeletion
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildActionToggle(context, item),
              ],
            ),
            if (sight.location != null) ...[
              const SizedBox(height: 4),
              Text(
                sight.location.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            _buildOriginalDateInfo(context, item.entity),
            if (!isMarkedForDeletion) ...[
              const SizedBox(height: 12),
              _buildDateRow(
                context: context,
                label: 'Visit Date',
                date: sight.visitTime,
                onChanged: (newDate) {
                  setState(() {
                    sight.visitTime = newDate;
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      sight.visitTime = null;
                    });
                    widget.onChanged();
                  },
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: isLightTheme
                        ? AppColors.warning
                        : AppColors.warningLight,
                  ),
                  label: Text(
                    'Clear date',
                    style: TextStyle(
                      color: isLightTheme
                          ? AppColors.warning
                          : AppColors.warningLight,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'This sight will be removed from itinerary',
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

  Widget _buildActionToggle(
      BuildContext context, AffectedEntityItem<SightFacade> item) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final isMarkedForDeletion = item.isMarkedForDeletion;

    return IconButton(
      icon: Icon(
        isMarkedForDeletion ? Icons.restore : Icons.delete_outline,
        color: isMarkedForDeletion
            ? (isLightTheme ? AppColors.success : AppColors.successLight)
            : (isLightTheme ? AppColors.error : AppColors.errorLight),
      ),
      tooltip: isMarkedForDeletion ? 'Restore' : 'Delete',
      onPressed: () {
        setState(() {
          item.action = isMarkedForDeletion
              ? AffectedEntityAction.update
              : AffectedEntityAction.delete;
        });
        widget.onChanged();
      },
    );
  }

  Widget _buildOriginalDateInfo(BuildContext context, SightFacade original) {
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
            'Was on: ${original.day.dayDateMonthFormat}${original.visitTime != null ? ' at ${original.visitTime!.hour}:${original.visitTime!.minute.toString().padLeft(2, '0')}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isLightTheme ? AppColors.warning : AppColors.warningLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required Function(DateTime) onChanged,
  }) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 18,
          color: isLightTheme ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        PlatformDatePicker(
          selectedDate: date,
          onDateSelected: onChanged,
        ),
      ],
    );
  }
}
