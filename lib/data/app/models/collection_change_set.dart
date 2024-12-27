class CollectionChangeSet<T> {
  final T beforeUpdate;
  final T afterUpdate;

  const CollectionChangeSet(this.beforeUpdate, this.afterUpdate);
}
