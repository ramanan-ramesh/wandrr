import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/affected_entities/affected_entities_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

/// Bottom sheet for adjusting affected entities when trip metadata changes
class AffectedEntitiesBottomSheet extends StatefulWidget {
  final TripMetadataUpdatePlan updatePlan;

  const AffectedEntitiesBottomSheet({
    super.key,
    required this.updatePlan,
  });

  @override
  State<AffectedEntitiesBottomSheet> createState() =>
      _AffectedEntitiesBottomSheetState();
}

class _AffectedEntitiesBottomSheetState
    extends State<AffectedEntitiesBottomSheet> {
  late final TripMetadataUpdatePlan _updatePlan;

  @override
  void initState() {
    super.initState();
    _updatePlan = widget.updatePlan;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      shouldCloseOnMinExtent: false,
      initialChildSize: 0.8,
      maxChildSize: 0.85,
      minChildSize: 0.5,
      builder: _buildContent,
    );
  }

  Widget _buildContent(
      BuildContext context, ScrollController scrollController) {
    const double fabBottomMargin = 25.0;
    final double bottomPadding =
        TripEditorPageConstants.fabSize + fabBottomMargin + 16.0;
    final isLightTheme = context.isLightTheme;

    return Stack(
      children: [
        Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                style: isLightTheme
                    ? ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(AppColors.brandSecondary),
                      )
                    : null,
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Adjust Affected Items'),
              centerTitle: true,
              elevation: 0,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AffectedEntitiesEditor(
                    updatePlan: _updatePlan,
                    onModelUpdated: () => setState(() {}),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: fabBottomMargin,
          left: 0,
          right: 0,
          child: Center(
            child: _buildActionButton(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: FittedBox(
        child: PlatformSubmitterFAB(
          callback: () => _applyChanges(context),
          child: const Icon(Icons.check_rounded),
        ),
      ),
    );
  }

  void _applyChanges(BuildContext context) {
    context.addTripManagementEvent(ApplyTripMetadataUpdatePlan(
      updatePlan: _updatePlan,
    ));
    // Close the bottom sheet
    Navigator.of(context).pop();
  }
}
