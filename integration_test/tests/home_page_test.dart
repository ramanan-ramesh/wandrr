import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/asset_manager/extension.dart';
import 'package:wandrr/data/app/models/app_data.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/trip_repository.dart';
import 'package:wandrr/presentation/app/widgets/button.dart';
import 'package:wandrr/presentation/app/widgets/date_range_pickers.dart';
import 'package:wandrr/presentation/trip/pages/home/app_bar/app_bar.dart';
import 'package:wandrr/presentation/trip/pages/home/home_page.dart';
import 'package:wandrr/presentation/trip/pages/home/trip_creator_dialog.dart';
import 'package:wandrr/presentation/trip/pages/home/trips_list_view.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor.dart';

import '../helpers/test_config.dart';
import '../helpers/test_helpers.dart';

/// Test: HomePage sets isBigLayout to true when screen width >= 1000, and AppBar resizes accordingly
Future<void> runHomePageLayoutTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated)
  await TestHelpers.pumpAndSettleApp(tester);

  // Verify HomePage is displayed
  expect(find.byType(HomePage), findsOneWidget);

  // Verify layout matches device size
  final appBarFinder = find.byType(HomeAppBar);
  expect(appBarFinder, findsOneWidget);

  final appBarContent = find.descendant(
    of: appBarFinder,
    matching: find.byType(FractionallySizedBox),
  );
  expect(appBarContent, findsOneWidget);

  final isLarge = TestHelpers.isLargeScreen(tester);
  if (isLarge) {
    final fracBox = tester.widget<FractionallySizedBox>(appBarContent);
    expect(fracBox.widthFactor, 0.5);
    print('Verified large layout on device: AppBar contents widthFactor = 0.5');
  } else {
    final fracBox = tester.widget<FractionallySizedBox>(appBarContent);
    expect(fracBox.widthFactor, 1.0);
    print('Verified small layout on device: AppBar contents widthFactor = 1.0');
  }
}

/// Test: Language selection updates locale and repository
Future<void> runHomePageLanguageSwitchTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated)
  await TestHelpers.pumpAndSettleApp(tester);

  final context = tester.element(find.byType(HomePage));
  final appDataRepository = RepositoryProvider.of<AppDataFacade>(context);
  expect(appDataRepository.activeLanguage, 'en',
      reason: 'Default language in AppDataRepository should be english');
  final defaultLocale = Localizations.localeOf(context);
  expect(defaultLocale.languageCode, 'en',
      reason: 'Default language applied in MaterialApp should be english');

  // Verify HomePage is displayed
  expect(find.byType(HomePage), findsOneWidget);

  // Verify language code is updated to hindi
  await _changeLanguageAndVerifyLocale('hi', tester);

  // Verify language code is updated to tamil
  await _changeLanguageAndVerifyLocale('ta', tester);

  // Verify language code is updated to english
  await _changeLanguageAndVerifyLocale('en', tester);
}

/// Test: Theme mode switcher updates theme mode and repository
Future<void> runHomePageThemeSwitchTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated)
  await TestHelpers.pumpAndSettleApp(tester);

  // Verify HomePage is displayed
  expect(find.byType(HomePage), findsOneWidget);

  final context = tester.element(find.byType(HomePage));
  final appDataRepository = RepositoryProvider.of<AppDataFacade>(context);
  expect(appDataRepository.activeThemeMode, ThemeMode.dark,
      reason: 'Default theme mode in AppDataRepository should be dark');
  final defaultThemeMode = Theme.of(context).brightness;
  expect(defaultThemeMode, Brightness.dark,
      reason: 'Default theme mode applied in MaterialApp should be dark');

  // Find and tap the toolbar menu
  await _openToolbar(tester);

  // Verify theme mode is updated to light
  await _switchAndVerifyThemeMode(tester, ThemeMode.light);

  // Verify theme mode is updated to dark
  await _switchAndVerifyThemeMode(tester, ThemeMode.dark);
}

/// Test: HomePage displays no trips initially in TripsListView
Future<void> runHomePageEmptyTripsTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated)
  await TestHelpers.pumpAndSettleApp(tester);

  // Verify HomePage is displayed
  expect(find.byType(HomePage), findsOneWidget);

  // Verify TripsListView is displayed
  expect(find.byType(TripListView), findsOneWidget);

  // Verify no trips are displayed (should show empty state)
  var localizations = TestHelpers.getAppLocalizations(tester, HomePage);
  expect(find.text(localizations.noTripsCreated), findsOneWidget);
  expect(find.byType(GridView), findsNothing);
}

/// Test: Creating a trip navigates to TripEditorPage
Future<void> runHomePageCreateTripFlowTest(
  WidgetTester tester,
  SharedPreferences sharedPreferences,
) async {
  // Launch the app (already authenticated)
  await TestHelpers.pumpAndSettleApp(tester);

  // Verify HomePage is displayed
  expect(find.byType(HomePage), findsOneWidget);

  // Find and tap the 'Plan a Trip' button
  final planTripButton = find.byIcon(Icons.add_location_alt_rounded);
  await TestHelpers.tapWidget(tester, planTripButton);

  // Verify dialog is displayed
  expect(find.byType(TripCreatorDialog), findsOneWidget);

  // Select a thumbnail (navigate to last thumbnail in PageView)
  var lastThumbnailImage = Assets.images.tripThumbnails.values.last;
  await _clickOnImageInThumbnailSelector(
      tester, Assets.images.tripThumbnails.values.length - 1);

  // Enter trip name
  final tripNameField = find.byKey(Key('TripCreatorDialog_TripNameField'));
  const tripName = 'Test Trip';
  await TestHelpers.enterText(tester, tripNameField, tripName);

  // Open date range picker
  final dateRangePicker = find.byType(PlatformDateRangePicker);
  await TestHelpers.tapWidget(tester, dateRangePicker);

  // Verify first possible selectable date
  final calendarPicker = tester.widget<CalendarDatePicker2WithActionButtons>(
      find.byType(CalendarDatePicker2WithActionButtons));
  final calendarPickerConfig = calendarPicker.config;
  final currentDateTime = DateTime.now();
  _matchDate(calendarPickerConfig.firstDate, currentDateTime,
      reason: 'First possible selectable date should be today');

  // Select range: Current day plus 15 days.
  await TestHelpers.selectDateRange(tester, false, currentDateTime, 15);

  // Enter budget
  var budget = Money(currency: 'EUR', amount: 50000);
  await TestHelpers.enterMoneyAmount(tester, budget);

  // Tap submit button
  await TestHelpers.tapWidget(tester, find.byType(PlatformSubmitterFAB),
      warnIfMissed: false);

  // Wait for navigation to TripEditorPage
  await TestHelpers.waitForWidget(tester, find.byType(TripEditorPage),
      timeout: const Duration(seconds: 5));
  var context = tester.element(find.byType(TripEditorPage));
  final currentTripMetadata =
      RepositoryProvider.of<TripRepositoryFacade>(context)
          .activeTrip!
          .tripMetadata;
  expect(currentTripMetadata.name, tripName);
  expect(currentTripMetadata.thumbnailTag, lastThumbnailImage.fileName);
  expect(currentTripMetadata.budget, equals(budget));
  _matchDate(currentTripMetadata.startDate!, currentDateTime,
      reason: 'Trip start date must be ${currentDateTime.dayDateMonthFormat}');
  final tripEndDate = currentDateTime.add(const Duration(days: 15));
  _matchDate(currentTripMetadata.endDate!, tripEndDate,
      reason: 'Trip end date must be ${tripEndDate.dayDateMonthFormat}');
  expect(currentTripMetadata.contributors, [TestConfig.testEmail]);
}

Future<void> _clickOnImageInThumbnailSelector(
    WidgetTester tester, int indexOfThumbnailImage) async {
  // Select a thumbnail (navigate to last thumbnail in PageView)
  var allThumbnails = Assets.images.tripThumbnails.values.toList();
  var targetThumbnailImage = allThumbnails[indexOfThumbnailImage];

  // Find the PageView and get its controller
  final pageViewFinder = find.byType(PageView);
  expect(pageViewFinder, findsOneWidget);
  final pageView = tester.widget<PageView>(pageViewFinder);
  final pageController = pageView.controller!;

  // Jump directly to the target page to ensure it's rendered
  pageController.jumpToPage(indexOfThumbnailImage);
  await tester.pumpAndSettle();

  // Find and tap the Image widget with matching AssetImage asset name
  final thumbnailImageFinder = find.byWidgetPredicate((widget) {
    if (widget is! Image || widget.image is! AssetImage) {
      return false;
    }
    var imageProvider = widget.image as AssetImage;
    return imageProvider.assetName == targetThumbnailImage.keyName;
  });
  expect(thumbnailImageFinder, findsOneWidget);
  await TestHelpers.tapWidget(tester, thumbnailImageFinder);
}

void _matchDate(DateTime actualDateTime, DateTime expectedDateTime,
    {String? reason}) {
  expect(
      actualDateTime,
      predicate<DateTime>((DateTime date) {
        return date.isOnSameDayAs(expectedDateTime);
      }, reason ?? 'Date should be ${expectedDateTime.dayDateMonthFormat}'));
}

Future _changeLanguageAndVerifyLocale(
    String locale, WidgetTester tester) async {
  // Find and tap the toolbar menu
  await _openToolbar(tester);

  // Find language option
  final languageMenu = find.byIcon(Icons.translate);
  await TestHelpers.tapWidget(tester, languageMenu);

  final languageOption = find.byKey(Key('ToolBar_LanguageSwitcher_' + locale));
  await TestHelpers.tapWidget(tester, languageOption);
  var context = tester.element(find.byType(HomePage));
  await _verifyCurrentLocale(context, locale);
}

Future<void> _verifyCurrentLocale(Element context, String locale) async {
  String? languageCode = Localizations.localeOf(context).languageCode;
  expect(languageCode, locale,
      reason: 'Language code applied on MaterialApp should be "$locale"');
  var sharedPreferences = await SharedPreferences.getInstance();
  languageCode = sharedPreferences.getString('language');
  expect(languageCode, locale,
      reason: 'Language code present in cache should be "$locale"');
  languageCode = RepositoryProvider.of<AppDataFacade>(context).activeLanguage;
  expect(languageCode, locale,
      reason: 'Language code in AppDataRepository should be "$locale"');
}

Future<void> _switchAndVerifyThemeMode(
    WidgetTester tester, ThemeMode themeMode) async {
  //Click on theme switcher
  final themeOption = find.byKey(Key('ToolBar_ThemeSwitcher'));
  await TestHelpers.tapWidget(tester, themeOption);

  // Verify theme mode is updated to light
  final context = tester.element(find.byType(HomePage));
  expect(Theme.of(context).brightness,
      themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
      reason: 'ThemeMode applied on MaterialApp should be ${themeMode.name}');
  expect(
      RepositoryProvider.of<AppDataFacade>(context).activeThemeMode, themeMode,
      reason: 'ThemeMode in AppDataRepository should be ${themeMode.name}');
  final sharedPreferences = await SharedPreferences.getInstance();
  final cachedThemeMode = sharedPreferences.getString('themeMode');
  expect(cachedThemeMode, themeMode.name,
      reason: 'ThemeMode value in cache should be ${themeMode.name}');
}

Future<void> _openToolbar(WidgetTester tester) async {
  final toolbarButton = find.byIcon(Icons.settings);
  await TestHelpers.tapWidget(tester, toolbarButton);
}
