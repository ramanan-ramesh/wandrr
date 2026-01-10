import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
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

    // Step 1: Execute entity changes in a batch
    if (plan.hasEntityChanges || plan.hasDateChanges) {
      await _executeEntityChanges(plan);
    }

    // Step 2: Update itinerary days (after entities are updated)
    if (plan.hasDateChanges) {
      await itineraryCollection.updateTripDays(
        plan.newMetadata.startDate!,
        plan.newMetadata.endDate!,
      );
    }

    // Step 3: Recalculate total expenditure
    if (plan.hasEntityChanges ||
        plan.hasDateChanges ||
        plan.hasCurrencyChange) {
      await budgetingModule.recalculateTotalExpenditure();
    }
  }

  Future<void> _executeEntityChanges(TripMetadataUpdatePlan plan) async {
    final batch = FirebaseFirestore.instance.batch();

    // Process transit deletions
    for (final transit in plan.deletedTransits) {
      final doc = transitCollection.repositoryItemCreator(transit);
      batch.delete(doc.documentReference);
    }

    // Process transit updates
    for (final transit in plan.updatedTransits) {
      final doc = transitCollection.repositoryItemCreator(transit);
      batch.update(doc.documentReference, doc.toJson());
    }

    // Process stay deletions
    for (final stay in plan.deletedStays) {
      final doc = lodgingCollection.repositoryItemCreator(stay);
      batch.delete(doc.documentReference);
    }

    // Process stay updates
    for (final stay in plan.updatedStays) {
      final doc = lodgingCollection.repositoryItemCreator(stay);
      batch.update(doc.documentReference, doc.toJson());
    }

    // Process sight changes through itinerary plan data updates
    await _processSightChanges(plan, batch);

    // Process expense split changes
    await _processExpenseSplitChanges(plan, batch);

    // Commit all changes atomically
    await batch.commit();
  }

  Future<void> _processSightChanges(
    TripMetadataUpdatePlan plan,
    WriteBatch batch,
  ) async {
    // Group sight changes by day for efficient itinerary updates
    final sightsByDay = <DateTime, List<EntityChange<SightFacade>>>{};

    for (final change in plan.sightChanges) {
      final day = change.originalEntity.day;
      final normalizedDay = DateTime(day.year, day.month, day.day);
      sightsByDay.putIfAbsent(normalizedDay, () => []).add(change);

      // If sight is being moved to a different day, also track the new day
      if (change.isUpdate) {
        final newDay = change.modifiedEntity.day;
        final normalizedNewDay =
            DateTime(newDay.year, newDay.month, newDay.day);
        if (!normalizedDay.isOnSameDayAs(normalizedNewDay)) {
          sightsByDay.putIfAbsent(normalizedNewDay, () => []).add(change);
        }
      }
    }

    // Update each affected itinerary's plan data
    for (final entry in sightsByDay.entries) {
      final day = entry.key;
      final changes = entry.value;

      try {
        final itinerary = itineraryCollection.getItineraryForDay(day);
        final planData = itinerary.planData;

        for (final change in changes) {
          if (change.isDelete) {
            // Remove sight from this day
            planData.sights
                .removeWhere((s) => s.id == change.originalEntity.id);
          } else if (change.isUpdate) {
            final originalDay = change.originalEntity.day;
            final newDay = change.modifiedEntity.day;

            if (day.isOnSameDayAs(originalDay) &&
                !originalDay.isOnSameDayAs(newDay)) {
              // Remove from original day
              planData.sights
                  .removeWhere((s) => s.id == change.originalEntity.id);
            } else if (day.isOnSameDayAs(newDay)) {
              // Add/update on new day
              final existingIndex = planData.sights.indexWhere(
                (s) => s.id == change.originalEntity.id,
              );
              if (existingIndex >= 0) {
                planData.sights[existingIndex] = change.modifiedEntity;
              } else {
                planData.sights.add(change.modifiedEntity);
              }
            }
          }
        }

        // Queue the plan data update in the batch
        await itinerary.updatePlanData(planData);
      } catch (e) {
        // Itinerary for this day doesn't exist (may have been removed)
        // This is expected for deleted days
      }
    }
  }

  Future<void> _processExpenseSplitChanges(
    TripMetadataUpdatePlan plan,
    WriteBatch batch,
  ) async {
    for (final change in plan.expenseChanges) {
      if (!change.includeInSplitBy || change.isMarkedForDeletion) continue;

      final entity = change.modifiedEntity;
      final expense = entity.expense;

      // Add new contributors to splitBy
      for (final contributor in plan.addedContributors) {
        if (!expense.splitBy.contains(contributor)) {
          expense.splitBy.add(contributor);
        }
      }

      // Update the entity based on its type
      if (entity is StandaloneExpense) {
        final doc = expenseCollection.repositoryItemCreator(entity);
        batch.update(doc.documentReference, doc.toJson());
      } else if (entity is TransitFacade) {
        final doc = transitCollection.repositoryItemCreator(entity);
        batch.update(doc.documentReference, doc.toJson());
      } else if (entity is LodgingFacade) {
        final doc = lodgingCollection.repositoryItemCreator(entity);
        batch.update(doc.documentReference, doc.toJson());
      }
      // Sight expenses are handled through itinerary plan data updates
    }
  }
}
