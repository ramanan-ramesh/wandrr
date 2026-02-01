import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_metadata_update.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_message_builder.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/widgets/stay_date_time_range_editor.dart';

/// A subpage for resolving timeline conflicts within an entity editor.
/// This is not a bottom sheet but an embedded page that can be navigated to.
class ConflictResolutionSubpage extends StatefulWidget {
  final TripEntityUpdatePlan conflictPlan;
  final VoidCallback onBackPressed;
  final VoidCallback onConflictsResolved;

  const ConflictResolutionSubpage({
    super.key,
    required this.conflictPlan,
    required this.onBackPressed,
    required this.onConflictsResolved,
  });

  @override
  State<ConflictResolutionSubpage> createState() =>
      _ConflictResolutionSubpageState();
}

class _ConflictResolutionSubpageState extends State<ConflictResolutionSubpage> {
  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isLightTheme),
        const SizedBox(height: 16),
        _buildInfoBanner(context, isLightTheme),
        const SizedBox(height: 16),
        if (widget.conflictPlan.transitChanges.isNotEmpty)
          _ConflictingTransitsSection(
            changes: widget.conflictPlan.transitChanges,
            plan: widget.conflictPlan,
            onChanged: () => setState(() {}),
          ),
        if (widget.conflictPlan.stayChanges.isNotEmpty)
          _ConflictingStaysSection(
            changes: widget.conflictPlan.stayChanges,
            plan: widget.conflictPlan,
            onChanged: () => setState(() {}),
          ),
        if (widget.conflictPlan.sightChanges.isNotEmpty)
          _ConflictingSightsSection(
            changes: widget.conflictPlan.sightChanges,
            plan: widget.conflictPlan,
            onChanged: () => setState(() {}),
          ),
        const SizedBox(height: 24),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isLightTheme) {
    return InkWell(
      onTap: widget.onBackPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLightTheme
                ? [
                    AppColors.brandPrimary.withValues(alpha: 0.1),
                    AppColors.brandSecondary.withValues(alpha: 0.15),
                  ]
                : [
                    AppColors.brandPrimaryLight.withValues(alpha: 0.2),
                    AppColors.brandSecondaryLight.withValues(alpha: 0.15),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLightTheme
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLightTheme
                    ? AppColors.brandPrimary.withValues(alpha: 0.15)
                    : AppColors.brandPrimaryLight.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: isLightTheme
                    ? AppColors.brandPrimary
                    : AppColors.brandPrimaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Back to Editing',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLightTheme
                              ? AppColors.brandPrimary
                              : AppColors.brandPrimaryLight,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to return to the editor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isLightTheme
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, bool isLightTheme) {
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
              Icon(
                Icons.info_outline,
                size: 20,
                color: isLightTheme ? AppColors.info : AppColors.infoLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ConflictMessageBuilder.buildSummaryMessage(
                      widget.conflictPlan),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLightTheme
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ConflictMessageBuilder.buildActionMessage(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLightTheme
                      ? Colors.grey.shade600
                      : Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onBackPressed,
              child: const Text('Back to Editor'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                widget.conflictPlan.acknowledge();
                // Don't dispatch events here - they will be buffered
                // and dispatched when the main FAB is clicked
                widget.onConflictsResolved();
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Changes'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isLightTheme ? AppColors.success : AppColors.successLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section for conflicting transits
class _ConflictingTransitsSection extends StatefulWidget {
  final List<EntityChange<TransitFacade>> changes;
  final TripEntityUpdatePlan plan;
  final VoidCallback onChanged;

  const _ConflictingTransitsSection({
    required this.changes,
    required this.plan,
    required this.onChanged,
  });

  @override
  State<_ConflictingTransitsSection> createState() =>
      _ConflictingTransitsSectionState();
}

class _ConflictingTransitsSectionState
    extends State<_ConflictingTransitsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.directions_transit_rounded,
            title: 'Transits (${widget.changes.length})',
            iconColor: isLightTheme ? AppColors.info : AppColors.infoLight,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            ...widget.changes
                .map((change) => _buildTransitItem(context, change)),
        ],
      ),
    );
  }

  Widget _buildTransitItem(
      BuildContext context, EntityChange<TransitFacade> change) {
    final isDeleted = change.isMarkedForDeletion;

    return _ConflictItemCard(
      isDeleted: isDeleted,
      icon: Icons.directions_transit,
      title: change.conflictDescription ?? 'Transit',
      originalTime: change.originalTimeDescription ?? '',
      onToggleDelete: () {
        setState(() {
          if (isDeleted) {
            change.restore();
          } else {
            change.markForDeletion();
          }
        });
        widget.onChanged();
      },
      child: isDeleted
          ? null
          : _TransitDateTimeEditor(
              change: change,
              plan: widget.plan,
              onChanged: widget.onChanged,
            ),
    );
  }
}

/// Section for conflicting stays
class _ConflictingStaysSection extends StatefulWidget {
  final List<EntityChange<LodgingFacade>> changes;
  final TripEntityUpdatePlan plan;
  final VoidCallback onChanged;

  const _ConflictingStaysSection({
    required this.changes,
    required this.plan,
    required this.onChanged,
  });

  @override
  State<_ConflictingStaysSection> createState() =>
      _ConflictingStaysSectionState();
}

class _ConflictingStaysSectionState extends State<_ConflictingStaysSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.hotel_rounded,
            title: 'Stays (${widget.changes.length})',
            iconColor: isLightTheme
                ? AppColors.brandPrimary
                : AppColors.brandPrimaryLight,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            ...widget.changes.map((change) => _buildStayItem(context, change)),
        ],
      ),
    );
  }

  Widget _buildStayItem(
      BuildContext context, EntityChange<LodgingFacade> change) {
    final isDeleted = change.isMarkedForDeletion;

    return _ConflictItemCard(
      isDeleted: isDeleted,
      icon: Icons.hotel,
      title: change.conflictDescription ?? 'Stay',
      originalTime: change.originalTimeDescription ?? '',
      onToggleDelete: () {
        setState(() {
          if (isDeleted) {
            change.restore();
          } else {
            change.markForDeletion();
          }
        });
        widget.onChanged();
      },
      child: isDeleted
          ? null
          : _StayDateTimeEditor(
              change: change,
              plan: widget.plan,
              onChanged: widget.onChanged,
            ),
    );
  }
}

/// Section for conflicting sights
class _ConflictingSightsSection extends StatefulWidget {
  final List<EntityChange<SightFacade>> changes;
  final TripEntityUpdatePlan plan;
  final VoidCallback onChanged;

  const _ConflictingSightsSection({
    required this.changes,
    required this.plan,
    required this.onChanged,
  });

  @override
  State<_ConflictingSightsSection> createState() =>
      _ConflictingSightsSectionState();
}

class _ConflictingSightsSectionState extends State<_ConflictingSightsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: Icons.place_rounded,
            title: 'Sights (${widget.changes.length})',
            iconColor:
                isLightTheme ? AppColors.success : AppColors.successLight,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            ...widget.changes.map((change) => _buildSightItem(context, change)),
        ],
      ),
    );
  }

  Widget _buildSightItem(
      BuildContext context, EntityChange<SightFacade> change) {
    final isDeleted = change.isMarkedForDeletion;

    return _ConflictItemCard(
      isDeleted: isDeleted,
      icon: Icons.place,
      title: change.conflictDescription ?? 'Sight',
      originalTime: change.originalTimeDescription ?? '',
      onToggleDelete: () {
        setState(() {
          if (isDeleted) {
            change.restore();
          } else {
            change.markForDeletion();
          }
        });
        widget.onChanged();
      },
      child: isDeleted
          ? null
          : _SightTimeEditor(
              change: change,
              plan: widget.plan,
              onChanged: widget.onChanged,
            ),
    );
  }
}

/// Reusable card for conflict items
class _ConflictItemCard extends StatelessWidget {
  final bool isDeleted;
  final IconData icon;
  final String title;
  final String originalTime;
  final VoidCallback onToggleDelete;
  final Widget? child;

  const _ConflictItemCard({
    required this.isDeleted,
    required this.icon,
    required this.title,
    required this.originalTime,
    required this.onToggleDelete,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Opacity(
      opacity: isDeleted ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDeleted
              ? (isLightTheme
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.errorLight.withValues(alpha: 0.1))
              : (isLightTheme
                  ? Colors.grey.shade100
                  : Colors.grey.shade800.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDeleted
                ? (isLightTheme ? AppColors.error : AppColors.errorLight)
                : (isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700),
            width: isDeleted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration:
                              isDeleted ? TextDecoration.lineThrough : null,
                        ),
                  ),
                ),
                IconButton(
                  icon: Icon(isDeleted ? Icons.restore : Icons.delete_outline),
                  tooltip: isDeleted ? 'Restore' : 'Delete',
                  onPressed: onToggleDelete,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildOriginalTimeChip(context, isLightTheme),
            if (!isDeleted && child != null) ...[
              const SizedBox(height: 12),
              child!,
            ],
            if (isDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Will be deleted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLightTheme
                              ? AppColors.error
                              : AppColors.errorLight,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalTimeChip(BuildContext context, bool isLightTheme) {
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

/// DateTime editor for transits with conflict validation
class _TransitDateTimeEditor extends StatefulWidget {
  final EntityChange<TransitFacade> change;
  final TripEntityUpdatePlan plan;
  final VoidCallback onChanged;

  const _TransitDateTimeEditor({
    required this.change,
    required this.plan,
    required this.onChanged,
  });

  @override
  State<_TransitDateTimeEditor> createState() => _TransitDateTimeEditorState();
}

class _TransitDateTimeEditorState extends State<_TransitDateTimeEditor> {
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final transit = widget.change.modifiedEntity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimePickerRow(
          label: 'Departure',
          icon: Icons.flight_takeoff,
          dateTime: transit.departureDateTime,
          startDate: widget.plan.tripStartDate,
          endDate: widget.plan.tripEndDate,
          onChanged: (dt) => _updateDeparture(dt),
        ),
        const SizedBox(height: 8),
        _DateTimePickerRow(
          label: 'Arrival',
          icon: Icons.flight_land,
          dateTime: transit.arrivalDateTime,
          startDate: transit.departureDateTime ?? widget.plan.tripStartDate,
          endDate: widget.plan.tripEndDate,
          onChanged: (dt) => _updateArrival(dt),
        ),
        if (_errorMessage != null) _buildErrorMessage(context),
      ],
    );
  }

  void _updateDeparture(DateTime? dt) {
    setState(() {
      widget.change.modifiedEntity.departureDateTime = dt;
      _errorMessage = null;
    });
    widget.onChanged();
  }

  void _updateArrival(DateTime? dt) {
    setState(() {
      widget.change.modifiedEntity.arrivalDateTime = dt;
      _errorMessage = null;
    });
    widget.onChanged();
  }

  Widget _buildErrorMessage(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// DateTime editor for stays with conflict validation
class _StayDateTimeEditor extends StatefulWidget {
  final EntityChange<LodgingFacade> change;
  final TripEntityUpdatePlan plan;
  final VoidCallback onChanged;

  const _StayDateTimeEditor({
    required this.change,
    required this.plan,
    required this.onChanged,
  });

  @override
  State<_StayDateTimeEditor> createState() => _StayDateTimeEditorState();
}

class _StayDateTimeEditorState extends State<_StayDateTimeEditor> {
  @override
  Widget build(BuildContext context) {
    final stay = widget.change.modifiedEntity;
    final originalStay = widget.change.originalEntity;

    return StayDateTimeRangeEditor(
      checkinDateTime: stay.checkinDateTime,
      checkoutDateTime: stay.checkoutDateTime,
      tripStartDate: widget.plan.tripStartDate,
      tripEndDate: widget.plan.tripEndDate,
      location: stay.location,
      showOriginalTimes: true,
      originalCheckinDateTime: originalStay.checkinDateTime,
      originalCheckoutDateTime: originalStay.checkoutDateTime,
      onCheckinChanged: (dt) {
        setState(() {
          widget.change.modifiedEntity.checkinDateTime = dt;
        });
        widget.onChanged();
      },
      onCheckoutChanged: (dt) {
        setState(() {
          widget.change.modifiedEntity.checkoutDateTime = dt;
        });
        widget.onChanged();
      },
    );
  }
}

/// Time editor for sights
class _SightTimeEditor extends StatelessWidget {
  final EntityChange<SightFacade> change;
  final TripEntityUpdatePlan plan;
  final VoidCallback onChanged;

  const _SightTimeEditor({
    required this.change,
    required this.plan,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sight = change.modifiedEntity;
    final timeOfDay = sight.visitTime != null
        ? TimeOfDay.fromDateTime(sight.visitTime!)
        : null;

    return Row(
      children: [
        const Icon(Icons.schedule, size: 18),
        const SizedBox(width: 8),
        const Text('Visit time:'),
        const Spacer(),
        OutlinedButton.icon(
          icon: const Icon(Icons.access_time, size: 16),
          label: Text(timeOfDay?.format(context) ?? 'Set time'),
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: timeOfDay ?? TimeOfDay.now(),
            );
            if (picked != null) {
              final d = sight.day;
              sight.visitTime =
                  DateTime(d.year, d.month, d.day, picked.hour, picked.minute);
              onChanged();
            }
          },
        ),
        if (sight.visitTime != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () {
              sight.visitTime = null;
              onChanged();
            },
          ),
        ],
      ],
    );
  }
}

/// Simple datetime picker row
class _DateTimePickerRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? dateTime;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime?> onChanged;

  const _DateTimePickerRow({
    required this.label,
    required this.icon,
    required this.dateTime,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  String _formatDateTime(DateTime dt) {
    final dayName =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayName ${dt.day}/${dt.month} $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text('$label:'),
        const Spacer(),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(dateTime != null ? _formatDateTime(dateTime!) : 'Select'),
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: dateTime ?? startDate,
              firstDate: startDate,
              lastDate: endDate,
            );
            if (pickedDate != null) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: dateTime != null
                    ? TimeOfDay.fromDateTime(dateTime!)
                    : TimeOfDay.now(),
              );
              if (pickedTime != null) {
                onChanged(DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                ));
              }
            }
          },
        ),
        if (dateTime != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => onChanged(null),
          ),
        ],
      ],
    );
  }
}
