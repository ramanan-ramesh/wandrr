abstract class TripEntity<TValidationResult extends Enum> {
  String? get id;

  TripEntity<TValidationResult> clone();

  Iterable<TValidationResult> getValidationErrors();
}
