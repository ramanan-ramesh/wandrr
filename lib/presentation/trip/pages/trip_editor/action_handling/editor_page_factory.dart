import 'package:flutter/material.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/presentation/trip/bloc_extensions.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/action_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/conflict_aware_action_page.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/budgeting/expenses/expense_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/itinerary/itinerary_plan_data_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/lodging/lodging_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/transit/journey_editor.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_details/trip_details_editor.dart';

/// Factory for creating editor action pages.
/// Centralizes all editor page creation logic.
class EditorPageFactory {
  final TripDataFacade tripData;
  final String title;
  final bool isEditing;
  final VoidCallback onClosePressed;
  final ScrollController scrollController;
  final ItineraryPlanDataEditorConfig? itineraryConfig;

  EditorPageFactory({
    required this.tripData,
    required this.title,
    required this.isEditing,
    required this.onClosePressed,
    required this.scrollController,
    this.itineraryConfig,
  });

  Widget? createPage(TripEntity<Enum> entity) {
    if (entity is TripMetadataFacade) {
      return _createTripDetailsPage(entity);
    } else if (entity is ItineraryPlanData) {
      return _createItineraryPage(entity);
    } else if (entity is TransitFacade) {
      return _createTransitPage(entity);
    } else if (entity is LodgingFacade) {
      return _createStayPage(entity);
    } else if (entity is StandaloneExpense) {
      return _createExpensePage(entity);
    }
    return null;
  }

  Widget _createTripDetailsPage(TripMetadataFacade entity) {
    return ConflictAwareActionPage<TripMetadataFacade>(
      tripEntity: entity,
      tripData: tripData,
      isEditing: isEditing,
      title: title,
      onClosePressed: onClosePressed,
      onActionInvoked: (ctx) {
        final editable = ctx.editableEntity<TripMetadataFacade>();
        if (isEditing && editable == entity) return 0;
        _emitUpdateEvent<TripMetadataFacade>(ctx, editable);
        return 1;
      },
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, onUpdated) => TripDetailsEditor(
        tripMetadataFacade: editableEntity,
        onTripMetadataUpdated: () {
          onUpdated();
        },
      ),
    );
  }

  Widget _createItineraryPage(ItineraryPlanData entity) {
    final editorKey = GlobalKey<ItineraryPlanDataEditorState>();

    return ConflictAwareActionPage<ItineraryPlanData>(
      tripEntity: entity,
      tripData: tripData,
      isEditing: isEditing,
      title: title,
      onClosePressed: onClosePressed,
      onActionInvoked: (ctx) {
        final editableEntity = ctx.editableEntity<ItineraryPlanData>();
        // Write stable lists → entity right before the update event is emitted.
        editorKey.currentState?.syncToEntity();

        // Simple update — skip if the entity is unchanged.
        if (isEditing && editableEntity == entity) return 0;
        _emitUpdateEvent<ItineraryPlanData>(ctx, editableEntity);
        return 1;
      },
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, onUpdated) =>
          ItineraryPlanDataEditor(
        key: editorKey,
        planData: editableEntity,
        onPlanDataUpdated: () {
          onUpdated();
        },
        config: itineraryConfig!,
      ),
    );
  }

  Widget _createTransitPage(TransitFacade entity) {
    final journeyEditorKey = GlobalKey<JourneyEditorState>();

    return ConflictAwareActionPage<TransitFacade>(
      tripEntity: entity,
      tripData: tripData,
      isEditing: isEditing,
      title: title,
      onClosePressed: onClosePressed,
      onActionInvoked: (ctx) =>
          journeyEditorKey.currentState?.saveAllLegs(ctx) ?? 0,
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, onUpdated) => JourneyEditor(
        key: journeyEditorKey,
        initialLeg: editableEntity,
        onJourneyUpdated: () {
          onUpdated();
        },
      ),
    );
  }

  Widget _createStayPage(LodgingFacade entity) {
    return ConflictAwareActionPage<LodgingFacade>(
      tripEntity: entity,
      tripData: tripData,
      isEditing: isEditing,
      title: title,
      onClosePressed: onClosePressed,
      onActionInvoked: (ctx) {
        final editable = ctx.editableEntity<LodgingFacade>();
        if (isEditing && editable == entity) return 0;
        _emitUpdateEvent<LodgingFacade>(ctx, editable);
        return 1;
      },
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, onUpdated) => LodgingEditor(
        lodging: editableEntity,
        onLodgingUpdated: () {
          onUpdated();
        },
      ),
    );
  }

  Widget _createExpensePage(StandaloneExpense entity) {
    final editableEntity = entity.clone();

    return TripEditorActionPage<StandaloneExpense>(
      tripEntity: editableEntity,
      title: title,
      onClosePressed: onClosePressed,
      onActionInvoked: (ctx) {
        if (isEditing && editableEntity == entity) return 0;
        _emitUpdateEvent<StandaloneExpense>(ctx, editableEntity);
        return 1;
      },
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (validityNotifier) => ExpenseEditor(
        expenseBearingTripEntity: editableEntity,
        onExpenseUpdated: () =>
            validityNotifier.value = editableEntity.getValidationErrors(),
      ),
    );
  }

  /// Creates a page that always shows [ExpenseEditor] for any
  /// [ExpenseBearingTripEntity], regardless of its concrete type.
  /// Used when tapping an item from the expense list view.
  Widget? createExpenseEditorPage(ExpenseBearingTripEntity entity) {
    if (entity is StandaloneExpense) {
      return _createExpensePage(entity);
    } else if (entity is TransitFacade) {
      return _createExpenseBearingTripEntityEditorPage<TransitFacade>(entity);
    } else if (entity is LodgingFacade) {
      return _createExpenseBearingTripEntityEditorPage<LodgingFacade>(entity);
    }
    // Fallback: let the default router handle it
    return createPage(entity as TripEntity<Enum>);
  }

  Widget _createExpenseBearingTripEntityEditorPage<
      T extends ExpenseBearingTripEntity>(T entity) {
    return ConflictAwareActionPage<T>(
      tripEntity: entity,
      tripData: tripData,
      isEditing: isEditing,
      title: title,
      onClosePressed: onClosePressed,
      onActionInvoked: (ctx) {
        final editable = ctx.editableEntity<T>();
        if (isEditing && editable == entity) return 0;
        _emitUpdateEvent<T>(ctx, editable);
        return 1;
      },
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, onUpdated) => ExpenseEditor(
        expenseBearingTripEntity: editableEntity,
        onExpenseUpdated: onUpdated,
      ),
    );
  }

  IconData get _actionIcon =>
      isEditing ? Icons.check_rounded : Icons.add_rounded;

  void _emitUpdateEvent<T extends TripEntity>(BuildContext ctx, T entity) {
    ctx.addTripManagementEvent(
      isEditing
          ? UpdateTripEntity<T>.update(tripEntity: entity)
          : UpdateTripEntity<T>.create(tripEntity: entity),
    );
  }
}
