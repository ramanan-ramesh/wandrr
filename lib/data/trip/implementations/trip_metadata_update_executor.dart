import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';

/// Implementation that uses Firestore batch writes
///
/// Handler for executing trip metadata update plans using batch writes
///
/// The update order is critical:
/// 1. Update/delete transits, stays, sights, expenses (entity changes)
/// 2. Update itinerary days (add/remove days)
/// 3. Recalculate total expenditure
class TripMetadataUpdateExecutor {
  final ModelCollectionModifier<TransitFacade> transitCollection;
  final ModelCollectionModifier<LodgingFacade> lodgingCollection;
  final ModelCollectionModifier<StandaloneExpense> expenseCollection;
  final ItineraryFacadeCollectionEventHandler itineraryCollection;
  final BudgetingModuleEventHandler budgetingModule;

  TripMetadataUpdateExecutor({
    required this.transitCollection,
    required this.lodgingCollection,
    required this.expenseCollection,
    required this.itineraryCollection,
    required this.budgetingModule,
  });

  /// Executes the update plan using batch writes
  ///
  /// Returns a Future that completes when all updates are committed
  Future<void> execute(TripMetadataUpdatePlan plan) async {
    // Step 0: Update currency if changed (stateless, can happen anytime)
    if (plan.hasCurrencyChange) {
      budgetingModule.updateCurrency(plan.newMetadata.budget.currency);
    }

    // Step 1: Execute all entity and itinerary changes in a single batch
    if (plan.hasEntityChanges || plan.hasDateChanges) {
      await _executeAllChanges(plan);
    }

    // Step 2: Recalculate total expenditure
    if (plan.hasEntityChanges ||
        plan.hasDateChanges ||
        plan.hasCurrencyChange) {
      await budgetingModule.recalculateTotalExpenditure();
    }
  }

  Future<void> _executeAllChanges(TripMetadataUpdatePlan plan) async {
    final batch = FirebaseFirestore.instance.batch();

    // Prepare itinerary day updates with sight changes (adds deletions/creations/updates to batch)
    final updateLocalItineraryState =
        await itineraryCollection.prepareTripDaysUpdate(
      batch,
      plan.newMetadata.startDate!,
      plan.newMetadata.endDate!,
      plan.sightChanges,
      plan.expenseChanges,
    );

    // Process other entity changes
    _processTransitChanges(plan, batch);
    _processStayChanges(plan, batch);
    _processExpenseSplitChanges(plan, batch);

    // Commit all changes atomically
    await batch.commit();

    // Update local itinerary state after successful commit
    await updateLocalItineraryState();
  }

  void _processTransitChanges(TripMetadataUpdatePlan plan, WriteBatch batch) {
    for (final transitPlan in plan.transitChanges) {
      if (transitPlan.isDelete) {
        final doc =
            transitCollection.repositoryItemCreator(transitPlan.originalEntity);
        batch.delete(doc.documentReference);
      } else if (transitPlan.isUpdate) {
        final modifiedTransit = transitPlan.modifiedEntity;
        final updatedTransitExpense = plan.expenseChanges
            .where((e) =>
                e.originalEntity is TransitFacade &&
                e.originalEntity.id == modifiedTransit.id)
            .singleOrNull;
        if (updatedTransitExpense != null) {
          modifiedTransit.expense =
              updatedTransitExpense.modifiedEntity.expense;
        }
        if (modifiedTransit != transitPlan.originalEntity &&
            modifiedTransit.validate()) {
          final doc = transitCollection.repositoryItemCreator(modifiedTransit);
          batch.update(doc.documentReference, doc.toJson());
        }
      }
    }
  }

  void _processStayChanges(TripMetadataUpdatePlan plan, WriteBatch batch) {
    for (final stayPlan in plan.stayChanges) {
      if (stayPlan.isDelete) {
        final doc =
            lodgingCollection.repositoryItemCreator(stayPlan.originalEntity);
        batch.delete(doc.documentReference);
      } else if (stayPlan.isUpdate) {
        final modifiedStay = stayPlan.modifiedEntity;
        final updatedStayExpense = plan.expenseChanges
            .where((e) =>
                e.originalEntity is LodgingFacade &&
                e.originalEntity.id == modifiedStay.id)
            .singleOrNull;
        if (updatedStayExpense != null) {
          modifiedStay.expense = updatedStayExpense.modifiedEntity.expense;
        }
        if (modifiedStay != stayPlan.originalEntity &&
            modifiedStay.validate()) {
          final doc = lodgingCollection.repositoryItemCreator(modifiedStay);
          batch.update(doc.documentReference, doc.toJson());
        }
      }
    }
  }

  void _processExpenseSplitChanges(
    TripMetadataUpdatePlan plan,
    WriteBatch batch,
  ) {
    for (final change in plan.expenseChanges
        .where((expense) => expense.modifiedEntity is StandaloneExpense)) {
      if (!change.includeInSplitBy && !change.isMarkedForDeletion) {
        continue;
      }

      if (!change.modifiedEntity.validate()) {
        continue;
      }

      final entity = change.modifiedEntity as StandaloneExpense;
      final doc = expenseCollection.repositoryItemCreator(entity);
      if (change.isMarkedForDeletion) {
        batch.delete(doc.documentReference);
      } else {
        final expense = entity.expense;

        // Add new contributors to splitBy
        for (final contributor in plan.addedContributors) {
          if (!expense.splitBy.contains(contributor)) {
            expense.splitBy.add(contributor);
          }
        }

        batch.update(doc.documentReference, doc.toJson());
      }
    }
  }
}
