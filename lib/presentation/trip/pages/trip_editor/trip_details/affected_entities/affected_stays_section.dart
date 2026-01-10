import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_model.dart';

class AffectedStaysSection extends StatefulWidget {
  final Iterable<AffectedEntityItem<LodgingFacade>> affectedStays;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final VoidCallback onChanged;

  const AffectedStaysSection({
    super.key,
    required this.affectedStays,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onChanged,
  });

  @override
  State<AffectedStaysSection> createState() => _AffectedStaysSectionState();
}

class _AffectedStaysSectionState extends State<AffectedStaysSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.affectedStays.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.hotel_rounded,
            title: 'Affected Stays (${widget.affectedStays.length})',
            iconColor: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
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
            ...widget.affectedStays
                .map((item) => _buildStayItem(context, item)),
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
                  'These stays fall outside the new trip dates',
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
            '• Dates have been adjusted to fit within the new trip range where possible\n'
            '• Set new check-in/check-out dates, or delete stays you no longer need\n'
            '• Stays without valid dates will be skipped',
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

  Widget _buildStayItem(
      BuildContext context, AffectedEntityItem<LodgingFacade> item) {
    final lodging = item.modifiedEntity;
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
                  Icons.location_on,
                  size: 18,
                  color: isLightTheme
                      ? AppColors.brandPrimary
                      : AppColors.brandPrimaryLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lodging.location?.toString() ?? 'Unknown Location',
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
            const SizedBox(height: 8),
            _buildOriginalDatesInfo(context, item.entity),
            if (!isMarkedForDeletion) ...[
              const SizedBox(height: 12),
              _buildDateTimeRow(
                context: context,
                label: 'Check-in',
                icon: Icons.login_rounded,
                dateTime: lodging.checkinDateTime,
                startDateTime: widget.tripStartDate,
                onChanged: (newDateTime) {
                  setState(() {
                    lodging.checkinDateTime = newDateTime;
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 8),
              _buildDateTimeRow(
                context: context,
                label: 'Check-out',
                icon: Icons.logout_rounded,
                dateTime: lodging.checkoutDateTime,
                startDateTime: lodging.checkinDateTime != null
                    ? lodging.checkinDateTime!.add(Duration(hours: 1))
                    : widget.tripStartDate.add(Duration(hours: 1)),
                onChanged: (newDateTime) {
                  setState(() {
                    lodging.checkoutDateTime = newDateTime;
                  });
                  widget.onChanged();
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'This stay will be deleted',
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
      BuildContext context, AffectedEntityItem<LodgingFacade> item) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final isMarkedForDeletion = item.isMarkedForDeletion;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
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
        ),
      ],
    );
  }

  Widget _buildOriginalDatesInfo(BuildContext context, LodgingFacade original) {
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
            'Was: ${original.checkinDateTime?.dayDateMonthFormat ?? 'N/A'} - ${original.checkoutDateTime?.dayDateMonthFormat ?? 'N/A'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isLightTheme ? AppColors.warning : AppColors.warningLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required DateTime? dateTime,
    required DateTime startDateTime,
    required Function(DateTime) onChanged,
  }) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isLightTheme ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        PlatformDateTimePicker(
          currentDateTime: dateTime,
          startDateTime: startDateTime,
          endDateTime: DateTime(widget.tripEndDate.year,
              widget.tripEndDate.month, widget.tripEndDate.day, 23, 59),
          dateTimeUpdated: onChanged,
        ),
      ],
    );
  }
}
