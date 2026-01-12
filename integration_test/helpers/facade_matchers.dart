import 'package:flutter_test/flutter_test.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';

/// Custom matcher for TransitFacade that ignores the auto-generated id field
Matcher matchesTransit(TransitFacade expected) => _TransitMatcher(expected);

/// Custom matcher for ExpenseFacade that ignores the auto-generated id field
Matcher matchesStandaloneExpense(StandaloneExpense expected) =>
    _StandaloneExpenseMatcher(expected);

/// Custom matcher for ExpenseFacade that ignores the auto-generated id field
Matcher matchesExpense(ExpenseFacade expected) => _ExpenseMatcher(expected);

/// Custom matcher for LodgingFacade that ignores the auto-generated id field
Matcher matchesLodging(LodgingFacade expected) => _LodgingMatcher(expected);

/// Custom matcher for SightFacade that ignores the auto-generated id field
Matcher matchesSight(SightFacade expected) => _SightMatcher(expected);

class _TransitMatcher extends Matcher {
  final TransitFacade expected;

  _TransitMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! TransitFacade) {
      matchState['error'] =
          'Expected TransitFacade but got ${item.runtimeType}';
      return false;
    }

    final actual = item;

    // Compare all fields except id
    if (actual.tripId != expected.tripId) {
      matchState['field'] = 'tripId';
      matchState['expected'] = expected.tripId;
      matchState['actual'] = actual.tripId;
      return false;
    }

    if (actual.transitOption != expected.transitOption) {
      matchState['field'] = 'transitOption';
      matchState['expected'] = expected.transitOption;
      matchState['actual'] = actual.transitOption;
      return false;
    }

    if (actual.departureDateTime != expected.departureDateTime) {
      matchState['field'] = 'departureDateTime';
      matchState['expected'] = expected.departureDateTime;
      matchState['actual'] = actual.departureDateTime;
      return false;
    }

    if (actual.arrivalDateTime != expected.arrivalDateTime) {
      matchState['field'] = 'arrivalDateTime';
      matchState['expected'] = expected.arrivalDateTime;
      matchState['actual'] = actual.arrivalDateTime;
      return false;
    }

    // Compare departure locations by their properties (ignoring id)
    if (actual.departureLocation != null &&
        expected.departureLocation != null) {
      if (actual.departureLocation!.latitude !=
              expected.departureLocation!.latitude ||
          actual.departureLocation!.longitude !=
              expected.departureLocation!.longitude ||
          actual.departureLocation!.context !=
              expected.departureLocation!.context) {
        matchState['field'] = 'departureLocation';
        matchState['expected'] = expected.departureLocation;
        matchState['actual'] = actual.departureLocation;
        return false;
      }
    } else if (actual.departureLocation != expected.departureLocation) {
      matchState['field'] = 'departureLocation';
      matchState['expected'] = expected.departureLocation;
      matchState['actual'] = actual.departureLocation;
      return false;
    }

    // Compare arrival locations by their properties (ignoring id)
    if (actual.arrivalLocation != null && expected.arrivalLocation != null) {
      if (actual.arrivalLocation!.latitude !=
              expected.arrivalLocation!.latitude ||
          actual.arrivalLocation!.longitude !=
              expected.arrivalLocation!.longitude ||
          actual.arrivalLocation!.context !=
              expected.arrivalLocation!.context) {
        matchState['field'] = 'arrivalLocation';
        matchState['expected'] = expected.arrivalLocation;
        matchState['actual'] = actual.arrivalLocation;
        return false;
      }
    } else if (actual.arrivalLocation != expected.arrivalLocation) {
      matchState['field'] = 'arrivalLocation';
      matchState['expected'] = expected.arrivalLocation;
      matchState['actual'] = actual.arrivalLocation;
      return false;
    }

    if (actual.operator != expected.operator) {
      matchState['field'] = 'operator';
      matchState['expected'] = expected.operator;
      matchState['actual'] = actual.operator;
      return false;
    }

    if (actual.confirmationId != expected.confirmationId) {
      matchState['field'] = 'confirmationId';
      matchState['expected'] = expected.confirmationId;
      matchState['actual'] = actual.confirmationId;
      return false;
    }

    if (actual.notes != expected.notes) {
      matchState['field'] = 'notes';
      matchState['expected'] = expected.notes;
      matchState['actual'] = actual.notes;
      return false;
    }

    // Compare expense using expense matcher
    final expenseMatcher = _ExpenseMatcher(expected.expense);
    if (!expenseMatcher.matches(actual.expense, matchState)) {
      matchState['field'] = 'expense.${matchState['field']}';
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('matches TransitFacade ').addDescriptionOf(expected);

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error']);
    }
    if (matchState.containsKey('field')) {
      return mismatchDescription
          .add('has different ${matchState['field']}: ')
          .add('expected ${matchState['expected']}, ')
          .add('but got ${matchState['actual']}');
    }
    return mismatchDescription;
  }
}

class _StandaloneExpenseMatcher extends Matcher {
  final StandaloneExpense _expectedStandalone;

  _StandaloneExpenseMatcher(StandaloneExpense standaloneExpense)
      : _expectedStandalone = standaloneExpense;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! StandaloneExpense) {
      matchState['error'] =
          'Expected StandaloneExpense but got ${item.runtimeType}';
      return false;
    }

    final actualStandaloneExpense = item;

    // Check wrapper properties first (title, category)
    if (actualStandaloneExpense.title != _expectedStandalone.title) {
      matchState['field'] = 'title';
      matchState['expected'] = _expectedStandalone.title;
      matchState['actual'] = actualStandaloneExpense.title;
      return false;
    }

    if (actualStandaloneExpense.category != _expectedStandalone.category) {
      matchState['field'] = 'category';
      matchState['expected'] = _expectedStandalone.category;
      matchState['actual'] = actualStandaloneExpense.category;
      return false;
    }

    // Compare expense using expense matcher
    final expenseMatcher = _ExpenseMatcher(_expectedStandalone.expense);
    if (!expenseMatcher.matches(actualStandaloneExpense.expense, matchState)) {
      matchState['field'] = 'expense.${matchState['field']}';
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) => description
      .add('matches StandaloneExpense ')
      .addDescriptionOf(_expectedStandalone);

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error']);
    }
    if (matchState.containsKey('field')) {
      return mismatchDescription
          .add('has different ${matchState['field']}: ')
          .add('expected ${matchState['expected']}, ')
          .add('but got ${matchState['actual']}');
    }
    return mismatchDescription;
  }
}

class _ExpenseMatcher extends Matcher {
  final ExpenseFacade expected;

  _ExpenseMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! ExpenseFacade) {
      matchState['error'] =
          'Expected ExpenseFacade but got ${item.runtimeType}';
      return false;
    }

    final actual = item;

    if (actual.currency != expected.currency) {
      matchState['field'] = 'currency';
      matchState['expected'] = expected.currency;
      matchState['actual'] = actual.currency;
      return false;
    }

    if (actual.description != expected.description) {
      matchState['field'] = 'description';
      matchState['expected'] = expected.description;
      matchState['actual'] = actual.description;
      return false;
    }

    if (actual.dateTime != expected.dateTime) {
      matchState['field'] = 'dateTime';
      matchState['expected'] = expected.dateTime;
      matchState['actual'] = actual.dateTime;
      return false;
    }

    // Compare paidBy map
    if (actual.paidBy.length != expected.paidBy.length) {
      matchState['field'] = 'paidBy.length';
      matchState['expected'] = expected.paidBy.length;
      matchState['actual'] = actual.paidBy.length;
      return false;
    }

    for (var key in expected.paidBy.keys) {
      if (!actual.paidBy.containsKey(key)) {
        matchState['field'] = 'paidBy[$key]';
        matchState['expected'] = 'key exists';
        matchState['actual'] = 'key missing';
        return false;
      }
      if (actual.paidBy[key] != expected.paidBy[key]) {
        matchState['field'] = 'paidBy[$key]';
        matchState['expected'] = expected.paidBy[key];
        matchState['actual'] = actual.paidBy[key];
        return false;
      }
    }

    // Compare splitBy list
    if (actual.splitBy.length != expected.splitBy.length) {
      matchState['field'] = 'splitBy.length';
      matchState['expected'] = expected.splitBy.length;
      matchState['actual'] = actual.splitBy.length;
      return false;
    }

    for (int i = 0; i < expected.splitBy.length; i++) {
      if (actual.splitBy[i] != expected.splitBy[i]) {
        matchState['field'] = 'splitBy[$i]';
        matchState['expected'] = expected.splitBy[i];
        matchState['actual'] = actual.splitBy[i];
        return false;
      }
    }

    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('matches ExpenseFacade ').addDescriptionOf(expected);

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error']);
    }
    if (matchState.containsKey('field')) {
      return mismatchDescription
          .add('has different ${matchState['field']}: ')
          .add('expected ${matchState['expected']}, ')
          .add('but got ${matchState['actual']}');
    }
    return mismatchDescription;
  }
}

class _LodgingMatcher extends Matcher {
  final LodgingFacade expected;

  _LodgingMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! LodgingFacade) {
      matchState['error'] =
          'Expected LodgingFacade but got ${item.runtimeType}';
      return false;
    }

    final actual = item;

    // Compare all fields except id
    if (actual.tripId != expected.tripId) {
      matchState['field'] = 'tripId';
      matchState['expected'] = expected.tripId;
      matchState['actual'] = actual.tripId;
      return false;
    }

    // Compare locations by their properties (ignoring id)
    if (actual.location != null && expected.location != null) {
      if (actual.location!.latitude != expected.location!.latitude ||
          actual.location!.longitude != expected.location!.longitude ||
          actual.location!.context != expected.location!.context) {
        matchState['field'] = 'location';
        matchState['expected'] = expected.location;
        matchState['actual'] = actual.location;
        return false;
      }
    } else if (actual.location != expected.location) {
      // One is null and the other is not
      matchState['field'] = 'location';
      matchState['expected'] = expected.location;
      matchState['actual'] = actual.location;
      return false;
    }

    if (actual.checkinDateTime != expected.checkinDateTime) {
      matchState['field'] = 'checkinDateTime';
      matchState['expected'] = expected.checkinDateTime;
      matchState['actual'] = actual.checkinDateTime;
      return false;
    }

    if (actual.checkoutDateTime != expected.checkoutDateTime) {
      matchState['field'] = 'checkoutDateTime';
      matchState['expected'] = expected.checkoutDateTime;
      matchState['actual'] = actual.checkoutDateTime;
      return false;
    }

    if (actual.confirmationId != expected.confirmationId) {
      matchState['field'] = 'confirmationId';
      matchState['expected'] = expected.confirmationId;
      matchState['actual'] = actual.confirmationId;
      return false;
    }

    if (actual.notes != expected.notes) {
      matchState['field'] = 'notes';
      matchState['expected'] = expected.notes;
      matchState['actual'] = actual.notes;
      return false;
    }

    // Compare expense using expense matcher
    final expenseMatcher = _ExpenseMatcher(expected.expense);
    if (!expenseMatcher.matches(actual.expense, matchState)) {
      matchState['field'] = 'expense.${matchState['field']}';
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('matches LodgingFacade ').addDescriptionOf(expected);

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error']);
    }
    if (matchState.containsKey('field')) {
      return mismatchDescription
          .add('has different ${matchState['field']}: ')
          .add('expected ${matchState['expected']}, ')
          .add('but got ${matchState['actual']}');
    }
    return mismatchDescription;
  }
}

class _SightMatcher extends Matcher {
  final SightFacade expected;

  _SightMatcher(this.expected);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! SightFacade) {
      matchState['error'] = 'Expected SightFacade but got ${item.runtimeType}';
      return false;
    }

    final actual = item;

    // Compare all fields except id
    if (actual.tripId != expected.tripId) {
      matchState['field'] = 'tripId';
      matchState['expected'] = expected.tripId;
      matchState['actual'] = actual.tripId;
      return false;
    }

    if (actual.name != expected.name) {
      matchState['field'] = 'name';
      matchState['expected'] = expected.name;
      matchState['actual'] = actual.name;
      return false;
    }

    if (actual.day != expected.day) {
      matchState['field'] = 'day';
      matchState['expected'] = expected.day;
      matchState['actual'] = actual.day;
      return false;
    }

    // Compare locations by their properties (ignoring id)
    if (actual.location != null && expected.location != null) {
      if (actual.location!.latitude != expected.location!.latitude ||
          actual.location!.longitude != expected.location!.longitude ||
          actual.location!.context != expected.location!.context) {
        matchState['field'] = 'location';
        matchState['expected'] = expected.location;
        matchState['actual'] = actual.location;
        return false;
      }
    } else if (actual.location != expected.location) {
      // One is null and the other is not
      matchState['field'] = 'location';
      matchState['expected'] = expected.location;
      matchState['actual'] = actual.location;
      return false;
    }

    if (actual.visitTime != expected.visitTime) {
      matchState['field'] = 'visitTime';
      matchState['expected'] = expected.visitTime;
      matchState['actual'] = actual.visitTime;
      return false;
    }

    if (actual.description != expected.description) {
      matchState['field'] = 'description';
      matchState['expected'] = expected.description;
      matchState['actual'] = actual.description;
      return false;
    }

    // Compare expense using expense matcher
    final expenseMatcher = _ExpenseMatcher(expected.expense);
    if (!expenseMatcher.matches(actual.expense, matchState)) {
      matchState['field'] = 'expense.${matchState['field']}';
      return false;
    }

    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('matches SightFacade ').addDescriptionOf(expected);

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState.containsKey('error')) {
      return mismatchDescription.add(matchState['error']);
    }
    if (matchState.containsKey('field')) {
      return mismatchDescription
          .add('has different ${matchState['field']}: ')
          .add('expected ${matchState['expected']}, ')
          .add('but got ${matchState['actual']}');
    }
    return mismatchDescription;
  }
}
