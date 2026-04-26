class Changeset<T> {
  final T beforeUpdate;
  final T afterUpdate;

  const Changeset(this.beforeUpdate, this.afterUpdate);
}
