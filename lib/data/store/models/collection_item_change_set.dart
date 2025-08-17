class CollectionItemChangeSet<T> {
  final T beforeUpdate;
  final T afterUpdate;

  const CollectionItemChangeSet(this.beforeUpdate, this.afterUpdate);
}
