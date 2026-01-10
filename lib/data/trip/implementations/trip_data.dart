import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wandrr/data/store/implementations/firestore_model_collection.dart';
import 'package:wandrr/data/store/models/model_collection.dart';
import 'package:wandrr/data/trip/implementations/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/implementations/itinerary/itinerary_collection.dart';
import 'package:wandrr/data/trip/models/api_service.dart';
import 'package:wandrr/data/trip/models/api_services_repository.dart';
import 'package:wandrr/data/trip/models/budgeting/budgeting_module.dart';
import 'package:wandrr/data/trip/models/budgeting/currency_data.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/transit_option_metadata.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/app_localizations.dart';

import 'budgeting/expense.dart';
import 'lodging.dart';
import 'transit.dart';
import 'trip_metadata.dart';

class TripDataModelImplementation extends TripDataModelEventHandler {
  static Future<TripDataModelImplementation> createInstance(
      TripMetadataFacade tripMetadata,
      ApiServicesRepositoryFacade apiServicesRepository,
      AppLocalizations appLocalizations,
      String currentUserName,
      Iterable<CurrencyData> supportedCurrencies) async {
    var tripMetadataModelImplementation =
        TripMetadataModelImplementation.fromModelFacade(
            tripMetadataModelFacade: tripMetadata);

    var tripDocumentReference = FirebaseFirestore.instance
        .collection(FirestoreCollections.tripCollectionName)
        .doc(tripMetadata.id);

    var transitModelCollection = await FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.transitCollectionName),
        (documentSnapshot) => TransitImplementation.fromDocumentSnapshot(
            tripMetadata.id!, documentSnapshot),
        (transitModelFacade) => TransitImplementation.fromModelFacade(
            transitModelFacade: transitModelFacade));
    var lodgingModelCollection = await FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.lodgingCollectionName),
        (documentSnapshot) => LodgingModelImplementation.fromDocumentSnapshot(
            tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (lodgingModelFacade) => LodgingModelImplementation.fromModelFacade(
            lodgingModelFacade: lodgingModelFacade));
    var expenseModelCollection = await FirestoreModelCollection.createInstance(
        tripDocumentReference
            .collection(FirestoreCollections.expenseCollectionName),
        (documentSnapshot) =>
            StandaloneExpenseModelImplementation.fromDocumentSnapshot(
                tripId: tripMetadata.id!, documentSnapshot: documentSnapshot),
        (expenseModelFacade) =>
            StandaloneExpenseModelImplementation.fromModelFacade(
                expenseModelFacade: expenseModelFacade));

    var itineraries = await ItineraryCollection.createInstance(
        transitCollection: transitModelCollection,
        lodgingCollection: lodgingModelCollection,
        tripMetadata: tripMetadata);

    var budgetingModule = await BudgetingModule.createInstance(
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        apiServicesRepository.currencyConverter,
        tripMetadataModelImplementation.budget.currency,
        supportedCurrencies,
        tripMetadataModelImplementation.contributors,
        currentUserName,
        itineraries);

    return TripDataModelImplementation._(
        tripMetadataModelImplementation,
        transitModelCollection,
        lodgingModelCollection,
        expenseModelCollection,
        itineraries,
        apiServicesRepository.currencyConverter,
        budgetingModule,
        appLocalizations);
  }

  @override
  final ModelCollectionModifier<TransitFacade> transitCollection;

  @override
  final ModelCollectionModifier<LodgingFacade> lodgingCollection;

  @override
  final ModelCollectionModifier<StandaloneExpense> expenseCollection;

  @override
  final ItineraryCollection itineraryCollection;

  ApiService<(Money, String), double?> currencyConverter;

  @override
  TripMetadataFacade get tripMetadata =>
      _tripMetadataModelImplementation.clone();
  final TripMetadataModelImplementation _tripMetadataModelImplementation;

  @override
  final BudgetingModuleEventHandler budgetingModule;

  @override
  Future updateTripMetadata(TripMetadataFacade tripMetadata) async {
    var currentContributors = _tripMetadataModelImplementation.contributors;
    var didContributorsChange = !(const ListEquality()
        .equals(currentContributors, tripMetadata.contributors));
    var didCurrencyChange = _tripMetadataModelImplementation.budget.currency !=
        tripMetadata.budget.currency;

    if (didCurrencyChange) {
      budgetingModule.updateCurrency(tripMetadata.budget.currency);
    }

    var haveTripDatesChanged = !_tripMetadataModelImplementation.startDate!
            .isOnSameDayAs(tripMetadata.startDate!) ||
        !_tripMetadataModelImplementation.endDate!
            .isOnSameDayAs(tripMetadata.endDate!);
    var deletedLodgings = <LodgingFacade>[];
    var deletedTransits = <TransitFacade>[];
    if (haveTripDatesChanged) {
      await itineraryCollection.updateTripDays(
          tripMetadata.startDate!, tripMetadata.endDate!);
      var oldDates = _createDateRange(
          _tripMetadataModelImplementation.startDate!,
          _tripMetadataModelImplementation.endDate!);
      var newDates =
          _createDateRange(tripMetadata.startDate!, tripMetadata.endDate!);
      var datesToRemove = oldDates.difference(newDates);

      var writeBatch = FirebaseFirestore.instance.batch();
      deletedTransits.addAll(_updateTripEntityListOnDatesChanged<TransitFacade>(
          datesToRemove,
          transitCollection,
          (dateTime, transit) =>
              transit.departureDateTime!.isOnSameDayAs(dateTime) ||
              transit.arrivalDateTime!.isOnSameDayAs(dateTime),
          writeBatch));

      deletedLodgings.addAll(_updateTripEntityListOnDatesChanged<LodgingFacade>(
          datesToRemove,
          lodgingCollection,
          (dateTime, lodging) => _isStayingDuringDate(lodging, dateTime),
          writeBatch));

      await writeBatch.commit();
    }

    if (didContributorsChange) {
      await budgetingModule
          .balanceExpensesOnContributorsChanged(tripMetadata.contributors);
    }

    var shouldRecalculateTotalExpense =
        haveTripDatesChanged || didContributorsChange || didCurrencyChange;
    if (shouldRecalculateTotalExpense) {
      await budgetingModule.recalculateTotalExpenditure(
          deletedTransits: deletedTransits, deletedLodgings: deletedLodgings);
    }
    _tripMetadataModelImplementation.copyWith(tripMetadata);
  }

  @override
  Iterable<TransitOptionMetadata> get transitOptionMetadatas =>
      _transitOptionMetadatas;
  final Iterable<TransitOptionMetadata> _transitOptionMetadatas;

  @override
  Future dispose() async {
    await transitCollection.dispose();
    await lodgingCollection.dispose();
    await expenseCollection.dispose();
    await itineraryCollection.dispose();
    await budgetingModule.dispose();
  }

  Iterable<T> _updateTripEntityListOnDatesChanged<T>(
      Set<DateTime> removedDates,
      ModelCollectionModifier<T> modelCollection,
      bool Function(DateTime, T) itemsFilter,
      WriteBatch writeBatch) sync* {
    var updatedItems = <T>[];
    var currentCollectionItems = modelCollection.collectionItems;
    for (final collectionItem in currentCollectionItems) {
      if (!removedDates
          .any((removedDate) => itemsFilter(removedDate, collectionItem))) {
        updatedItems.add(collectionItem);
      } else {
        var documentReference = modelCollection
            .repositoryItemCreator(collectionItem)
            .documentReference;
        writeBatch.delete(documentReference);
        yield collectionItem;
      }
    }
  }

  static Iterable<TransitOptionMetadata> _initializeIconsAndTransitOptions(
      AppLocalizations appLocalizations) {
    var transitOptionMetadataList = <TransitOptionMetadata>[];
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.publicTransport,
        icon: Icons.emoji_transportation_rounded,
        name: appLocalizations.publicTransit));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.flight,
        icon: Icons.flight_rounded,
        name: appLocalizations.flight));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.bus,
        icon: Icons.directions_bus_rounded,
        name: appLocalizations.bus));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.cruise,
        icon: Icons.kayaking_rounded,
        name: appLocalizations.cruise));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.ferry,
        icon: Icons.directions_ferry_outlined,
        name: appLocalizations.ferry));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.rentedVehicle,
        icon: Icons.car_rental_rounded,
        name: appLocalizations.carRental));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.train,
        icon: Icons.train_rounded,
        name: appLocalizations.train));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.vehicle,
        icon: Icons.bike_scooter_rounded,
        name: appLocalizations.personalVehicle));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.walk,
        icon: Icons.directions_walk_rounded,
        name: appLocalizations.walk));
    transitOptionMetadataList.add(TransitOptionMetadata(
        transitOption: TransitOption.taxi,
        icon: Icons.local_taxi_rounded,
        name: appLocalizations.taxi));
    return transitOptionMetadataList;
  }

  Set<DateTime> _createDateRange(DateTime startDate, DateTime endDate) {
    var dateSet = <DateTime>{};
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      dateSet.add(date);
    }
    return dateSet;
  }

  bool _isStayingDuringDate(LodgingFacade lodging, DateTime date) {
    var checkinDateTime = lodging.checkinDateTime!;
    var checkoutDateTime = lodging.checkoutDateTime!;
    return (checkinDateTime.isOnSameDayAs(date) ||
            date.isAfter(checkinDateTime)) &&
        (checkoutDateTime.isOnSameDayAs(date) ||
            date.isBefore(checkoutDateTime));
  }

  TripDataModelImplementation._(
      TripMetadataModelImplementation tripMetadata,
      this.transitCollection,
      this.lodgingCollection,
      this.expenseCollection,
      this.itineraryCollection,
      this.currencyConverter,
      this.budgetingModule,
      AppLocalizations appLocalisations)
      : _tripMetadataModelImplementation = tripMetadata,
        _transitOptionMetadatas =
            _initializeIconsAndTransitOptions(appLocalisations);
}
