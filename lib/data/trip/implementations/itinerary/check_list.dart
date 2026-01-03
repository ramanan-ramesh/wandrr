import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wandrr/data/store/models/leaf_repository_item.dart';
import 'package:wandrr/data/trip/implementations/firestore_converters.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';

/// Repository implementation for CheckList model.
/// Wraps CheckList model with Firestore-specific serialization.
// ignore: must_be_immutable
class CheckListRepositoryItem implements LeafRepositoryItem<CheckList> {
  final CheckList _checkList;

  @override
  String? id;

  CheckListRepositoryItem.fromModel(CheckList checkList)
      : _checkList = checkList,
        id = checkList.id;

  static CheckListRepositoryItem fromDocumentData({
    required Map<String, dynamic> documentData,
    required String tripId,
  }) {
    final checkList =
        CheckListFirestoreConverter.fromFirestore(documentData, tripId);
    return CheckListRepositoryItem.fromModel(checkList);
  }

  @override
  DocumentReference<Object?> get documentReference =>
      throw UnimplementedError('CheckList is embedded in ItineraryPlanData');

  @override
  Map<String, dynamic> toJson() =>
      CheckListFirestoreConverter.toFirestore(_checkList);

  @override
  CheckList get facade {
    if (id != null) {
      return _checkList.copyWith(id: id!);
    }
    return _checkList;
  }
}

// Legacy alias for backward compatibility
typedef CheckListModelImplementation = CheckListRepositoryItem;
