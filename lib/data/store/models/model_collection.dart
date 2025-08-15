import 'dart:async';

import 'package:wandrr/data/app/models/dispose.dart';

import 'collection_change_set.dart';
import 'collection_item_change_metadata.dart';
import 'leaf_repository_item.dart';

abstract class ModelCollectionFacade<T> implements Dispose {
  Stream<CollectionItemChangeMetadata<LeafRepositoryItem<T>>>
      get onDocumentAdded;

  Stream<
      CollectionItemChangeMetadata<
          CollectionChangeSet<LeafRepositoryItem<T>>>> get onDocumentUpdated;

  Stream<CollectionItemChangeMetadata<LeafRepositoryItem<T>>>
      get onDocumentDeleted;

  LeafRepositoryItem<T> Function(T) get leafRepositoryItemCreator;

  Iterable<LeafRepositoryItem<T>> get collectionItems;

  Future<LeafRepositoryItem<T>?> tryAdd(T toAdd);

  FutureOr<bool> tryDeleteItem(T toDelete);

  Future<void> runUpdateTransaction(Future<void> Function() updateTransaction);
}
