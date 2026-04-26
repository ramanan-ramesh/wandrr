abstract class TripEntity<TValidationResult extends Enum> {
  String? get id;

  TripEntity<TValidationResult> clone();

  bool validate();

  Iterable<TValidationResult> getValidationErrors();
}
