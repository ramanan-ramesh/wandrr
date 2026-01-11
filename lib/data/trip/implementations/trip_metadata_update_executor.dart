import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_metadata_update.dart';

import 'itinerary/itinerary_plan_data_implementation.dart';

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

    for (final transitPlan in plan.transitChanges) {
      if (transitPlan.isDelete) {
        final doc =
            transitCollection.repositoryItemCreator(transitPlan.originalEntity);
        batch.delete(doc.documentReference);
      } else if (transitPlan.isUpdate) {
        final modifiedTransit = transitPlan.modifiedEntity;
        final updatedTransitExpense = plan.expenseChanges.singleWhere((e) =>
            e.originalEntity is TransitFacade &&
            e.originalEntity.id == modifiedTransit.id);
        modifiedTransit.expense = updatedTransitExpense.modifiedEntity.expense;
        if (modifiedTransit != transitPlan.originalEntity &&
            modifiedTransit.validate()) {
          final doc = transitCollection.repositoryItemCreator(modifiedTransit);
          batch.update(doc.documentReference, doc.toJson());
        }
      }
    }

    for (final stayPlan in plan.stayChanges) {
      if (stayPlan.isDelete) {
        final doc =
            lodgingCollection.repositoryItemCreator(stayPlan.originalEntity);
        batch.delete(doc.documentReference);
      } else if (stayPlan.isUpdate) {
        final modifiedStay = stayPlan.modifiedEntity;
        final updatedStayExpense = plan.expenseChanges.singleWhere((e) =>
            e.originalEntity is LodgingFacade &&
            e.originalEntity.id == modifiedStay.id);
        modifiedStay.expense = updatedStayExpense.modifiedEntity.expense;
        if (modifiedStay != stayPlan.originalEntity &&
            modifiedStay.validate()) {
          final doc = lodgingCollection.repositoryItemCreator(modifiedStay);
          batch.update(doc.documentReference, doc.toJson());
        }
      }
    }

    // Process sight changes through itinerary plan data updates
    _processSightChanges(plan, batch);

    // Process expense split changes
    _processExpenseSplitChanges(plan, batch);

    // Commit all changes atomically
    await batch.commit();
  }

  /// Process sight changes by computing the final state of each affected itinerary's plan data
  /// and writing them in a batch.
  ///
  /// This handles:
  /// - Deleting sights from their current day
  /// - Moving sights to a different day (remove from old, add to new)
  /// - Updating sights in place
  ///
  /// For days that don't have an itinerary yet (new days), we create the plan data document.
  void _processSightChanges(
    TripMetadataUpdatePlan plan,
    WriteBatch batch,
  ) {
    if (plan.sightChanges.isEmpty) return;

    // Build a map of day -> list of sights to remove (by id)
    final sightsToRemoveByDay = <String, Set<String>>{};
    // Build a map of day -> list of sights to add/update
    final sightsToAddByDay = <String, List<SightFacade>>{};
    // Track which existing itinerary plan data we need to read
    final sightsToUpdateByDay = <SightFacade>[];
    // Process each sight change
    final affectedDays = <String>{};

    for (final change in plan.sightChanges) {
      final originalDay = change.originalEntity.day;
      final originalDayKey = originalDay.itineraryDateFormat;

      if (change.isDelete) {
        // Remove sight from its current day
        sightsToRemoveByDay.putIfAbsent(originalDayKey, () => {});
        sightsToRemoveByDay[originalDayKey]!.add(change.originalEntity.id!);
        affectedDays.add(originalDayKey);
      } else if (change.isUpdate) {
        final newDay = change.modifiedEntity.day;
        final newDayKey = newDay.itineraryDateFormat;

        if (!originalDay.isOnSameDayAs(newDay)) {
          // Sight is moving to a different day
          // Remove from original day
          sightsToRemoveByDay.putIfAbsent(originalDayKey, () => {});
          sightsToRemoveByDay[originalDayKey]!.add(change.originalEntity.id!);
          affectedDays.add(originalDayKey);

          // Add to new day
          if (change.modifiedEntity.validate()) {
            sightsToAddByDay.putIfAbsent(newDayKey, () => []);
            sightsToAddByDay[newDayKey]!.add(change.modifiedEntity);
            affectedDays.add(newDayKey);
          }
        } else if (change.modifiedEntity.validate()) {
          // Sight stays on the same day, just update it
          sightsToUpdateByDay.add(change.modifiedEntity);
          affectedDays.add(originalDayKey);
        }
      }
    }

    // Now process each affected day
    for (final dayKey in affectedDays) {
      // Ignore if day is outside the trip's date range.
      // Such Itineraries will be handled by ItineraryCollection.updateTripDays
      final day = DateTime.parse(dayKey);
      if (day.isBefore(plan.newMetadata.startDate!) ||
          day.isAfter(plan.newMetadata.endDate!)) {
        continue;
      }

      // Try to find existing itinerary for this day
      ItineraryModelEventHandler? existingItinerary = itineraryCollection
          .where(
            (it) => it.day.itineraryDateFormat == dayKey,
          )
          .firstOrNull;

      // Start with existing sights or empty list
      List<SightFacade> currentSights =
          List.from(existingItinerary?.planData.sights ?? []);
      List<String> currentNotes =
          List.from(existingItinerary?.planData.notes ?? []);
      List<CheckListFacade> currentCheckLists =
          List.from(existingItinerary?.planData.checkLists ?? []);

      //Update sights
      for (final sight in sightsToUpdateByDay) {
        final existingIndex = currentSights.indexWhere((s) => s.id == sight.id);
        if (existingIndex >= 0) {
          var updatedSightExpense = plan.expenseChanges
              .where((e) =>
                  e.originalEntity is SightFacade &&
                  e.originalEntity.id == sight.id)
              .singleOrNull;
          if (updatedSightExpense != null) {
            sight.expense = updatedSightExpense.modifiedEntity.expense;
          }
          currentSights[existingIndex] = sight;
        }
      }

      // Remove sights marked for removal
      final toRemove = sightsToRemoveByDay[dayKey] ?? {};
      currentSights.removeWhere((s) => toRemove.contains(s.id));

      // Add sights
      currentSights.addAll(sightsToAddByDay[dayKey] ?? []);

      final itineraryPlanData = ItineraryPlanDataModelImplementation(
        tripId: plan.newMetadata.id!,
        day: DateTime.parse(dayKey),
        sights: currentSights,
        notes: currentNotes,
        checkLists: currentCheckLists,
      );

      // Use set with merge to create or update the document
      if (existingItinerary != null &&
          existingItinerary.planData != itineraryPlanData) {
        batch.set(itineraryPlanData.documentReference,
            itineraryPlanData.toJson(), SetOptions(merge: false));
      } else {
        batch.set(itineraryPlanData.documentReference,
            itineraryPlanData.toJson(), SetOptions(merge: false));
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
