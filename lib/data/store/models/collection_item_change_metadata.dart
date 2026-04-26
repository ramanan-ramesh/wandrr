class CollectionItemChangeMetadata<T> {
  final T collectionItemChange;
  final bool isFromExplicitAction;

  const CollectionItemChangeMetadata(this.collectionItemChange,
      {required this.isFromExplicitAction});
}
