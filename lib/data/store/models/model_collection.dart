import 'dart:async';

import 'package:wandrr/data/app/models/dispose.dart';

import 'collection_item_change_metadata.dart';
import 'collection_item_change_set.dart';
import 'leaf_repository_item.dart';

abstract class ModelCollectionFacade<T> {
  Stream<CollectionItemChangeMetadata<LeafRepositoryItem<T>>>
      get onDocumentAdded;

  Stream<
          CollectionItemChangeMetadata<
              CollectionItemChangeSet<LeafRepositoryItem<T>>>>
      get onDocumentUpdated;

  Stream<CollectionItemChangeMetadata<LeafRepositoryItem<T>>>
      get onDocumentDeleted;

  LeafRepositoryItem<T> Function(T) get leafRepositoryItemCreator;

  Iterable<LeafRepositoryItem<T>> get collectionItems;
}

abstract class ModelCollectionModifier<T> extends ModelCollectionFacade<T>
    implements Dispose {
  Future<LeafRepositoryItem<T>?> tryAdd(T toAdd);

  FutureOr<bool> tryDeleteItem(T toDelete);

  Future<void> runUpdateTransaction(Future<void> Function() updateTransaction);
}
