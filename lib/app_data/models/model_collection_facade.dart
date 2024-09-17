import 'dart:async';

import 'collection_change_metadata.dart';
import 'collection_change_set.dart';
import 'repository_pattern.dart';

abstract class ModelCollectionFacade<T> implements Dispose {
  Stream<CollectionChangeMetadata<RepositoryPattern<T>>> get onDocumentAdded;

  Stream<CollectionChangeMetadata<CollectionChangeSet<RepositoryPattern<T>>>>
      get onDocumentUpdated;

  Stream<CollectionChangeMetadata<RepositoryPattern<T>>> get onDocumentDeleted;

  RepositoryPattern<T> Function(T) get repositoryPatternCreator;

  List<RepositoryPattern<T>> get collectionItems;

  Future<RepositoryPattern<T>?> tryAdd(T toAdd);

  Future<void> runUpdateTransaction(Future<void> Function() updateTransaction);

  FutureOr<bool> tryDeleteItem(T toDelete);
}
