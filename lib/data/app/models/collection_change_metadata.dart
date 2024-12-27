class CollectionChangeMetadata<T> {
  final T modifiedCollectionItem;
  final bool isFromEvent;

  const CollectionChangeMetadata(this.modifiedCollectionItem, this.isFromEvent);
}
