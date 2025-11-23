import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/collection_names.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';

// ignore: must_be_immutable
class TripMetadataModelImplementation extends TripMetadataFacade
    implements LeafRepositoryItem<TripMetadataFacade> {
  static const String _startDateField = 'startDate';
  static const String _endDateField = 'endDate';
  static const String _nameField = 'name';
  static const String _contributorsField = 'contributors';
  static const String _thumbnailTagField = 'thumbnailTag';
  static const _budgetField = 'budget';

  TripMetadataModelImplementation.fromModelFacade(
      {required TripMetadataFacade tripMetadataModelFacade})
      : super(
            id: tripMetadataModelFacade.id,
            startDate: tripMetadataModelFacade.startDate,
            endDate: tripMetadataModelFacade.endDate,
            name: tripMetadataModelFacade.name,
            contributors: List.from(tripMetadataModelFacade.contributors),
            thumbnailTag: tripMetadataModelFacade.thumbnailTag,
            budget: tripMetadataModelFacade.budget);

  static TripMetadataModelImplementation fromDocumentSnapshot(
      DocumentSnapshot documentSnapshot) {
    var documentData = documentSnapshot.data() as Map<String, dynamic>;
    var startDateTime = (documentData[_startDateField] as Timestamp).toDate();
    var endDateTime = (documentData[_endDateField] as Timestamp).toDate();
    var contributors = List<String>.from(documentData[_contributorsField]);
    var budgetValue = documentData[_budgetField] as String;
    var thumbNailTag = documentData[_thumbnailTagField] as String;
    var budget = Money.fromDocumentData(budgetValue);

    return TripMetadataModelImplementation._(
        id: documentSnapshot.id,
        startDate: startDateTime,
        endDate: endDateTime,
        name: documentData[_nameField],
        contributors: contributors,
        thumbnailTag: thumbNailTag,
        budget: budget);
  }

  @override
  DocumentReference get documentReference => FirebaseFirestore.instance
      .collection(FirestoreCollections.tripMetadataCollectionName)
      .doc(id);

  @override
  Map<String, dynamic> toJson() => {
        _startDateField: Timestamp.fromDate(startDate!),
        _endDateField: Timestamp.fromDate(endDate!),
        _contributorsField: contributors,
        _nameField: name,
        _budgetField: budget.toString(),
        _thumbnailTagField: thumbnailTag
      };

  @override
  TripMetadataFacade get facade => clone();

  TripMetadataModelImplementation._(
      {required String super.id,
      required DateTime super.startDate,
      required DateTime super.endDate,
      required super.name,
      required super.contributors,
      required super.thumbnailTag,
      required super.budget});
}
