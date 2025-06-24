abstract class ApiService<T> {
  String get apiIdentifier;

  Future<void> initialize();

  Future<Iterable<T>> queryData(String query);

  Future dispose();
}
