import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_model.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_expenses_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_sights_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_stays_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_transits_section.dart';

/// Editor for adjusting affected entities when trip metadata changes
class AffectedEntitiesEditor extends StatefulWidget {
  final AffectedEntitiesModel affectedEntitiesModel;
  final VoidCallback onModelUpdated;

  const AffectedEntitiesEditor({
    super.key,
    required this.affectedEntitiesModel,
    required this.onModelUpdated,
  });

  @override
  State<AffectedEntitiesEditor> createState() => _AffectedEntitiesEditorState();
}

class _AffectedEntitiesEditorState extends State<AffectedEntitiesEditor> {
  @override
  Widget build(BuildContext context) {
    final model = widget.affectedEntitiesModel;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryHeader(context, isLightTheme),
        const SizedBox(height: 16),
        if (model.hasDateChanges) _buildDateChangesInfo(context, isLightTheme),
        if (model.hasContributorChanges)
          _buildContributorChangesInfo(context, isLightTheme),
        const SizedBox(height: 8),
        AffectedStaysSection(
          affectedStays: model.affectedStays,
          tripStartDate: model.newMetadata.startDate!,
          tripEndDate: model.newMetadata.endDate!,
          onChanged: widget.onModelUpdated,
        ),
        AffectedTransitsSection(
          affectedTransits: model.affectedTransits,
          tripStartDate: model.newMetadata.startDate!,
          tripEndDate: model.newMetadata.endDate!,
          onChanged: widget.onModelUpdated,
        ),
        AffectedSightsSection(
          affectedSights: model.affectedSights,
          tripStartDate: model.newMetadata.startDate!,
          tripEndDate: model.newMetadata.endDate!,
          onChanged: widget.onModelUpdated,
        ),
        AffectedExpensesSection(
          allExpenses: model.allExpenses,
          addedContributors: model.addedContributors,
          removedContributors: model.removedContributors,
          onChanged: widget.onModelUpdated,
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(BuildContext context, bool isLightTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLightTheme
              ? [
                  AppColors.brandPrimary.withValues(alpha: 0.1),
                  AppColors.brandPrimaryLight.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.brandPrimaryDark.withValues(alpha: 0.3),
                  AppColors.brandPrimary.withValues(alpha: 0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLightTheme
              ? AppColors.brandPrimary.withValues(alpha: 0.2)
              : AppColors.brandPrimaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isLightTheme
                    ? AppColors.brandPrimary
                    : AppColors.brandPrimaryLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Review Affected Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme
                            ? AppColors.brandPrimary
                            : AppColors.brandPrimaryLight,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Some items in your trip need attention after the changes. '
            'Please review and update them as needed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isLightTheme
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChangesInfo(BuildContext context, bool isLightTheme) {
    final model = widget.affectedEntitiesModel;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.infoLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.infoLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range_rounded,
            color: isLightTheme ? AppColors.info : AppColors.infoLight,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip dates changed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isLightTheme ? AppColors.info : AppColors.infoLight,
                      ),
                ),
                Text(
                  '${_formatDate(model.oldMetadata.startDate)} - ${_formatDate(model.oldMetadata.endDate)} → ${_formatDate(model.newMetadata.startDate)} - ${_formatDate(model.newMetadata.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLightTheme
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorChangesInfo(BuildContext context, bool isLightTheme) {
    final model = widget.affectedEntitiesModel;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.successLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.successLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_rounded,
            color: isLightTheme ? AppColors.success : AppColors.successLight,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tripmates changed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLightTheme
                            ? AppColors.success
                            : AppColors.successLight,
                      ),
                ),
                if (model.addedContributors.isNotEmpty)
                  Text(
                    'Added: ${model.addedContributors.join(", ")}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? Colors.grey.shade700
                              : Colors.grey.shade400,
                        ),
                  ),
                if (model.removedContributors.isNotEmpty)
                  Text(
                    'Removed: ${model.removedContributors.join(", ")}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? AppColors.error
                              : AppColors.errorLight,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
