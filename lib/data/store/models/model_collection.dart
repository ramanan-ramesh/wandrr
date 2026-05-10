import 'dart:async';

import 'package:wandrr/data/app/models/dispose.dart';

import 'change_set.dart';
import 'collection_item_change_metadata.dart';
import 'collection_item_document.dart';

abstract class ModelCollectionFacade<TModel> {
  Stream<CollectionItemChangeMetadata<TModel>> get onDocumentAdded;

  Stream<CollectionItemChangeMetadata<Changeset<TModel>>> get onDocumentUpdated;

  Stream<CollectionItemChangeMetadata<TModel>> get onDocumentDeleted;

  Iterable<TModel> get items;

  bool get isLoaded;

  Stream<bool> get onLoaded;
}

abstract class ModelCollectionModifier<TModel>
    extends ModelCollectionFacade<TModel> implements Dispose {
  CollectionDocument<TModel> Function(TModel) get collectionDocumentCreator;

  void tryAdd(TModel toAdd);

  void tryDeleteItem(TModel toDelete);

  void tryUpdateItem(TModel toUpdate);
}
