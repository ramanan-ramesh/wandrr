abstract class MultiOptionsAPIService<T>{
  Future<List<T>> performQuery(Object query);
}

abstract class SingleOptionAPIService<T>{
  Future<T> performQuery(Object query);
}
