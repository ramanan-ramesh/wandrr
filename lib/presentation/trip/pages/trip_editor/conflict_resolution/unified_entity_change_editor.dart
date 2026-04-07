import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/time_range.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_section_builder.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/entity_change_message_provider.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/entity_change_section.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/widgets/stay_date_time_range_editor.dart';

/// A unified editor for entity changes that works for both
/// TripMetadata updates and timeline conflict resolution.
class UnifiedEntityChangeEditor extends StatefulWidget {
  final TripDataUpdatePlan updatePlan;
  final MessageContext context;
  final void Function(EntityChangeBase change) onTimeRangeUpdated;
  final void Function(EntityChangeBase change) onDeletionToggled;
  final Iterable<ExpenseSplitChange>? expenseChanges;
  final Iterable<String>? addedContributors;
  final Iterable<String>? removedContributors;

  const UnifiedEntityChangeEditor({
    super.key,
    required this.updatePlan,
    required this.context,
    required this.onTimeRangeUpdated,
    required this.onDeletionToggled,
    this.expenseChanges,
    this.addedContributors,
    this.removedContributors,
  });

  /// Creates an editor for TripMetadataUpdatePlan
  factory UnifiedEntityChangeEditor.forMetadataUpdate({
    Key? key,
    required TripMetadataUpdatePlan updatePlan,
    required void Function(EntityChangeBase change) onTimeRangeUpdated,
    required void Function(EntityChangeBase change) onDeletionToggled,
  }) {
    return UnifiedEntityChangeEditor(
      key: key,
      updatePlan: updatePlan,
      context: MessageContext.metadataUpdate,
      onTimeRangeUpdated: onTimeRangeUpdated,
      onDeletionToggled: onDeletionToggled,
      expenseChanges: updatePlan.expenseChanges,
      addedContributors: updatePlan.addedContributors,
      removedContributors: updatePlan.removedContributors,
    );
  }

  /// Creates an editor for timeline conflict resolution
  factory UnifiedEntityChangeEditor.forConflictResolution({
    Key? key,
    required TripDataUpdatePlan updatePlan,
    required void Function(EntityChangeBase change) onTimeRangeUpdated,
    required void Function(EntityChangeBase change) onDeletionToggled,
    TripEntity? sourceEntity,
  }) {
    return UnifiedEntityChangeEditor(
      key: key,
      updatePlan: updatePlan,
      context: MessageContext.timelineConflict,
      onTimeRangeUpdated: onTimeRangeUpdated,
      onDeletionToggled: onDeletionToggled,
    );
  }

  @override
  State<UnifiedEntityChangeEditor> createState() =>
      _UnifiedEntityChangeEditorState();
}

class _UnifiedEntityChangeEditorState extends State<UnifiedEntityChangeEditor> {
  late EntityChangeMessageProvider _messageProvider;

  @override
  void initState() {
    super.initState();
    _messageProvider = EntityChangeMessageProvider(widget.context);
  }

  @override
  void didUpdateWidget(UnifiedEntityChangeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context != widget.context) {
      _messageProvider = EntityChangeMessageProvider(widget.context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stays section
        EntityChangeSection<StayChange>(
          icon: Icons.hotel_rounded,
          title: _messageProvider.staysSectionTitle(
            widget.updatePlan.stayChanges.length,
          ),
          iconColor: _getStaysIconColor(context),
          items: widget.updatePlan.stayChanges,
          infoMessage: widget.updatePlan.stayChanges.isNotEmpty
              ? _messageProvider.staysSectionInfo()
              : null,
          itemBuilder: _buildStayItem,
        ),

        // Transits section
        EntityChangeSection<TransitChange>(
          icon: Icons.directions_transit_rounded,
          title: _messageProvider.transitsSectionTitle(
            widget.updatePlan.transitChanges.length,
          ),
          iconColor: _getTransitsIconColor(context),
          items: widget.updatePlan.transitChanges,
          infoMessage: widget.updatePlan.transitChanges.isNotEmpty
              ? _messageProvider.transitsSectionInfo()
              : null,
          itemBuilder: _buildTransitItem,
        ),

        // Sights section
        EntityChangeSection<SightChange>(
          icon: Icons.attractions_rounded,
          title: _messageProvider.sightsSectionTitle(
            widget.updatePlan.sightChanges.length,
          ),
          iconColor: _getSightsIconColor(context),
          items: widget.updatePlan.sightChanges,
          infoMessage: widget.updatePlan.sightChanges.isNotEmpty
              ? _messageProvider.sightsSectionInfo()
              : null,
          itemBuilder: _buildSightItem,
        ),

        // Expenses section (only for TripMetadataUpdatePlan)
        if (widget.updatePlan is TripMetadataUpdatePlan &&
            widget.updatePlan.expenseChanges.isNotEmpty &&
            widget.context == MessageContext.metadataUpdate)
          _ExpensesSection(
            updatePlan: widget.updatePlan as TripMetadataUpdatePlan,
            addedContributors: widget.addedContributors ?? const [],
            removedContributors: widget.removedContributors ?? const [],
            messageProvider: _messageProvider,
          ),
      ],
    );
  }

  // =========================================================================
  // Icon Colors
  // =========================================================================

  Color _getStaysIconColor(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;
  }

  Color _getTransitsIconColor(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return isLightTheme ? AppColors.info : AppColors.infoLight;
  }

  Color _getSightsIconColor(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return isLightTheme ? AppColors.success : AppColors.successLight;
  }

  // =========================================================================
  // Stay Item Builder
  // =========================================================================

  Widget _buildStayItem(BuildContext context, StayChange change) {
    final lodging = change.modified;
    final originalLodging = change.original;

    return EntityChangeItemCard(
      isDeleted: change.isMarkedForDeletion,
      isClamped: change.isClamped,
      icon: Icons.hotel_rounded,
      iconColor: _getStaysIconColor(context),
      title: lodging.location?.context.name ?? 'Unknown Location',
      subtitle: lodging.location?.context.city,
      onToggleDelete: () => widget.onDeletionToggled(change),
      child: StayDateTimeRangeEditor(
        checkinDateTime: lodging.checkinDateTime,
        checkoutDateTime: lodging.checkoutDateTime,
        tripStartDate: widget.updatePlan.tripStartDate,
        tripEndDate: widget.updatePlan.tripEndDate,
        location: lodging.location,
        showOriginalTimes: change.isClamped,
        originalCheckinDateTime: originalLodging.checkinDateTime,
        originalCheckoutDateTime: originalLodging.checkoutDateTime,
        onStayRangeChanged: (checkin, checkout) {
          setState(() {
            lodging.checkinDateTime = checkin;
            lodging.checkoutDateTime = checkout;
          });
          widget.onTimeRangeUpdated(change);
        },
      ),
    );
  }

  // =========================================================================
  // Transit Item Builder
  // =========================================================================

  Widget _buildTransitItem(BuildContext context, TransitChange change) {
    final transit = change.modified;

    return EntityChangeItemCard(
      isDeleted: change.isMarkedForDeletion,
      isClamped: change.isClamped,
      icon: _getTransitIcon(transit.transitOption),
      iconColor: _getTransitsIconColor(context),
      title:
          '${transit.departureLocation?.context.name ?? '?'} → ${transit.arrivalLocation?.context.name ?? '?'}',
      onToggleDelete: () => widget.onDeletionToggled(change),
      child: _TransitDateTimeEditor(
        transit: transit,
        change: change,
        tripStartDate: widget.updatePlan.tripStartDate,
        tripEndDate: widget.updatePlan.tripEndDate,
        onValidateRange: (_) => true,
        onChanged: () => widget.onTimeRangeUpdated(change),
      ),
    );
  }

  IconData _getTransitIcon(TransitOption? option) {
    switch (option) {
      case TransitOption.flight:
        return Icons.flight;
      case TransitOption.train:
        return Icons.train;
      case TransitOption.bus:
        return Icons.directions_bus;
      case TransitOption.rentedVehicle:
      case TransitOption.vehicle:
        return Icons.directions_car;
      case TransitOption.ferry:
      case TransitOption.cruise:
        return Icons.directions_boat;
      case TransitOption.walk:
        return Icons.directions_walk;
      case TransitOption.publicTransport:
        return Icons.commute;
      case TransitOption.taxi:
        return Icons.local_taxi;
      default:
        return Icons.directions_transit;
    }
  }

  // =========================================================================
  // Sight Item Builder
  // =========================================================================

  Widget _buildSightItem(BuildContext context, SightChange change) {
    final sight = change.modified;

    return EntityChangeItemCard(
      isDeleted: change.isMarkedForDeletion,
      isClamped: change.isClamped,
      icon: Icons.place_rounded,
      iconColor: _getSightsIconColor(context),
      title: sight.name.isNotEmpty ? sight.name : 'Unnamed Sight',
      subtitle: sight.location?.context.name,
      onToggleDelete: () => widget.onDeletionToggled(change),
      child: _SightTimeEditor(
        change: change,
        tripStartDate: widget.updatePlan.tripStartDate,
        tripEndDate: widget.updatePlan.tripEndDate,
        onValidateRange: (_) => true,
        onChanged: () => widget.onTimeRangeUpdated(change),
      ),
    );
  }
}

// =============================================================================
// Transit DateTime Editor
// =============================================================================

class _TransitDateTimeEditor extends StatefulWidget {
  final TransitFacade transit;
  final TransitChange? change;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final bool Function(TimeRange range) onValidateRange;
  final VoidCallback onChanged;

  const _TransitDateTimeEditor({
    required this.transit,
    this.change,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onValidateRange,
    required this.onChanged,
  });

  @override
  State<_TransitDateTimeEditor> createState() => _TransitDateTimeEditorState();
}

class _TransitDateTimeEditorState extends State<_TransitDateTimeEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimePickerRow(
          label: 'Departure',
          icon: Icons.flight_takeoff_rounded,
          dateTime: widget.transit.departureDateTime,
          startDateTime: widget.tripStartDate,
          endDateTime: widget.tripEndDate,
          onChanged: (dt) {
            final oldDt = widget.transit.departureDateTime;
            widget.transit.departureDateTime = dt;

            if (widget.transit.departureDateTime != null &&
                widget.transit.arrivalDateTime != null) {
              if (!widget.onValidateRange(TimeRange(
                  start: widget.transit.departureDateTime!,
                  end: widget.transit.arrivalDateTime!))) {
                widget.transit.departureDateTime = oldDt;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Cannot conflict with the entity being edited.')),
                );
                setState(() {});
                return;
              }
            }
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),
        _DateTimePickerRow(
          label: 'Arrival',
          icon: Icons.flight_land_rounded,
          dateTime: widget.transit.arrivalDateTime,
          startDateTime: widget.transit.departureDateTime != null
              ? widget.transit.departureDateTime!
                  .add(const Duration(minutes: 1))
              : widget.tripStartDate.add(const Duration(minutes: 1)),
          endDateTime: widget.tripEndDate,
          onChanged: (dt) {
            final oldDt = widget.transit.arrivalDateTime;
            widget.transit.arrivalDateTime = dt;

            if (widget.transit.departureDateTime != null &&
                widget.transit.arrivalDateTime != null) {
              if (!widget.onValidateRange(TimeRange(
                  start: widget.transit.departureDateTime!,
                  end: widget.transit.arrivalDateTime!))) {
                widget.transit.arrivalDateTime = oldDt;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Cannot conflict with the entity being edited.')),
                );
                setState(() {});
                return;
              }
            }
            widget.onChanged();
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Sight Time Editor
// =============================================================================

class _SightTimeEditor extends StatefulWidget {
  final SightChange change;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final bool Function(TimeRange range) onValidateRange;
  final VoidCallback onChanged;

  const _SightTimeEditor({
    required this.change,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onValidateRange,
    required this.onChanged,
  });

  @override
  State<_SightTimeEditor> createState() => _SightTimeEditorState();
}

class _SightTimeEditorState extends State<_SightTimeEditor> {
  SightFacade get sight => widget.change.modified;

  @override
  Widget build(BuildContext context) {
    final timeOfDay = sight.visitTime != null
        ? TimeOfDay.fromDateTime(sight.visitTime!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day picker
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 8),
            const Text('Day:'),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_formatDay(sight.day)),
              onPressed: () => _showDayPicker(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Time picker
        Row(
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 8),
            const Text('Visit time:'),
            const Spacer(),
            OutlinedButton.icon(
              icon: const Icon(Icons.access_time, size: 16),
              label: Text(timeOfDay?.format(context) ?? 'Set time'),
              onPressed: () => _showTimePicker(context),
            ),
            if (sight.visitTime != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() {
                    sight.visitTime = null;
                  });
                  widget.onChanged();
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatDay(DateTime day) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${dayNames[day.weekday - 1]} ${day.day}/${day.month}';
  }

  Future<void> _showDayPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: sight.day,
      firstDate: widget.tripStartDate,
      lastDate: widget.tripEndDate,
    );
    if (picked != null) {
      if (sight.visitTime != null) {
        final newVisitTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          sight.visitTime!.hour,
          sight.visitTime!.minute,
        );
        if (!widget.onValidateRange(TimeRange(
            start: newVisitTime,
            end: newVisitTime.add(const Duration(minutes: 1))))) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Cannot conflict with the entity being edited.')),
            );
          }
          return;
        }
      }

      setState(() {
        // Create a new SightFacade with the updated day since day is final
        widget.change.modified = SightFacade(
          tripId: sight.tripId,
          id: sight.id,
          name: sight.name,
          day: picked,
          expense: sight.expense,
          location: sight.location,
          visitTime: sight.visitTime != null
              ? DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  sight.visitTime!.hour,
                  sight.visitTime!.minute,
                )
              : null,
          description: sight.description,
        );
      });
      widget.onChanged();
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: sight.visitTime != null
          ? TimeOfDay.fromDateTime(sight.visitTime!)
          : TimeOfDay.now(),
    );
    if (picked != null) {
      final d = sight.day;
      final newTime =
          DateTime(d.year, d.month, d.day, picked.hour, picked.minute);

      if (!widget.onValidateRange(TimeRange(
          start: newTime, end: newTime.add(const Duration(minutes: 1))))) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cannot conflict with the entity being edited.')),
          );
        }
        return;
      }

      setState(() {
        sight.visitTime = newTime;
      });
      widget.onChanged();
    }
  }
}

// =============================================================================
// DateTime Picker Row
// =============================================================================

class _DateTimePickerRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? dateTime;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final ValueChanged<DateTime?> onChanged;

  const _DateTimePickerRow({
    required this.label,
    required this.icon,
    required this.dateTime,
    required this.startDateTime,
    required this.endDateTime,
    required this.onChanged,
  });

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
          onPressed: () => _showPicker(context),
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

  String _formatDateTime(DateTime dt) {
    final dayName =
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayName ${dt.day}/${dt.month} $hour:$minute $amPm';
  }

  Future<void> _showPicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: dateTime ?? startDateTime,
      firstDate: startDateTime,
      lastDate: endDateTime,
    );
    if (pickedDate != null && context.mounted) {
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
  }
}

// =============================================================================
// Expenses Section (for TripMetadataUpdatePlan only)
// =============================================================================

class _ExpensesSection extends StatefulWidget {
  final TripMetadataUpdatePlan updatePlan;
  final Iterable<String> addedContributors;
  final Iterable<String> removedContributors;
  final EntityChangeMessageProvider messageProvider;

  const _ExpensesSection({
    required this.updatePlan,
    required this.addedContributors,
    required this.removedContributors,
    required this.messageProvider,
  });

  @override
  State<_ExpensesSection> createState() => _ExpensesSectionState();
}

class _ExpensesSectionState extends State<_ExpensesSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final expenseChanges = widget.updatePlan.expenseChanges;
    if (expenseChanges.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final iconColor = isLightTheme ? AppColors.warning : AppColors.warningLight;

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tri-state checkbox
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // Tri-state checkbox
                  _TriStateCheckbox(
                    state: widget.updatePlan.expenseSelectionState,
                    onChanged: () {
                      setState(() {
                        widget.updatePlan.toggleExpenseSelection();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.payments_rounded, color: iconColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.messageProvider
                          .expensesSectionTitle(expenseChanges.length),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _buildInfoBanner(context),
            const SizedBox(height: 12),
            ...expenseChanges
                .map((change) => _buildExpenseItem(context, change)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final message = widget.messageProvider.expensesSectionInfo(
      addedContributors: widget.addedContributors,
      removedContributors: widget.removedContributors,
    );

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
                size: 16,
                color: isLightTheme ? AppColors.info : AppColors.infoLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.title,
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
            message.details,
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

  Widget _buildExpenseItem(
    BuildContext context,
    ExpenseSplitChange change,
  ) {
    final entity = change.modified;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final displayTitle =
        entity.title.isNotEmpty ? entity.title : 'Untitled Expense';
    final totalExpense = entity.expense.totalExpense;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? Colors.grey.shade100
            : Colors.grey.shade800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: change.includeInSplitBy,
            onChanged: (value) {
              setState(() {
                change.includeInSplitBy = value ?? false;
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${totalExpense.currency} ${totalExpense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tri-State Checkbox Widget
// =============================================================================

/// A tri-state checkbox widget:
/// - null (some selected): shows filled square with gap
/// - true (all selected): shows filled checkbox with checkmark
/// - false (none selected): shows empty square
class _TriStateCheckbox extends StatelessWidget {
  /// The current state: null = some, true = all, false = none
  final bool? state;

  /// Called when the checkbox is tapped
  final VoidCallback onChanged;

  const _TriStateCheckbox({
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final activeColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: state == false ? Colors.transparent : activeColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: state == false
                ? (isLightTheme ? Colors.grey.shade500 : Colors.grey.shade400)
                : activeColor,
            width: 2,
          ),
        ),
        child: _buildIcon(state),
      ),
    );
  }

  Widget _buildIcon(bool? state) {
    if (state == false) {
      // None selected - empty square (no icon)
      return const SizedBox.shrink();
    } else if (state == true) {
      // All selected - checkmark
      return const Icon(
        Icons.check,
        size: 18,
        color: Colors.white,
      );
    } else {
      // Some selected - horizontal line (indeterminate)
      return const Center(
        child: SizedBox(
          width: 12,
          height: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(1)),
            ),
          ),
        ),
      );
    }
  }
}

// =============================================================================
// Optimized Entity Change Section
// =============================================================================

/// An optimized section for displaying entity changes that uses [ConflictItemBuilder]
/// to rebuild individual items only when they are updated.
///
/// This widget should be used within a [ConflictSectionBuilder] which handles
/// section-level rebuilds when conflicts are added/removed.
class OptimizedEntityChangeSection<T extends TripEntity>
    extends StatefulWidget {
  final ConflictSectionType sectionType;
  final TripDataUpdatePlan plan;
  final MessageContext messageContext;
  final void Function(EntityChangeBase change) onTimeRangeUpdated;
  final void Function(EntityChangeBase change) onDeletionToggled;

  const OptimizedEntityChangeSection({
    super.key,
    required this.sectionType,
    required this.plan,
    required this.messageContext,
    required this.onTimeRangeUpdated,
    required this.onDeletionToggled,
  });

  @override
  State<OptimizedEntityChangeSection<T>> createState() =>
      _OptimizedEntityChangeSectionState<T>();
}

class _OptimizedEntityChangeSectionState<T extends TripEntity>
    extends State<OptimizedEntityChangeSection<T>> {
  late EntityChangeMessageProvider _messageProvider;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _messageProvider = EntityChangeMessageProvider(widget.messageContext);
  }

  @override
  void didUpdateWidget(OptimizedEntityChangeSection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageContext != widget.messageContext) {
      _messageProvider = EntityChangeMessageProvider(widget.messageContext);
    }
  }

  List<EntityChangeBase> get _changes {
    switch (widget.sectionType) {
      case ConflictSectionType.stays:
        return widget.plan.stayChanges.cast<EntityChangeBase>();
      case ConflictSectionType.transits:
        return widget.plan.transitChanges.cast<EntityChangeBase>();
      case ConflictSectionType.sights:
        return widget.plan.sightChanges.cast<EntityChangeBase>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final changes = _changes;
    if (changes.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final iconColor = _getIconColor(isLightTheme);

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: _getSectionIcon(),
            title: _getSectionTitle(changes.length),
            iconColor: iconColor,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: _toggleExpansion,
            ),
            onTap: _toggleExpansion,
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _buildInfoBanner(),
            const SizedBox(height: 12),
            // Each item uses ConflictItemBuilder for localized updates
            ...changes.map((change) => _OptimizedChangeItem<T>(
                  change: change,
                  sectionType: widget.sectionType,
                  plan: widget.plan,
                  onTimeRangeUpdated: widget.onTimeRangeUpdated,
                  onDeletionToggled: widget.onDeletionToggled,
                )),
          ],
        ],
      ),
    );
  }

  void _toggleExpansion() {
    setState(() => _isExpanded = !_isExpanded);
  }

  IconData _getSectionIcon() {
    switch (widget.sectionType) {
      case ConflictSectionType.stays:
        return Icons.hotel_rounded;
      case ConflictSectionType.transits:
        return Icons.directions_transit_rounded;
      case ConflictSectionType.sights:
        return Icons.attractions_rounded;
    }
  }

  String _getSectionTitle(int count) {
    switch (widget.sectionType) {
      case ConflictSectionType.stays:
        return _messageProvider.staysSectionTitle(count);
      case ConflictSectionType.transits:
        return _messageProvider.transitsSectionTitle(count);
      case ConflictSectionType.sights:
        return _messageProvider.sightsSectionTitle(count);
    }
  }

  Color _getIconColor(bool isLightTheme) {
    switch (widget.sectionType) {
      case ConflictSectionType.stays:
        return isLightTheme
            ? AppColors.brandPrimary
            : AppColors.brandPrimaryLight;
      case ConflictSectionType.transits:
        return isLightTheme ? AppColors.info : AppColors.infoLight;
      case ConflictSectionType.sights:
        return isLightTheme ? AppColors.success : AppColors.successLight;
    }
  }

  Widget _buildInfoBanner() {
    final infoMessage = _getInfoMessage();
    if (infoMessage == null) return const SizedBox.shrink();

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
              Icon(
                Icons.info_outline,
                size: 16,
                color: isLightTheme ? AppColors.info : AppColors.infoLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  infoMessage.title,
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
            infoMessage.details,
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

  EntityChangeInfoMessage? _getInfoMessage() {
    switch (widget.sectionType) {
      case ConflictSectionType.stays:
        return _messageProvider.staysSectionInfo();
      case ConflictSectionType.transits:
        return _messageProvider.transitsSectionInfo();
      case ConflictSectionType.sights:
        return _messageProvider.sightsSectionInfo();
    }
  }
}

/// An individual change item that uses [ConflictItemBuilder<T>] for localized
/// rebuilds driven by [PlanItemsUpdated].
class _OptimizedChangeItem<T extends TripEntity> extends StatelessWidget {
  final EntityChangeBase change;
  final ConflictSectionType sectionType;
  final TripDataUpdatePlan plan;
  final void Function(EntityChangeBase change) onTimeRangeUpdated;
  final void Function(EntityChangeBase change) onDeletionToggled;

  const _OptimizedChangeItem({
    required this.change,
    required this.sectionType,
    required this.plan,
    required this.onTimeRangeUpdated,
    required this.onDeletionToggled,
  });

  @override
  Widget build(BuildContext context) {
    final id = change.original.id ?? '';
    return ConflictItemBuilder<T>(
      entityId: id,
      sectionType: sectionType,
      builder: (context, activeChange) => switch (sectionType) {
        ConflictSectionType.stays =>
          _buildStayItem(context, activeChange as StayChange),
        ConflictSectionType.transits =>
          _buildTransitItem(context, activeChange as TransitChange),
        ConflictSectionType.sights =>
          _buildSightItem(context, activeChange as SightChange),
      },
    );
  }

  Widget _buildStayItem(BuildContext context, StayChange activeChange) {
    final lodging = activeChange.modified;
    final originalLodging = activeChange.original;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final iconColor =
        isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight;

    return EntityChangeItemCard(
      isDeleted: activeChange.isMarkedForDeletion,
      isClamped: activeChange.isClamped,
      icon: Icons.hotel_rounded,
      iconColor: iconColor,
      title: lodging.location?.context.name ?? 'Unknown Location',
      subtitle: lodging.location?.context.city,
      onToggleDelete: () => onDeletionToggled(activeChange),
      child: StayDateTimeRangeEditor(
        checkinDateTime: lodging.checkinDateTime,
        checkoutDateTime: lodging.checkoutDateTime,
        tripStartDate: plan.tripStartDate,
        tripEndDate: plan.tripEndDate,
        location: lodging.location,
        showOriginalTimes: activeChange.isClamped,
        originalCheckinDateTime: originalLodging.checkinDateTime,
        originalCheckoutDateTime: originalLodging.checkoutDateTime,
        onStayRangeChanged: (checkin, checkout) {
          lodging.checkinDateTime = checkin;
          lodging.checkoutDateTime = checkout;
          onTimeRangeUpdated(activeChange);
        },
      ),
    );
  }

  Widget _buildTransitItem(BuildContext context, TransitChange activeChange) {
    final transit = activeChange.modified;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final iconColor = isLightTheme ? AppColors.info : AppColors.infoLight;

    return EntityChangeItemCard(
      isDeleted: activeChange.isMarkedForDeletion,
      isClamped: activeChange.isClamped,
      icon: _getTransitIcon(transit.transitOption),
      iconColor: iconColor,
      title:
          '${transit.departureLocation?.context.name ?? '?'} → ${transit.arrivalLocation?.context.name ?? '?'}',
      onToggleDelete: () => onDeletionToggled(activeChange),
      child: _TransitDateTimeEditor(
        transit: transit,
        change: activeChange,
        tripStartDate: plan.tripStartDate,
        tripEndDate: plan.tripEndDate,
        onValidateRange: (_) => true,
        onChanged: () => onTimeRangeUpdated(activeChange),
      ),
    );
  }

  Widget _buildSightItem(BuildContext context, SightChange activeChange) {
    final sight = activeChange.modified;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final iconColor = isLightTheme ? AppColors.success : AppColors.successLight;

    return EntityChangeItemCard(
      isDeleted: activeChange.isMarkedForDeletion,
      isClamped: activeChange.isClamped,
      icon: Icons.place_rounded,
      iconColor: iconColor,
      title: sight.name.isNotEmpty ? sight.name : 'Unnamed Sight',
      subtitle: sight.location?.context.name,
      onToggleDelete: () => onDeletionToggled(activeChange),
      child: _SightTimeEditor(
        change: activeChange,
        tripStartDate: plan.tripStartDate,
        tripEndDate: plan.tripEndDate,
        onValidateRange: (_) => true,
        onChanged: () => onTimeRangeUpdated(activeChange),
      ),
    );
  }

  IconData _getTransitIcon(TransitOption? option) {
    switch (option) {
      case TransitOption.flight:
        return Icons.flight;
      case TransitOption.train:
        return Icons.train;
      case TransitOption.bus:
        return Icons.directions_bus;
      case TransitOption.rentedVehicle:
      case TransitOption.vehicle:
        return Icons.directions_car;
      case TransitOption.ferry:
      case TransitOption.cruise:
        return Icons.directions_boat;
      case TransitOption.walk:
        return Icons.directions_walk;
      case TransitOption.publicTransport:
        return Icons.commute;
      case TransitOption.taxi:
        return Icons.local_taxi;
      default:
        return Icons.directions_transit;
    }
  }
}
