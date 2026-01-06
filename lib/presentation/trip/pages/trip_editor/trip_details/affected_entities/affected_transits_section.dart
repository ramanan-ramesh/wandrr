import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/date_time_picker.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_model.dart';

class AffectedTransitsSection extends StatefulWidget {
  final List<AffectedEntityItem<TransitFacade>> affectedTransits;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final VoidCallback onChanged;

  const AffectedTransitsSection({
    super.key,
    required this.affectedTransits,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onChanged,
  });

  @override
  State<AffectedTransitsSection> createState() =>
      _AffectedTransitsSectionState();
}

class _AffectedTransitsSectionState extends State<AffectedTransitsSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.affectedTransits.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.directions_transit_rounded,
            title: 'Affected Transits (${widget.affectedTransits.length})',
            iconColor: isLightTheme ? AppColors.info : AppColors.infoLight,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            ...widget.affectedTransits
                .map((item) => _buildTransitItem(context, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildTransitItem(
      BuildContext context, AffectedEntityItem<TransitFacade> item) {
    final transit = item.modifiedEntity;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? Colors.grey.shade100
            : Colors.grey.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTransitIcon(transit.transitOption),
                size: 18,
                color: isLightTheme ? AppColors.info : AppColors.infoLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${transit.departureLocation?.toString() ?? 'Unknown'} → ${transit.arrivalLocation?.toString() ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildOriginalDatesInfo(context, item.entity),
          const SizedBox(height: 12),
          _buildUnassignedInfo(context),
          const SizedBox(height: 12),
          _buildDateTimeRow(
            context: context,
            label: 'Departure',
            icon: Icons.flight_takeoff_rounded,
            dateTime: transit.departureDateTime,
            onChanged: (newDateTime) {
              setState(() {
                transit.departureDateTime = newDateTime;
              });
              widget.onChanged();
            },
          ),
          const SizedBox(height: 8),
          _buildDateTimeRow(
            context: context,
            label: 'Arrival',
            icon: Icons.flight_land_rounded,
            dateTime: transit.arrivalDateTime,
            onChanged: (newDateTime) {
              setState(() {
                transit.arrivalDateTime = newDateTime;
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
                  transit.departureDateTime = null;
                  transit.arrivalDateTime = null;
                });
                widget.onChanged();
              },
              icon: Icon(
                Icons.clear_rounded,
                size: 16,
                color: isLightTheme ? AppColors.error : AppColors.errorLight,
              ),
              label: Text(
                'Clear dates',
                style: TextStyle(
                  color: isLightTheme ? AppColors.error : AppColors.errorLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnassignedInfo(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.infoLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: isLightTheme ? AppColors.info : AppColors.infoLight,
          ),
          const SizedBox(width: 4),
          Text(
            'Dates are unassigned by default',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLightTheme ? AppColors.info : AppColors.infoLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalDatesInfo(BuildContext context, TransitFacade original) {
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
            'Was: ${original.departureDateTime?.dayDateMonthFormat ?? 'N/A'} → ${original.arrivalDateTime?.dayDateMonthFormat ?? 'N/A'}',
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
          startDateTime: widget.tripStartDate,
          endDateTime: widget.tripEndDate.add(const Duration(days: 1)),
          dateTimeUpdated: onChanged,
        ),
      ],
    );
  }

  IconData _getTransitIcon(TransitOption option) {
    switch (option) {
      case TransitOption.flight:
        return Icons.flight;
      case TransitOption.train:
        return Icons.train;
      case TransitOption.bus:
        return Icons.directions_bus;
      case TransitOption.ferry:
        return Icons.directions_ferry;
      case TransitOption.vehicle:
        return Icons.directions_car;
      case TransitOption.rentedVehicle:
        return Icons.car_rental;
      case TransitOption.walk:
        return Icons.directions_walk;
      case TransitOption.publicTransport:
      default:
        return Icons.directions_transit;
    }
  }
}
