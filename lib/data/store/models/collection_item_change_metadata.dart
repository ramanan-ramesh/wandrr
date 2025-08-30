class CollectionItemChangeMetadata<T> {
  final T modifiedCollectionItem;
  final bool isFromExplicitAction;

  const CollectionItemChangeMetadata(this.modifiedCollectionItem,
      {required this.isFromExplicitAction});
}
