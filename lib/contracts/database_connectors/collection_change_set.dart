class CollectionChangeSet<T> {
  final T beforeUpdate;
  final T afterUpdate;

  CollectionChangeSet(this.beforeUpdate, this.afterUpdate);
}
