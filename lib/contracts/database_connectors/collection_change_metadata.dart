class CollectionChangeMetadata<T> {
  T modifiedCollectionItem;
  bool isFromEvent;

  CollectionChangeMetadata(this.modifiedCollectionItem, this.isFromEvent);
}
