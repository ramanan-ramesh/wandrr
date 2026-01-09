abstract class TripEntity<T> {
  String? get id;

  T clone();

  bool validate();
}
