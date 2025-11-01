import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/plan_data_edit_context.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';

class TripEntityEditorBottomSheet<T extends TripEntity>
    extends StatelessWidget {
  final TripEditorAction tripEditorAction;
  final T tripEntity;
  final ItineraryPlanDataEditorConfig? planDataEditorConfig;

  const TripEntityEditorBottomSheet({
    super.key,
    required this.tripEditorAction,
    required this.tripEntity,
    this.planDataEditorConfig,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      shouldCloseOnMinExtent: false,
      initialChildSize: 0.8,
      maxChildSize: 0.85,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return tripEditorAction.createActionPage(
            tripEntity: tripEntity,
            isEditing: true,
            onClosePressed: (context) => Navigator.of(context).pop(),
            scrollController: scrollController,
            itineraryConfig: planDataEditorConfig,
            title:
                tripEditorAction.createSubtitle(context.localizations, true))!;
      },
    );
  }
}
