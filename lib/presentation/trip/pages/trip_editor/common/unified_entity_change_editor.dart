import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/entity_change_context.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_data_update_plan.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/common/entity_change_message_provider.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/common/entity_change_section.dart';
import 'package:wandrr/presentation/trip/widgets/stay_date_time_range_editor.dart';

/// A unified editor for entity changes that works for both
/// TripMetadata updates and timeline conflict resolution.
class UnifiedEntityChangeEditor extends StatefulWidget {
  /// The update plan containing all entity changes
  final TripDataUpdatePlan updatePlan;

  /// The context in which changes are being displayed
  final EntityChangeContext context;

  /// Callback when any entity is modified
  final VoidCallback onChanged;

  /// Callback when an entity's deletion state changes (for expense sync)
  final void Function(dynamic entity, bool isDeleted)? onEntityDeletionChanged;

  /// Optional: expense changes for TripMetadataUpdatePlan
  final Iterable<EntityChange<ExpenseBearingTripEntity>>? expenseChanges;

  /// Optional: added contributors for expense section
  final Iterable<String>? addedContributors;

  /// Optional: removed contributors for expense section
  final Iterable<String>? removedContributors;

  const UnifiedEntityChangeEditor({
    super.key,
    required this.updatePlan,
    required this.context,
    required this.onChanged,
    this.onEntityDeletionChanged,
    this.expenseChanges,
    this.addedContributors,
    this.removedContributors,
  });

  /// Creates an editor for TripMetadataUpdatePlan
  factory UnifiedEntityChangeEditor.forMetadataUpdate({
    Key? key,
    required TripMetadataUpdatePlan updatePlan,
    required VoidCallback onChanged,
    void Function(dynamic entity, bool isDeleted)? onEntityDeletionChanged,
  }) {
    return UnifiedEntityChangeEditor(
      key: key,
      updatePlan: updatePlan,
      context: EntityChangeContext.tripMetadataUpdate,
      onChanged: onChanged,
      onEntityDeletionChanged: onEntityDeletionChanged,
      expenseChanges: updatePlan.expenseChanges,
      addedContributors: updatePlan.addedContributors,
      removedContributors: updatePlan.removedContributors,
    );
  }

  /// Creates an editor for timeline conflict resolution
  factory UnifiedEntityChangeEditor.forConflictResolution({
    Key? key,
    required TripDataUpdatePlan updatePlan,
    required VoidCallback onChanged,
  }) {
    return UnifiedEntityChangeEditor(
      key: key,
      updatePlan: updatePlan,
      context: EntityChangeContext.timelineConflict,
      onChanged: onChanged,
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
        EntityChangeSection<EntityChange<LodgingFacade>>(
          icon: Icons.hotel_rounded,
          title: _messageProvider.staysSectionTitle(
            widget.updatePlan.stayChanges.length,
          ),
          iconColor: _getStaysIconColor(context),
          items: widget.updatePlan.stayChanges,
          infoMessage: widget.updatePlan.stayChanges.isNotEmpty
              ? _messageProvider.staysSectionInfo()
              : null,
          itemBuilder: (ctx, change) => _buildStayItem(ctx, change),
        ),

        // Transits section
        EntityChangeSection<EntityChange<TransitFacade>>(
          icon: Icons.directions_transit_rounded,
          title: _messageProvider.transitsSectionTitle(
            widget.updatePlan.transitChanges.length,
          ),
          iconColor: _getTransitsIconColor(context),
          items: widget.updatePlan.transitChanges,
          infoMessage: widget.updatePlan.transitChanges.isNotEmpty
              ? _messageProvider.transitsSectionInfo()
              : null,
          itemBuilder: (ctx, change) => _buildTransitItem(ctx, change),
        ),

        // Sights section
        EntityChangeSection<EntityChange<SightFacade>>(
          icon: Icons.attractions_rounded,
          title: _messageProvider.sightsSectionTitle(
            widget.updatePlan.sightChanges.length,
          ),
          iconColor: _getSightsIconColor(context),
          items: widget.updatePlan.sightChanges,
          infoMessage: widget.updatePlan.sightChanges.isNotEmpty
              ? _messageProvider.sightsSectionInfo()
              : null,
          itemBuilder: (ctx, change) => _buildSightItem(ctx, change),
        ),

        // Expenses section (only for TripMetadataUpdatePlan)
        if (widget.expenseChanges != null &&
            widget.expenseChanges!.isNotEmpty &&
            widget.context == EntityChangeContext.tripMetadataUpdate)
          _ExpensesSection(
            expenseChanges: widget.expenseChanges!,
            addedContributors: widget.addedContributors ?? const [],
            removedContributors: widget.removedContributors ?? const [],
            messageProvider: _messageProvider,
            onChanged: widget.onChanged,
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

  Widget _buildStayItem(
      BuildContext context, EntityChange<LodgingFacade> change) {
    final lodging = change.modifiedEntity;
    final originalLodging = change.originalEntity;
    final isDeleted = change.isMarkedForDeletion;

    return EntityChangeItemCard(
      isDeleted: isDeleted,
      icon: Icons.location_on,
      iconColor: _getStaysIconColor(context),
      title: lodging.location?.toString() ?? 'Unknown Location',
      originalTimeDescription: change.originalTimeDescription,
      onToggleDelete: () => _toggleStayDeletion(change),
      deletedMessage: 'This stay will be deleted',
      child: StayDateTimeRangeEditor(
        checkinDateTime: lodging.checkinDateTime,
        checkoutDateTime: lodging.checkoutDateTime,
        tripStartDate: widget.updatePlan.tripStartDate,
        tripEndDate: widget.updatePlan.tripEndDate,
        location: lodging.location,
        showOriginalTimes: true,
        originalCheckinDateTime: originalLodging.checkinDateTime,
        originalCheckoutDateTime: originalLodging.checkoutDateTime,
        onCheckinChanged: (dt) {
          setState(() => lodging.checkinDateTime = dt);
          widget.onChanged();
        },
        onCheckoutChanged: (dt) {
          setState(() => lodging.checkoutDateTime = dt);
          widget.onChanged();
        },
      ),
    );
  }

  // =========================================================================
  // Transit Item Builder
  // =========================================================================

  Widget _buildTransitItem(
      BuildContext context, EntityChange<TransitFacade> change) {
    final transit = change.modifiedEntity;
    final isDeleted = change.isMarkedForDeletion;

    return EntityChangeItemCard(
      isDeleted: isDeleted,
      icon: _getTransitIcon(transit.transitOption),
      iconColor: _getTransitsIconColor(context),
      title:
          '${transit.departureLocation?.toString() ?? 'Unknown'} → ${transit.arrivalLocation?.toString() ?? 'Unknown'}',
      originalTimeDescription: change.originalTimeDescription,
      onToggleDelete: () => _toggleTransitDeletion(change),
      deletedMessage: 'This transit will be deleted',
      child: _TransitDateTimeEditor(
        transit: transit,
        tripStartDate: widget.updatePlan.tripStartDate,
        tripEndDate: widget.updatePlan.tripEndDate,
        onChanged: widget.onChanged,
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

  Widget _buildSightItem(
      BuildContext context, EntityChange<SightFacade> change) {
    final sight = change.modifiedEntity;
    final isDeleted = change.isMarkedForDeletion;

    return EntityChangeItemCard(
      isDeleted: isDeleted,
      icon: Icons.place_rounded,
      iconColor: _getSightsIconColor(context),
      title: sight.name.isNotEmpty ? sight.name : 'Unnamed Sight',
      subtitle: sight.location?.toString(),
      originalTimeDescription: change.originalTimeDescription,
      onToggleDelete: () => _toggleSightDeletion(change),
      deletedMessage: 'This sight will be deleted',
      child: _SightTimeEditor(
        change: change,
        tripStartDate: widget.updatePlan.tripStartDate,
        tripEndDate: widget.updatePlan.tripEndDate,
        onChanged: widget.onChanged,
      ),
    );
  }

  // =========================================================================
  // Toggle Deletion
  // =========================================================================

  void _toggleStayDeletion(EntityChange<LodgingFacade> change) {
    final newIsDeleted = !change.isMarkedForDeletion;
    setState(() {
      if (newIsDeleted) {
        change.markForDeletion();
      } else {
        change.restore();
      }
    });
    widget.onEntityDeletionChanged?.call(change.originalEntity, newIsDeleted);
    widget.onChanged();
  }

  void _toggleTransitDeletion(EntityChange<TransitFacade> change) {
    final newIsDeleted = !change.isMarkedForDeletion;
    setState(() {
      if (newIsDeleted) {
        change.markForDeletion();
      } else {
        change.restore();
      }
    });
    widget.onEntityDeletionChanged?.call(change.originalEntity, newIsDeleted);
    widget.onChanged();
  }

  void _toggleSightDeletion(EntityChange<SightFacade> change) {
    final newIsDeleted = !change.isMarkedForDeletion;
    setState(() {
      if (newIsDeleted) {
        change.markForDeletion();
      } else {
        change.restore();
      }
    });
    widget.onEntityDeletionChanged?.call(change.originalEntity, newIsDeleted);
    widget.onChanged();
  }
}

// =============================================================================
// Transit DateTime Editor
// =============================================================================

class _TransitDateTimeEditor extends StatelessWidget {
  final TransitFacade transit;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final VoidCallback onChanged;

  const _TransitDateTimeEditor({
    required this.transit,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimePickerRow(
          label: 'Departure',
          icon: Icons.flight_takeoff_rounded,
          dateTime: transit.departureDateTime,
          startDateTime: tripStartDate,
          endDateTime: tripEndDate,
          onChanged: (dt) {
            transit.departureDateTime = dt;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _DateTimePickerRow(
          label: 'Arrival',
          icon: Icons.flight_land_rounded,
          dateTime: transit.arrivalDateTime,
          startDateTime: transit.departureDateTime != null
              ? transit.departureDateTime!.add(const Duration(minutes: 1))
              : tripStartDate.add(const Duration(minutes: 1)),
          endDateTime: tripEndDate,
          onChanged: (dt) {
            transit.arrivalDateTime = dt;
            onChanged();
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
  final EntityChange<SightFacade> change;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final VoidCallback onChanged;

  const _SightTimeEditor({
    required this.change,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.onChanged,
  });

  @override
  State<_SightTimeEditor> createState() => _SightTimeEditorState();
}

class _SightTimeEditorState extends State<_SightTimeEditor> {
  SightFacade get sight => widget.change.modifiedEntity;

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
      setState(() {
        // Create a new SightFacade with the updated day since day is final
        widget.change.modifiedEntity = SightFacade(
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
      setState(() {
        final d = sight.day;
        sight.visitTime =
            DateTime(d.year, d.month, d.day, picked.hour, picked.minute);
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
  final Iterable<EntityChange<ExpenseBearingTripEntity>> expenseChanges;
  final Iterable<String> addedContributors;
  final Iterable<String> removedContributors;
  final EntityChangeMessageProvider messageProvider;
  final VoidCallback onChanged;

  const _ExpensesSection({
    required this.expenseChanges,
    required this.addedContributors,
    required this.removedContributors,
    required this.messageProvider,
    required this.onChanged,
  });

  @override
  State<_ExpensesSection> createState() => _ExpensesSectionState();
}

class _ExpensesSectionState extends State<_ExpensesSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.expenseChanges.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final expensesList = widget.expenseChanges.toList();

    return EntityChangeSection<EntityChange<ExpenseBearingTripEntity>>(
      icon: Icons.payments_rounded,
      title: widget.messageProvider.expensesSectionTitle(expensesList.length),
      iconColor: isLightTheme ? AppColors.warning : AppColors.warningLight,
      items: expensesList,
      infoMessage: widget.messageProvider.expensesSectionInfo(
        addedContributors: widget.addedContributors,
        removedContributors: widget.removedContributors,
      ),
      itemBuilder: (ctx, change) => _buildExpenseItem(ctx, change),
    );
  }

  Widget _buildExpenseItem(
    BuildContext context,
    EntityChange<ExpenseBearingTripEntity> change,
  ) {
    final entity = change.modifiedEntity;
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
              widget.onChanged();
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
