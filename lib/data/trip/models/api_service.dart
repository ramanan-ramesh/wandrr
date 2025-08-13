import 'dart:async';

abstract class ApiService<TQuery, TResult> {
  String get apiIdentifier;

  FutureOr<void> initialize();

  FutureOr<TResult> queryData(TQuery query);

  FutureOr<void> dispose();
}
