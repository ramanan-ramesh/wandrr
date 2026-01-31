import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/timeline_conflict_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

/// Bottom sheet for resolving timeline conflicts
///
/// Note: This class is deprecated. Use ConflictResolutionSubpage instead
/// which is embedded within the editors.
@Deprecated('Use ConflictResolutionSubpage instead')
class TimelineConflictBottomSheet extends StatefulWidget {
  final TripEntityUpdatePlan conflictPlan;
  final DateTime tripStartDate;
  final DateTime tripEndDate;

  const TimelineConflictBottomSheet({
    super.key,
    required this.conflictPlan,
    required this.tripStartDate,
    required this.tripEndDate,
  });

  /// Shows the conflict resolution bottom sheet and returns true if changes were applied
  static Future<bool> show({
    required BuildContext context,
    required TripEntityUpdatePlan conflictPlan,
    required DateTime tripStartDate,
    required DateTime tripEndDate,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => TimelineConflictBottomSheet(
        conflictPlan: conflictPlan,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
      ),
    );
    return result ?? false;
  }

  @override
  State<TimelineConflictBottomSheet> createState() =>
      _TimelineConflictBottomSheetState();
}

class _TimelineConflictBottomSheetState
    extends State<TimelineConflictBottomSheet> {
  late final TripEntityUpdatePlan _conflictPlan;

  @override
  void initState() {
    super.initState();
    _conflictPlan = widget.conflictPlan;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: (availableHeight - keyboardHeight).clamp(400.0, availableHeight),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: TripEditorPageConstants.fabSize + 40,
                  ),
                  child: TimelineConflictEditor(
                    conflictPlan: _conflictPlan,
                    tripStartDate: widget.tripStartDate,
                    tripEndDate: widget.tripEndDate,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(child: _buildActionButtons(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: TripEditorPageConstants.fabSize,
          height: TripEditorPageConstants.fabSize,
          child: PlatformSubmitterFAB(
            callback: () => Navigator.of(context).pop(false),
            child: const Icon(Icons.close),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: TripEditorPageConstants.fabSize,
          height: TripEditorPageConstants.fabSize,
          child: PlatformSubmitterFAB(
            callback: () {
              _applyConflictResolutions(context);
              Navigator.of(context).pop(true);
            },
            child: const Icon(Icons.check),
          ),
        ),
      ],
    );
  }

  void _applyConflictResolutions(BuildContext context) {
    // Process transit changes
    for (final change in _conflictPlan.transitChanges) {
      if (change.isMarkedForDeletion) {
        context.addTripManagementEvent(
          UpdateTripEntity<TransitFacade>.delete(
              tripEntity: change.originalEntity),
        );
      } else if (change.modifiedEntity.departureDateTime != null &&
          change.modifiedEntity.arrivalDateTime != null) {
        context.addTripManagementEvent(
          UpdateTripEntity<TransitFacade>.update(
              tripEntity: change.modifiedEntity),
        );
      }
    }

    // Process stay changes
    for (final change in _conflictPlan.stayChanges) {
      if (change.isMarkedForDeletion) {
        context.addTripManagementEvent(
          UpdateTripEntity<LodgingFacade>.delete(
              tripEntity: change.originalEntity),
        );
      } else if (change.modifiedEntity.checkinDateTime != null &&
          change.modifiedEntity.checkoutDateTime != null) {
        context.addTripManagementEvent(
          UpdateTripEntity<LodgingFacade>.update(
              tripEntity: change.modifiedEntity),
        );
      }
    }

    // Process sight changes
    for (final change in _conflictPlan.sightChanges) {
      if (change.isMarkedForDeletion) {
        context.addTripManagementEvent(
          UpdateTripEntity<SightFacade>.delete(
              tripEntity: change.originalEntity),
        );
      } else {
        context.addTripManagementEvent(
          UpdateTripEntity<SightFacade>.update(
              tripEntity: change.modifiedEntity),
        );
      }
    }
  }
}
