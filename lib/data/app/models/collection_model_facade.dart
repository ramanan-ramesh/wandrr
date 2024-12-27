import 'dart:async';

import 'collection_change_metadata.dart';
import 'collection_change_set.dart';
import 'leaf_repository_item.dart';

abstract class CollectionModelFacade<T> implements Dispose {
  Stream<CollectionChangeMetadata<LeafRepositoryItem<T>>> get onDocumentAdded;

  Stream<CollectionChangeMetadata<CollectionChangeSet<LeafRepositoryItem<T>>>>
      get onDocumentUpdated;

  Stream<CollectionChangeMetadata<LeafRepositoryItem<T>>> get onDocumentDeleted;

  LeafRepositoryItem<T> Function(T) get leafRepositoryItemCreator;

  Iterable<LeafRepositoryItem<T>> get collectionItems;

  Future<LeafRepositoryItem<T>?> tryAdd(T toAdd);

  FutureOr<bool> tryDeleteItem(T toDelete);

  Future<void> runUpdateTransaction(Future<void> Function() updateTransaction);
}
