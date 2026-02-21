import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

/// Unified executor for TripEntityUpdatePlan using Firestore batch writes.
/// Handles both TripMetadata updates and conflict resolution.
class TripEntityDataUpdatePlanExecutor {
  final ModelCollectionModifier<TransitFacade> transitCollection;
  final ModelCollectionModifier<LodgingFacade> lodgingCollection;
  final ModelCollectionModifier<StandaloneExpense> expenseCollection;
  final ItineraryFacadeCollectionEventHandler itineraryCollection;
  final BudgetingModuleEventHandler budgetingModule;

  TripEntityDataUpdatePlanExecutor({
    required this.transitCollection,
    required this.lodgingCollection,
    required this.expenseCollection,
    required this.itineraryCollection,
    required this.budgetingModule,
  });

  /// Executes the update plan using batch writes
  Future<void> execute<T extends TripEntity>(
      TripEntityUpdatePlan<T> plan) async {
    final isTripMetadataUpdate = plan.oldEntity is TripMetadataFacade;
    final haveTripDatesChanged = _haveTripDatesChanged(plan);
    final hasDefaultCurrencyChanged = _hasDefaultCurrencyChanged(plan);

    // Step 0: Update currency if changed (TripMetadata only)
    if (hasDefaultCurrencyChanged) {
      final newMeta = plan.newEntity as TripMetadataFacade;
      budgetingModule.updateCurrency(newMeta.budget.currency);
    }

    // Step 1: Execute all entity changes in a single batch
    if (plan.hasConflicts || haveTripDatesChanged) {
      await _executeAllChanges(plan);
    }

    // Step 2: Recalculate total expenditure if needed
    if (plan.hasConflicts ||
        (isTripMetadataUpdate &&
            (haveTripDatesChanged || hasDefaultCurrencyChanged))) {
      await budgetingModule.recalculateTotalExpenditure();
    }
  }

  bool _haveTripDatesChanged<T extends TripEntity>(
      TripEntityUpdatePlan<T> plan) {
    if (plan is! TripEntityUpdatePlan<TripMetadataFacade>) {
      return false;
    }
    final oldMeta = plan.oldEntity as TripMetadataFacade;
    final newMeta = plan.newEntity as TripMetadataFacade;
    return !oldMeta.startDate!.isOnSameDayAs(newMeta.startDate!) ||
        !oldMeta.endDate!.isOnSameDayAs(newMeta.endDate!);
  }

  bool _hasDefaultCurrencyChanged<T extends TripEntity>(
      TripEntityUpdatePlan<T> plan) {
    if (plan is! TripEntityUpdatePlan<TripMetadataFacade>) {
      return false;
    }
    final oldMeta = plan.oldEntity as TripMetadataFacade;
    final newMeta = plan.newEntity as TripMetadataFacade;
    return oldMeta.budget.currency != newMeta.budget.currency;
  }

  Future<void> _executeAllChanges<T extends TripEntity>(
      TripEntityUpdatePlan<T> plan) async {
    final batch = FirebaseFirestore.instance.batch();
    Future<void> Function()? updateLocalItineraryState;

    // For TripMetadata updates, prepare itinerary day updates
    if (plan is TripEntityUpdatePlan<TripMetadataFacade> &&
        _haveTripDatesChanged(plan)) {
      final newMeta = plan.newEntity as TripMetadataFacade;
      updateLocalItineraryState =
          await itineraryCollection.prepareTripDaysUpdate(
        batch,
        newMeta.startDate!,
        newMeta.endDate!,
        plan.sightChanges,
        plan.expenseChanges,
      );
    } else if (plan.sightChanges.isNotEmpty) {
      // For conflict resolution, just update sights
      updateLocalItineraryState = await itineraryCollection.prepareSightUpdates(
          batch, plan.sightChanges);
    }

    // Process transit changes
    _processChanges<TransitFacade>(plan.transitChanges, plan.expenseChanges,
        plan.addedContributors, transitCollection, batch);

    // Process stay changes
    _processChanges<LodgingFacade>(plan.stayChanges, plan.expenseChanges,
        plan.addedContributors, lodgingCollection, batch);

    // Process standalone expense changes
    if (plan is TripEntityUpdatePlan<TripMetadataFacade>) {
      _processExpenseChanges(
          plan.expenseChanges, plan.addedContributors, batch);
    }

    // Commit all changes atomically
    await batch.commit();

    // Update local itinerary state after successful commit
    if (updateLocalItineraryState != null) {
      await updateLocalItineraryState();
    }
  }

  void _processChanges<T extends TripEntity>(
    List<DateTimeChange<T>> changes,
    List<ExpenseSplitChange> expenseChanges,
    Iterable<String> addedContributors,
    ModelCollectionModifier<T> modelCollection,
    WriteBatch batch,
  ) {
    for (final change in changes) {
      if (change.isDelete) {
        final doc = modelCollection.repositoryItemCreator(change.original);
        batch.delete(doc.documentReference);
      } else if (change.isUpdate && change.modified.validate()) {
        // Add new contributors to expense splitBy if needed
        final expenseChange = expenseChanges
            .where((expenseChange) =>
                expenseChange.original is ExpenseBearingTripEntity<T>)
            .singleOrNull;
        if (expenseChange != null) {
          if (expenseChange.includeInSplitBy) {
            _addContributorsToExpense(
                expenseChange.modified.expense, addedContributors);
          }
        }
        final doc = modelCollection.repositoryItemCreator(change.modified);
        batch.update(doc.documentReference, doc.toJson());
      }
    }
  }

  void _processExpenseChanges(
    List<ExpenseSplitChange> changes,
    Iterable<String> addedContributors,
    WriteBatch batch,
  ) {
    for (final change in changes) {
      // Skip if not a standalone expense
      if (change.modified is! StandaloneExpense) continue;

      // Skip if not marked for inclusion and not being deleted
      if (!change.includeInSplitBy && !change.isMarkedForDeletion) continue;

      // Skip invalid entities
      if (!change.modified.validate()) continue;

      final entity = change.modified as StandaloneExpense;
      final doc = expenseCollection.repositoryItemCreator(entity);

      if (change.isMarkedForDeletion) {
        batch.delete(doc.documentReference);
      } else {
        _addContributorsToExpense(entity.expense, addedContributors);
        batch.update(doc.documentReference, doc.toJson());
      }
    }
  }

  void _addContributorsToExpense(
    ExpenseFacade expense,
    Iterable<String> addedContributors,
  ) {
    for (final contributor in addedContributors) {
      if (!expense.splitBy.contains(contributor)) {
        expense.splitBy.add(contributor);
      }
    }
  }
}
