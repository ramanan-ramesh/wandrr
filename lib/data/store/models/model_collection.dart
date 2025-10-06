import 'dart:async';

import 'package:wandrr/data/app/models/dispose.dart';

import 'collection_item_change_metadata.dart';
import 'collection_item_change_set.dart';
import 'leaf_repository_item.dart';

abstract class ModelCollectionFacade<Model> {
  Stream<CollectionItemChangeMetadata<Model>> get onDocumentAdded;

  Stream<CollectionItemChangeMetadata<CollectionItemChangeSet<Model>>>
      get onDocumentUpdated;

  Stream<CollectionItemChangeMetadata<Model>> get onDocumentDeleted;

  Iterable<Model> get collectionItems;
}

abstract class ModelCollectionModifier<Model>
    extends ModelCollectionFacade<Model> implements Dispose {
  LeafRepositoryItem<Model> Function(Model) get repositoryItemCreator;

  Future<LeafRepositoryItem<Model>?> tryAdd(Model toAdd);

  FutureOr<bool> tryDeleteItem(Model toDelete);

  FutureOr<bool> tryUpdateItem(Model toUpdate);

  Future<void> runUpdateTransaction(Future<void> Function() updateTransaction);
}
