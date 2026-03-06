import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip/itinerary_plan_data_editor_config.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary_plan_data.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
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

  Widget? createPage(TripEntity entity) {
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
      onActionInvoked: (ctx) =>
          _emitUpdateEvent<TripMetadataFacade>(ctx, entity),
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, validityNotifier, onUpdated) =>
          TripDetailsEditor(
        tripMetadataFacade: editableEntity,
        onTripMetadataUpdated: () {
          validityNotifier.value = editableEntity.validate();
          onUpdated();
        },
      ),
    );
  }

  Widget _createItineraryPage(ItineraryPlanData entity) {
    return ConflictAwareActionPage<ItineraryPlanData>(
      tripEntity: entity,
      tripData: tripData,
      isEditing: isEditing,
      title: title,
      onClosePressed: onClosePressed,
      onActionInvoked: (ctx) =>
          _emitUpdateEvent<ItineraryPlanData>(ctx, entity),
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, validityNotifier, onUpdated) =>
          ItineraryPlanDataEditor(
        planData: editableEntity,
        onPlanDataUpdated: () {
          validityNotifier.value = editableEntity.validate();
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
      onActionInvoked: (ctx) => journeyEditorKey.currentState?.saveAllLegs(ctx),
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, validityNotifier, onUpdated) =>
          JourneyEditor(
        key: journeyEditorKey,
        initialLeg: editableEntity,
        onJourneyUpdated: () {
          validityNotifier.value = editableEntity.validate();
          onUpdated();
        },
        validityNotifier: validityNotifier,
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
      onActionInvoked: (ctx) => _emitUpdateEvent<LodgingFacade>(ctx, entity),
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (editableEntity, validityNotifier, onUpdated) =>
          LodgingEditor(
        lodging: editableEntity,
        onLodgingUpdated: () {
          validityNotifier.value = editableEntity.validate();
          onUpdated();
        },
        validityNotifier: validityNotifier,
      ),
    );
  }

  Widget _createExpensePage(StandaloneExpense entity) {
    final editableEntity = entity.clone();

    return TripEditorActionPage<StandaloneExpense>(
      tripEntity: editableEntity,
      title: title,
      onActionInvoked: (ctx) =>
          _emitUpdateEvent<StandaloneExpense>(ctx, editableEntity),
      scrollController: scrollController,
      actionIcon: _actionIcon,
      pageContentCreator: (validityNotifier) => ExpenseEditor(
        expenseBearingTripEntity: editableEntity,
        onExpenseUpdated: () =>
            validityNotifier.value = editableEntity.validate(),
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
