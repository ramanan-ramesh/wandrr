import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/editor_page_factory.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_action.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

class TripEntityEditorBottomSheet<T extends TripEntity> extends StatefulWidget {
  final TripEditorAction tripEditorAction;
  final T tripEntity;
  final ItineraryPlanDataEditorConfig? planDataEditorConfig;

  const TripEntityEditorBottomSheet({
    required this.tripEditorAction,
    required this.tripEntity,
    super.key,
    this.planDataEditorConfig,
  });

  @override
  State<TripEntityEditorBottomSheet<T>> createState() =>
      _TripEntityEditorBottomSheetState<T>();
}

class _TripEntityEditorBottomSheetState<T extends TripEntity>
    extends State<TripEntityEditorBottomSheet<T>> {
  /// The editor page is built once and reused across DraggableScrollableSheet
  /// rebuilds (which happen on every scroll). Without this, a new
  /// editableClone + editorKey would be created on every scroll, causing the
  /// GlobalKey to detach from the editor state and syncToEntity() to be a no-op.
  late final Widget _editorPage;

  @override
  void initState() {
    super.initState();
    // We need a dummy ScrollController placeholder here; the real one is
    // injected via the builder. We store the factory and build the page
    // inside the builder the FIRST time only, using a one-shot flag.
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      shouldCloseOnMinExtent: false,
      initialChildSize: 0.8,
      maxChildSize: 0.85,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        // Build the editor page lazily on the first builder call and cache it.
        // This ensures editableClone and editorKey (inside EditorPageFactory)
        // are created exactly once, not on every scroll-driven rebuild.
        if (!_isPageBuilt) {
          _isPageBuilt = true;
          final factory = EditorPageFactory(
            tripData: context.activeTrip,
            title: widget.tripEditorAction
                .getSubtitle(context.localizations, isEditing: true),
            isEditing: true,
            onClosePressed: Navigator.of(context).pop,
            scrollController: scrollController,
            itineraryConfig: widget.planDataEditorConfig,
          );
          _editorPage =
              factory.createPage(widget.tripEntity) ?? const SizedBox.shrink();
        }
        return _editorPage;
      },
    );
  }

  bool _isPageBuilt = false;
}
