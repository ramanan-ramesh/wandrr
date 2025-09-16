import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// No description provided for @plan_itinerary.
  ///
  /// In en, this message translates to:
  /// **'Plan your Itinerary with ease and elegance'**
  String get plan_itinerary;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'LogOut'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'UserName'**
  String get userName;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @alternativeLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with'**
  String get alternativeLogin;

  /// No description provided for @userNameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This username is already registered. You can login with it instead'**
  String get userNameAlreadyExists;

  /// No description provided for @noSuchUserExists.
  ///
  /// In en, this message translates to:
  /// **'No such username exists. You can register with it instead'**
  String get noSuchUserExists;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @viewRecentTrips.
  ///
  /// In en, this message translates to:
  /// **'View upcoming trips'**
  String get viewRecentTrips;

  /// No description provided for @noTripsCreated.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips? Have fun creating a new one!'**
  String get noTripsCreated;

  /// No description provided for @planTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip!'**
  String get planTrip;

  /// No description provided for @dateRangePickerStart.
  ///
  /// In en, this message translates to:
  /// **'Start Date:'**
  String get dateRangePickerStart;

  /// No description provided for @dateRangePickerEnd.
  ///
  /// In en, this message translates to:
  /// **'End Date:'**
  String get dateRangePickerEnd;

  /// No description provided for @budgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget Amount'**
  String get budgetAmount;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @tripName.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get tripName;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @transit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get transit;

  /// No description provided for @lodging.
  ///
  /// In en, this message translates to:
  /// **'Lodging'**
  String get lodging;

  /// No description provided for @itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @budgeting.
  ///
  /// In en, this message translates to:
  /// **'Budgeting'**
  String get budgeting;

  /// No description provided for @add_expense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get add_expense;

  /// No description provided for @edit_budget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get edit_budget;

  /// No description provided for @debt_summary.
  ///
  /// In en, this message translates to:
  /// **'Debt Summary'**
  String get debt_summary;

  /// No description provided for @view_breakdown.
  ///
  /// In en, this message translates to:
  /// **'View breakdown'**
  String get view_breakdown;

  /// No description provided for @add_tripmate.
  ///
  /// In en, this message translates to:
  /// **'Add Tripmate'**
  String get add_tripmate;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @oldToNew.
  ///
  /// In en, this message translates to:
  /// **'Date: Oldest to Newest'**
  String get oldToNew;

  /// No description provided for @newToOld.
  ///
  /// In en, this message translates to:
  /// **'Date: Newest to Oldest'**
  String get newToOld;

  /// No description provided for @lowToHighCost.
  ///
  /// In en, this message translates to:
  /// **'Cost: Low to High'**
  String get lowToHighCost;

  /// No description provided for @highToLowCost.
  ///
  /// In en, this message translates to:
  /// **'Cost: High to Low'**
  String get highToLowCost;

  /// No description provided for @flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get flight;

  /// No description provided for @flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get flights;

  /// No description provided for @carRental.
  ///
  /// In en, this message translates to:
  /// **'Car Rental'**
  String get carRental;

  /// No description provided for @publicTransit.
  ///
  /// In en, this message translates to:
  /// **'Public Transit'**
  String get publicTransit;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @drinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get drinks;

  /// No description provided for @sightseeing.
  ///
  /// In en, this message translates to:
  /// **'Sightseeing'**
  String get sightseeing;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @fuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuel;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @noExpensesCreated.
  ///
  /// In en, this message translates to:
  /// **'You haven’t added any expense yet.'**
  String get noExpensesCreated;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid By'**
  String get paidBy;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @view_expenses.
  ///
  /// In en, this message translates to:
  /// **'View Expenses'**
  String get view_expenses;

  /// No description provided for @wrong_password_entered.
  ///
  /// In en, this message translates to:
  /// **'Wrong password entered'**
  String get wrong_password_entered;

  /// No description provided for @password_short.
  ///
  /// In en, this message translates to:
  /// **'Password is too short'**
  String get password_short;

  /// No description provided for @noTransitsCreated.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any transit yet.'**
  String get noTransitsCreated;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @transitCarrier.
  ///
  /// In en, this message translates to:
  /// **'Transit Carrier'**
  String get transitCarrier;

  /// No description provided for @depart.
  ///
  /// In en, this message translates to:
  /// **'Depart'**
  String get depart;

  /// No description provided for @arrive.
  ///
  /// In en, this message translates to:
  /// **'Arrive'**
  String get arrive;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @bus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// No description provided for @cruise.
  ///
  /// In en, this message translates to:
  /// **'Cruise'**
  String get cruise;

  /// No description provided for @ferry.
  ///
  /// In en, this message translates to:
  /// **'Ferry'**
  String get ferry;

  /// No description provided for @train.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get train;

  /// No description provided for @personalVehicle.
  ///
  /// In en, this message translates to:
  /// **'Personal Vehicle'**
  String get personalVehicle;

  /// No description provided for @walk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get walk;

  /// No description provided for @splitBy.
  ///
  /// In en, this message translates to:
  /// **'Split By'**
  String get splitBy;

  /// No description provided for @flightNumber.
  ///
  /// In en, this message translates to:
  /// **'Flight Number'**
  String get flightNumber;

  /// No description provided for @flightCarrierName.
  ///
  /// In en, this message translates to:
  /// **'Airline Name'**
  String get flightCarrierName;

  /// No description provided for @airport.
  ///
  /// In en, this message translates to:
  /// **'Airport'**
  String get airport;

  /// No description provided for @noLodgingCreated.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any lodging yet.'**
  String get noLodgingCreated;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-Out'**
  String get checkOut;

  /// No description provided for @newPlanData.
  ///
  /// In en, this message translates to:
  /// **'New Plan Data'**
  String get newPlanData;

  /// No description provided for @dayByDay.
  ///
  /// In en, this message translates to:
  /// **'Day by day'**
  String get dayByDay;

  /// No description provided for @addATitle.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get addATitle;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get deleteTrip;

  /// No description provided for @deleteTripConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this trip?'**
  String get deleteTripConfirmation;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @stayAddress.
  ///
  /// In en, this message translates to:
  /// **'Hostel or Lodging Address'**
  String get stayAddress;

  /// No description provided for @carrierName.
  ///
  /// In en, this message translates to:
  /// **'Carrier Name'**
  String get carrierName;

  /// No description provided for @dateTimeSelection.
  ///
  /// In en, this message translates to:
  /// **'Select a date and time'**
  String get dateTimeSelection;

  /// No description provided for @searchForCurrency.
  ///
  /// In en, this message translates to:
  /// **'Search a currency'**
  String get searchForCurrency;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @departAt.
  ///
  /// In en, this message translates to:
  /// **'Depart At'**
  String get departAt;

  /// No description provided for @arriveAt.
  ///
  /// In en, this message translates to:
  /// **'Arrive At'**
  String get arriveAt;

  /// No description provided for @allDayTravel.
  ///
  /// In en, this message translates to:
  /// **'All Day Travel'**
  String get allDayTravel;

  /// No description provided for @allDayStay.
  ///
  /// In en, this message translates to:
  /// **'All Day Stay'**
  String get allDayStay;

  /// No description provided for @noExpensesAssociatedWithDate.
  ///
  /// In en, this message translates to:
  /// **'No expenses associated with a date'**
  String get noExpensesAssociatedWithDate;

  /// No description provided for @noExpensesToSplit.
  ///
  /// In en, this message translates to:
  /// **'There are no expenses to split'**
  String get noExpensesToSplit;

  /// No description provided for @needsToPay.
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get needsToPay;

  /// No description provided for @splitExpensesWithNewTripMateMessage.
  ///
  /// In en, this message translates to:
  /// **'All current expenses will be split with the new trip mate. Do you wish to proceed?'**
  String get splitExpensesWithNewTripMateMessage;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @departureArrivalDateTimeCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Departure and Arrival date time cannot be empty'**
  String get departureArrivalDateTimeCannotBeEmpty;

  /// No description provided for @departureArrivalLocationCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Departure and Arrival location cannot be empty'**
  String get departureArrivalLocationCannotBeEmpty;

  /// No description provided for @departureAndArrivalLocationsCannotBeSame.
  ///
  /// In en, this message translates to:
  /// **'Departure and Arrival locations cannot be the same'**
  String get departureAndArrivalLocationsCannotBeSame;

  /// No description provided for @arrivalDepartureDateTimesError.
  ///
  /// In en, this message translates to:
  /// **'Arrival cannot be before departure. Also, both must be within the trip start/end dates'**
  String get arrivalDepartureDateTimesError;

  /// No description provided for @lodgingAddressCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Lodging address cannot be empty'**
  String get lodgingAddressCannotBeEmpty;

  /// No description provided for @checkInAndCheckoutDatesCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Check-In and Check-Out dates cannot be empty'**
  String get checkInAndCheckoutDatesCannotBeEmpty;

  /// No description provided for @expenseTitleMustBeAtleast3Characters.
  ///
  /// In en, this message translates to:
  /// **'Expense title must be at least 3 characters'**
  String get expenseTitleMustBeAtleast3Characters;

  /// No description provided for @titleCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get titleCannotBeEmpty;

  /// No description provided for @noteCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Note cannot be empty'**
  String get noteCannotBeEmpty;

  /// No description provided for @checkListTitle.
  ///
  /// In en, this message translates to:
  /// **'CheckList title'**
  String get checkListTitle;

  /// No description provided for @checkListTitleMustBeAtleast3Characters.
  ///
  /// In en, this message translates to:
  /// **'Checklist title must be at least 3 characters'**
  String get checkListTitleMustBeAtleast3Characters;

  /// No description provided for @checkListItemCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Checklist item cannot be empty'**
  String get checkListItemCannotBeEmpty;

  /// No description provided for @noNotesOrCheckListsOrPlaces.
  ///
  /// In en, this message translates to:
  /// **'No notes, checklists or places added yet'**
  String get noNotesOrCheckListsOrPlaces;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingYourTrips.
  ///
  /// In en, this message translates to:
  /// **'Loading your trips'**
  String get loadingYourTrips;

  /// No description provided for @loadedYourTrips.
  ///
  /// In en, this message translates to:
  /// **'Loaded your trips'**
  String get loadedYourTrips;

  /// No description provided for @loadingTripData.
  ///
  /// In en, this message translates to:
  /// **'Loading trip data'**
  String get loadingTripData;

  /// No description provided for @launchingTrip.
  ///
  /// In en, this message translates to:
  /// **'Launching trip'**
  String get launchingTrip;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseTripThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Choose a thumbnail'**
  String get chooseTripThumbnail;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
