import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/location/location_timezone_date_time.dart';
import 'package:wandrr/data/trip/models/print_options.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';

/// Generates a print-ready black-and-white timeline PDF from trip data.
///
/// The per-day itinerary is rendered as a continuous timeline. All events that
/// have a concrete time (check-in, check-out, transit departure/arrival, sight
/// visit) are merged and sorted chronologically. Sights without a visit time
/// are collected into a standalone "SIGHTS / PLACES" section.
class TripPrintService {
  // ── Monochrome palette ────────────────────────────────────────────────
  static const _black = PdfColors.black;
  static const _dark = PdfColor.fromInt(0xFF333333);
  static const _mid = PdfColor.fromInt(0xFF666666);
  static const _muted = PdfColor.fromInt(0xFF999999);
  static const _rule = PdfColor.fromInt(0xFFBBBBBB);
  static const _lightBg = PdfColor.fromInt(0xFFF5F5F5);
  static final RegExp _keycapEmojiRegex = RegExp('([0-9#*])\uFE0F?\u20E3');

  // ── Timeline constants ────────────────────────────────────────────────
  static const double _dotSize = 6.0;
  static const double _lineWidth = 1.0;
  static const double _timelineColWidth = 16.0;

  Future<Uint8List> generatePdf(
      TripDataFacade tripData, PrintOptions options) async {
    final logoImage = await _loadLogoImage();
    final pdfTheme = await _buildPdfTheme();

    final pdfDocument = pdf.Document(title: options.title, author: 'Wandrr');
    final meta = tripData.tripMetadata;
    final startDate = meta.startDate!;
    final endDate = meta.endDate!;
    final totalDays =
        startDate.calculateDaysInBetween(endDate, includeBoundaryDay: true);

    // ── Resolve selected transits ─────────────────────────────────────
    final allTransits = tripData.transitCollection.items.toList()
      ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
          .compareTo(b.departureDateTime ?? DateTime(0)));
    final filteredTransits = _filterTransits(allTransits, options);

    final allExpenses = <ExpenseBearingTripEntity>[
      ...tripData.expenseCollection.items,
    ];

    // ── Collect untimed sights across all days ────────────────────────
    final untimedSights = <SightFacade>[];

    final itineraryDays = List.generate(totalDays, (i) {
      final day = startDate.add(Duration(days: i));
      return _DayData(
          day, tripData.itineraryCollection.getItineraryForDay(day));
    });

    // Pre-collect untimed sights
    if (options.includeSights) {
      for (final dd in itineraryDays) {
        for (final sight in dd.itinerary.planData.sights) {
          if (sight.visitTime == null) {
            untimedSights.add(sight);
          }
        }
      }
    }

    final dateRange =
        '${startDate.monthDateYearFormat} - ${endDate.monthDateYearFormat}';

    pdfDocument.addPage(pdf.MultiPage(
      theme: pdfTheme,
      pageFormat: PdfPageFormat.a4,
      margin: const pdf.EdgeInsets.all(40),
      header: (_) => _pageHeader(logoImage),
      footer: (ctx) => pdf.Container(
          alignment: pdf.Alignment.centerRight,
          margin: const pdf.EdgeInsets.only(top: 12),
          child: pdf.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pdf.TextStyle(fontSize: 8, color: _muted))),
      build: (_) => [
        _coverSection(options.title, dateRange, totalDays, meta.contributors,
            meta.budget),
        pdf.SizedBox(height: 24),
        // Per-day timeline
        ...itineraryDays
            .expand((d) => _itineraryDay(d, options, filteredTransits)),
        // Untimed sights
        if (untimedSights.isNotEmpty) ...[
          _sectionHeader('SIGHTS / PLACES'),
          pdf.SizedBox(height: 6),
          ...untimedSights.map(_untimedSightRow),
          pdf.SizedBox(height: 20),
        ],
        if (options.includeExpenses && allExpenses.isNotEmpty) ...[
          _sectionHeader('EXPENSES'),
          pdf.SizedBox(height: 6),
          _expenseTable(allExpenses, meta.budget.currency),
          pdf.SizedBox(height: 20),
        ],
      ],
    ));

    return pdfDocument.save();
  }

  Future<pdf.ThemeData?> _buildPdfTheme() async {
    try {
      final baseFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      return pdf.ThemeData.withFont(base: baseFont, bold: boldFont);
    } on Exception {
      // Graceful fallback to package default fonts if Google font load fails.
      return null;
    }
  }

  String _sanitizePdfText(String value) {
    return value
        .replaceAllMapped(_keycapEmojiRegex, (match) => match.group(1)!)
        .replaceAll('\uFE0F', '');
  }

  // ── Page header ───────────────────────────────────────────────────────

  Future<pdf.MemoryImage?> _loadLogoImage() async {
    try {
      final source = await rootBundle.load(Assets.images.logo.path);
      final codec = await ui.instantiateImageCodec(source.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final bytes =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (bytes == null) {
        return null;
      }
      return pdf.MemoryImage(bytes.buffer.asUint8List());
    } on Exception {
      return null;
    }
  }

  pdf.Widget _pageHeader(pdf.ImageProvider? logo) => pdf.Container(
      margin: const pdf.EdgeInsets.only(bottom: 12),
      padding: const pdf.EdgeInsets.only(bottom: 8),
      decoration: const pdf.BoxDecoration(
          border: pdf.Border(bottom: pdf.BorderSide(color: _rule, width: 0.5))),
      child: pdf.Row(children: [
        if (logo != null)
          pdf.Image(logo, width: 18, height: 18)
        else
          pdf.Container(
              width: 18,
              height: 18,
              alignment: pdf.Alignment.center,
              decoration: pdf.BoxDecoration(
                border: pdf.Border.all(color: _rule, width: 0.5),
                borderRadius: pdf.BorderRadius.circular(3),
              ),
              child: pdf.Text('W',
                  style: pdf.TextStyle(
                      fontSize: 9,
                      color: _dark,
                      fontWeight: pdf.FontWeight.bold))),
        pdf.SizedBox(width: 6),
        pdf.Text('Wandrr',
            style: pdf.TextStyle(
                fontSize: 11, color: _dark, fontWeight: pdf.FontWeight.bold)),
      ]));

  // ── Cover ─────────────────────────────────────────────────────────────

  pdf.Widget _coverSection(String title, String dateRange, int totalDays,
      List<String> contributors, Money budget) {
    final sanitizedTitle = _sanitizePdfText(title);
    return pdf.Container(
      padding: const pdf.EdgeInsets.all(20),
      decoration: pdf.BoxDecoration(
          border: pdf.Border.all(color: _dark, width: 1.5),
          borderRadius: pdf.BorderRadius.circular(4)),
      child: pdf.Column(
          crossAxisAlignment: pdf.CrossAxisAlignment.start,
          children: [
            pdf.Text(sanitizedTitle,
                style: pdf.TextStyle(
                    fontSize: 26,
                    fontWeight: pdf.FontWeight.bold,
                    color: _black)),
            pdf.SizedBox(height: 6),
            pdf.Text(dateRange,
                style: const pdf.TextStyle(fontSize: 12, color: _mid)),
            pdf.SizedBox(height: 12),
            pdf.Divider(color: _rule, thickness: 0.5),
            pdf.SizedBox(height: 8),
            pdf.Row(children: [
              _infoPill('$totalDays days'),
              pdf.SizedBox(width: 10),
              if (contributors.isNotEmpty) ...[
                _infoPill(
                    '${contributors.length} traveller${contributors.length > 1 ? "s" : ""}'),
                pdf.SizedBox(width: 10),
              ],
              _infoPill('Budget: $budget'),
            ]),
          ]),
    );
  }

  pdf.Widget _infoPill(String text) => pdf.Container(
      padding: const pdf.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pdf.BoxDecoration(
          color: _lightBg,
          border: pdf.Border.all(color: _rule, width: 0.5),
          borderRadius: pdf.BorderRadius.circular(3)),
      child: pdf.Text(text,
          style: pdf.TextStyle(
              fontSize: 9, color: _dark, fontWeight: pdf.FontWeight.bold)));

  // ── Section header ────────────────────────────────────────────────────

  pdf.Widget _sectionHeader(String title) => pdf.Container(
      padding: const pdf.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pdf.BoxDecoration(
          color: _black, borderRadius: pdf.BorderRadius.circular(2)),
      child: pdf.Text(title,
          style: pdf.TextStyle(
              fontSize: 10,
              fontWeight: pdf.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.5)));

  // ── Timeline node (diamond marker + thin connecting line) ────────────

  pdf.Widget _timelineRow({required pdf.Widget content, bool isLast = false}) {
    return pdf.Row(crossAxisAlignment: pdf.CrossAxisAlignment.start, children: [
      pdf.SizedBox(
          width: _timelineColWidth,
          child: pdf.Column(children: [
            // Small filled diamond marker
            pdf.Container(
                width: _dotSize,
                height: _dotSize,
                margin: const pdf.EdgeInsets.only(top: 4),
                decoration: const pdf.BoxDecoration(
                    color: _dark,
                    borderRadius:
                        pdf.BorderRadius.all(pdf.Radius.circular(1.5)))),
            // Thin connecting line
            if (!isLast)
              pdf.Container(width: _lineWidth, height: 14, color: _rule),
          ])),
      pdf.SizedBox(width: 6),
      pdf.Expanded(child: content),
    ]);
  }

  // ── Untimed sight row (for standalone section) ────────────────────────

  pdf.Widget _untimedSightRow(SightFacade sight) {
    final sightName = _sanitizePdfText(sight.name);
    final sightDescription =
        sight.description == null ? null : _sanitizePdfText(sight.description!);
    return pdf.Container(
        margin: const pdf.EdgeInsets.only(bottom: 4),
        padding: const pdf.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: const pdf.BoxDecoration(
            border: pdf.Border(left: pdf.BorderSide(color: _dark, width: 3))),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text(sightName,
                  style: pdf.TextStyle(
                      fontSize: 10,
                      fontWeight: pdf.FontWeight.bold,
                      color: _black)),
              pdf.SizedBox(height: 1),
              pdf.Text(sight.day.dayDateMonthFormat,
                  style: const pdf.TextStyle(fontSize: 8, color: _mid)),
              if (sightDescription != null && sightDescription.isNotEmpty)
                pdf.Padding(
                    padding: const pdf.EdgeInsets.only(top: 1),
                    child: pdf.Text(sightDescription,
                        style:
                            const pdf.TextStyle(fontSize: 8, color: _muted))),
            ]));
  }

  // ── Expense table ─────────────────────────────────────────────────────

  pdf.Widget _expenseTable(
      List<ExpenseBearingTripEntity> expenses, String currency) {
    expenses.sort((a, b) => (a.expense.dateTime ?? DateTime(9999))
        .compareTo(b.expense.dateTime ?? DateTime(9999)));

    final total = expenses.fold<double>(
        0, (sum, e) => sum + e.expense.totalExpense.amount);

    return pdf.Table(
        border: pdf.TableBorder.all(color: _rule, width: 0.5),
        columnWidths: const {
          0: pdf.FlexColumnWidth(2.5),
          1: pdf.FlexColumnWidth(1.5),
          2: pdf.FlexColumnWidth(1.2),
          3: pdf.FlexColumnWidth(1.5),
        },
        children: [
          _tableHeaderRow(['Title', 'Category', 'Amount', 'Date']),
          ...expenses.map((e) => _tableDataRow([
                e.title.isNotEmpty ? e.title : (e.expense.description ?? '-'),
                e.category.name,
                e.expense.totalExpense.toString(),
                e.expense.dateTime?.dayDateMonthFormat ?? '-',
              ])),
          // Total row
          pdf.TableRow(
              decoration: const pdf.BoxDecoration(color: _lightBg),
              children: [
                pdf.Padding(
                    padding: const pdf.EdgeInsets.all(6),
                    child: pdf.Text('TOTAL',
                        style: pdf.TextStyle(
                            fontSize: 9,
                            fontWeight: pdf.FontWeight.bold,
                            color: _black))),
                pdf.SizedBox(),
                pdf.Padding(
                    padding: const pdf.EdgeInsets.all(6),
                    child: pdf.Text('${total.toStringAsFixed(2)} $currency',
                        style: pdf.TextStyle(
                            fontSize: 9,
                            fontWeight: pdf.FontWeight.bold,
                            color: _black))),
                pdf.SizedBox(),
              ]),
        ]);
  }

  pdf.TableRow _tableHeaderRow(List<String> cells) => pdf.TableRow(
      decoration: const pdf.BoxDecoration(color: _black),
      children: cells
          .map((c) => pdf.Padding(
              padding: const pdf.EdgeInsets.all(6),
              child: pdf.Text(c,
                  style: pdf.TextStyle(
                      fontSize: 9,
                      fontWeight: pdf.FontWeight.bold,
                      color: PdfColors.white))))
          .toList());

  pdf.TableRow _tableDataRow(List<String> cells) => pdf.TableRow(
      children: cells
          .map((c) => pdf.Padding(
              padding: const pdf.EdgeInsets.all(6),
              child: pdf.Text(_sanitizePdfText(c),
                  style: const pdf.TextStyle(fontSize: 9, color: _dark))))
          .toList());

  // ── Itinerary day (unified chronological timeline) ────────────────────

  List<pdf.Widget> _itineraryDay(
      _DayData dd, PrintOptions options, List<TransitFacade> transits) {
    final plan = dd.itinerary.planData;
    final day = dd.day;

    // Build a list of timed events for this day
    final events = <_TimelineEvent>[];

    // Check-out
    final checkOut = dd.itinerary.checkOutLodging;
    if (checkOut?.checkoutDateTime != null &&
        LocationTimezoneDateTime.isOnSameDay(
          storedDateTime: checkOut!.checkoutDateTime!,
          day: day,
          location: checkOut.location,
        )) {
      events.add(_TimelineEvent(
        time: checkOut.checkoutDateTime!,
        widget: _eventRow(
          label: 'CHECK-OUT',
          title: checkOut.location?.toString() ?? 'Accommodation',
          time: LocationTimezoneDateTime.formatHourMinuteAmPm(
            storedDateTime: checkOut.checkoutDateTime!,
            location: checkOut.location,
          ),
        ),
      ));
    }

    // Transit departures / arrivals on this day
    // Group merged journeys: show one combined event per merged journey
    final mergedIds = options.mergedJourneyIds;
    final handledJourneys = <String>{};

    for (final t in transits) {
      final jId = t.journeyId;
      if (jId != null && jId.isNotEmpty && mergedIds.contains(jId)) {
        // Merged journey — add a single event per journey per day
        if (handledJourneys.contains(jId)) {
          continue;
        }
        // Collect all legs of this journey in the filtered list
        final legs = transits.where((l) => l.journeyId == jId).toList()
          ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
              .compareTo(b.departureDateTime ?? DateTime(0)));
        final first = legs.first;
        final last = legs.last;
        // Show departure on departure day
        if (first.departureDateTime != null &&
            LocationTimezoneDateTime.isOnSameDay(
              storedDateTime: first.departureDateTime!,
              day: day,
              location: first.departureLocation,
            )) {
          events.add(_TimelineEvent(
            time: first.departureDateTime!,
            widget: _mergedJourneyEventRow(first, last),
          ));
        }
        // Show arrival on arrival day (if different from departure day)
        if (last.arrivalDateTime != null &&
            LocationTimezoneDateTime.isOnSameDay(
              storedDateTime: last.arrivalDateTime!,
              day: day,
              location: last.arrivalLocation,
            ) &&
            !(first.departureDateTime != null &&
                LocationTimezoneDateTime.isOnSameDay(
                  storedDateTime: first.departureDateTime!,
                  day: day,
                  location: first.departureLocation,
                ))) {
          events.add(_TimelineEvent(
            time: last.arrivalDateTime!,
            widget: _transitArrivalRow(last),
          ));
        }
        handledJourneys.add(jId);
      } else {
        // Standalone or non-merged journey leg — single combined event
        final hasDep = t.departureDateTime != null &&
            LocationTimezoneDateTime.isOnSameDay(
              storedDateTime: t.departureDateTime!,
              day: day,
              location: t.departureLocation,
            );
        final hasArr = t.arrivalDateTime != null &&
            LocationTimezoneDateTime.isOnSameDay(
              storedDateTime: t.arrivalDateTime!,
              day: day,
              location: t.arrivalLocation,
            );

        if (hasDep) {
          // Show combined departure → arrival on departure day
          events.add(_TimelineEvent(
            time: t.departureDateTime!,
            widget: _transitCombinedRow(t),
          ));
        } else if (hasArr) {
          // Arrival on a different day from departure — show arrival only
          events.add(_TimelineEvent(
            time: t.arrivalDateTime!,
            widget: _transitArrivalRow(t),
          ));
        }
      }
    }

    // Timed sights
    if (options.includeSights) {
      for (final sight in plan.sights) {
        if (sight.visitTime != null) {
          events.add(_TimelineEvent(
            time: sight.visitTime!,
            widget: _sightEventRow(sight),
          ));
        }
      }
    }

    // Check-in
    final checkIn = dd.itinerary.checkInLodging;
    if (checkIn?.checkinDateTime != null &&
        LocationTimezoneDateTime.isOnSameDay(
          storedDateTime: checkIn!.checkinDateTime!,
          day: day,
          location: checkIn.location,
        )) {
      events.add(_TimelineEvent(
        time: checkIn.checkinDateTime!,
        widget: _eventRow(
          label: 'CHECK-IN',
          title: checkIn.location?.toString() ?? 'Accommodation',
          time: LocationTimezoneDateTime.formatHourMinuteAmPm(
            storedDateTime: checkIn.checkinDateTime!,
            location: checkIn.location,
          ),
        ),
      ));
    }

    // Sort chronologically
    events.sort((a, b) => a.time.compareTo(b.time));

    // Collect non-timeline content (notes, checklists)
    final hasNotes = options.includeNotes && plan.notes.isNotEmpty;
    final hasChecklists =
        options.includeChecklist && plan.checkLists.isNotEmpty;

    final hasAnyContent = events.isNotEmpty || hasNotes || hasChecklists;
    if (!hasAnyContent) {
      return [];
    }

    // Merge timeline events + non-timeline items
    final allEntries = <pdf.Widget>[
      ...events.map((e) => e.widget),
      if (hasNotes) _notesEntry(plan.notes),
      if (hasChecklists) ...plan.checkLists.map(_checklistEntry),
    ];

    return [
      pdf.SizedBox(height: 14),
      // Day header
      pdf.Container(
          padding: const pdf.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: pdf.BoxDecoration(
              border: pdf.Border.all(color: _dark, width: 1),
              borderRadius: pdf.BorderRadius.circular(2)),
          child: pdf.Text(day.dayDateMonthFormat.toUpperCase(),
              style: pdf.TextStyle(
                  fontSize: 10,
                  fontWeight: pdf.FontWeight.bold,
                  color: _black,
                  letterSpacing: 1))),
      pdf.SizedBox(height: 6),
      for (var i = 0; i < allEntries.length; i++)
        _timelineRow(
            content: allEntries[i], isLast: i == allEntries.length - 1),
    ];
  }

  // ── Timeline event renderers ──────────────────────────────────────────

  pdf.Widget _eventRow({
    required String label,
    required String title,
    required String time,
  }) {
    final safeLabel = _sanitizePdfText(label);
    final safeTitle = _sanitizePdfText(title);
    final safeTime = _sanitizePdfText(time);
    return pdf.Padding(
        padding: const pdf.EdgeInsets.only(bottom: 4),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text(safeLabel,
                  style: pdf.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pdf.SizedBox(height: 1),
              pdf.Text(safeTitle,
                  style: pdf.TextStyle(
                      fontSize: 10,
                      fontWeight: pdf.FontWeight.bold,
                      color: _black)),
              pdf.Text(safeTime,
                  style: const pdf.TextStyle(fontSize: 8, color: _mid)),
            ]));
  }

  /// Renders a transit as a single combined timeline event showing
  /// departure → arrival with both locations and times.
  pdf.Widget _transitCombinedRow(TransitFacade t) {
    final type = _transitLabel(t.transitOption).toUpperCase();
    final from = _sanitizePdfText(t.departureLocation?.toString() ?? '?');
    final to = _sanitizePdfText(t.arrivalLocation?.toString() ?? '?');
    final depTime = t.departureDateTime == null
        ? '-'
        : LocationTimezoneDateTime.formatHourMinuteAmPm(
            storedDateTime: t.departureDateTime!,
            location: t.departureLocation,
          );
    final arrTime = t.arrivalDateTime == null
        ? '-'
        : LocationTimezoneDateTime.formatHourMinuteAmPm(
            storedDateTime: t.arrivalDateTime!,
            location: t.arrivalLocation,
          );

    return pdf.Padding(
        padding: const pdf.EdgeInsets.only(bottom: 4),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text(type,
                  style: pdf.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pdf.SizedBox(height: 1),
              pdf.Text('$from  ->  $to',
                  style: pdf.TextStyle(
                      fontSize: 10,
                      fontWeight: pdf.FontWeight.bold,
                      color: _black)),
              pdf.Text('$depTime  -  $arrTime',
                  style: const pdf.TextStyle(fontSize: 8, color: _mid)),
              if (t.operator != null && t.operator!.isNotEmpty)
                pdf.Text(_sanitizePdfText(t.operator!),
                    style: const pdf.TextStyle(fontSize: 8, color: _muted)),
              if (_platformAndSeatsWidget(t) != null)
                pdf.Padding(
                  padding: const pdf.EdgeInsets.only(top: 1),
                  child: _platformAndSeatsWidget(t)!,
                ),
            ]));
  }

  /// Renders a transit arrival-only event (when arrival is on a different
  /// day from departure).
  pdf.Widget _transitArrivalRow(TransitFacade t) {
    final type = _transitLabel(t.transitOption).toUpperCase();
    final location = _sanitizePdfText(t.arrivalLocation?.toString() ?? '?');
    final time = t.arrivalDateTime == null
        ? '-'
        : LocationTimezoneDateTime.formatHourMinuteAmPm(
            storedDateTime: t.arrivalDateTime!,
            location: t.arrivalLocation,
          );

    return pdf.Padding(
        padding: const pdf.EdgeInsets.only(bottom: 4),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text('$type - ARRIVE',
                  style: pdf.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pdf.SizedBox(height: 1),
              pdf.Text(location,
                  style: pdf.TextStyle(
                      fontSize: 10,
                      fontWeight: pdf.FontWeight.bold,
                      color: _black)),
              pdf.Text(time,
                  style: const pdf.TextStyle(fontSize: 8, color: _mid)),
              if (_platformAndSeatsWidget(t, isArrival: true) != null)
                pdf.Padding(
                  padding: const pdf.EdgeInsets.only(top: 1),
                  child: _platformAndSeatsWidget(t, isArrival: true)!,
                ),
            ]));
  }

  /// Renders a merged multi-leg journey as a single timeline entry showing
  /// the first leg's departure and the last leg's arrival.
  pdf.Widget _mergedJourneyEventRow(
      TransitFacade firstLeg, TransitFacade lastLeg) {
    final type = _transitLabel(firstLeg.transitOption).toUpperCase();
    final from =
        _sanitizePdfText(firstLeg.departureLocation?.toString() ?? '?');
    final to = _sanitizePdfText(lastLeg.arrivalLocation?.toString() ?? '?');
    final depTime = firstLeg.departureDateTime == null
        ? '-'
        : LocationTimezoneDateTime.formatHourMinuteAmPm(
            storedDateTime: firstLeg.departureDateTime!,
            location: firstLeg.departureLocation,
          );
    final arrTime = lastLeg.arrivalDateTime == null
        ? '-'
        : LocationTimezoneDateTime.formatHourMinuteAmPm(
            storedDateTime: lastLeg.arrivalDateTime!,
            location: lastLeg.arrivalLocation,
          );

    return pdf.Padding(
        padding: const pdf.EdgeInsets.only(bottom: 4),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text('$type - JOURNEY',
                  style: pdf.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pdf.SizedBox(height: 1),
              pdf.Text('$from  ->  $to',
                  style: pdf.TextStyle(
                      fontSize: 10,
                      fontWeight: pdf.FontWeight.bold,
                      color: _black)),
              pdf.Text('Depart $depTime  |  Arrive $arrTime',
                  style: const pdf.TextStyle(fontSize: 8, color: _mid)),
              if (_platformAndSeatsWidget(firstLeg) != null)
                pdf.Padding(
                  padding: const pdf.EdgeInsets.only(top: 1),
                  child: _platformAndSeatsWidget(firstLeg)!,
                ),
            ]));
  }

  pdf.Widget _sightEventRow(SightFacade sight) {
    final sightName = _sanitizePdfText(sight.name);
    final sightDescription =
        sight.description == null ? null : _sanitizePdfText(sight.description!);
    return pdf.Padding(
        padding: const pdf.EdgeInsets.only(bottom: 4),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text(sightName,
                  style: pdf.TextStyle(
                      fontSize: 10,
                      fontWeight: pdf.FontWeight.bold,
                      color: _black)),
              if (sight.visitTime != null)
                pdf.Text(
                    LocationTimezoneDateTime.formatHourMinuteAmPm(
                      storedDateTime: sight.visitTime!,
                      location: sight.location,
                    ),
                    style: const pdf.TextStyle(fontSize: 8, color: _mid)),
              if (sightDescription != null && sightDescription.isNotEmpty)
                pdf.Padding(
                    padding: const pdf.EdgeInsets.only(top: 1),
                    child: pdf.Text(sightDescription,
                        style:
                            const pdf.TextStyle(fontSize: 8, color: _muted))),
            ]));
  }

  pdf.Widget _notesEntry(List<String> notes) {
    final sanitizedNotes = notes.map(_sanitizePdfText).toList();
    return pdf.Padding(
        padding: const pdf.EdgeInsets.only(bottom: 4),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text('NOTES',
                  style: pdf.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pdf.SizedBox(height: 2),
              ...sanitizedNotes.map((note) => pdf.Padding(
                  padding: const pdf.EdgeInsets.only(bottom: 1),
                  child: pdf.Text('-  $note',
                      style: const pdf.TextStyle(fontSize: 9, color: _dark)))),
            ]));
  }

  pdf.Widget _checklistEntry(CheckListFacade cl) {
    final checklistTitle =
        _sanitizePdfText(cl.title ?? 'Checklist').toUpperCase();
    return pdf.Padding(
        padding: const pdf.EdgeInsets.only(bottom: 4),
        child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text(checklistTitle,
                  style: pdf.TextStyle(
                      fontSize: 8,
                      fontWeight: pdf.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pdf.SizedBox(height: 2),
              ...cl.items.map<pdf.Widget>((item) => pdf.Padding(
                  padding: const pdf.EdgeInsets.only(bottom: 1),
                  child: pdf.Row(children: [
                    pdf.Container(
                        width: 9,
                        height: 9,
                        decoration: pdf.BoxDecoration(
                            border: pdf.Border.all(color: _dark, width: 1),
                            borderRadius: pdf.BorderRadius.circular(1.5),
                            color: item.isChecked ? _dark : PdfColors.white)),
                    pdf.SizedBox(width: 5),
                    pdf.Expanded(
                        child: pdf.Text(_sanitizePdfText(item.item),
                            style: pdf.TextStyle(
                                fontSize: 9,
                                decoration: item.isChecked
                                    ? pdf.TextDecoration.lineThrough
                                    : null,
                                color: item.isChecked ? _muted : _dark))),
                  ]))),
            ]));
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  pdf.Widget? _platformAndSeatsWidget(TransitFacade t, {bool? isArrival}) {
    final isFlight = t.transitOption == TransitOption.flight;
    final platformLabel = isFlight ? 'Terminal' : 'Platform';

    final parts = <String>[];

    if (isArrival == null || !isArrival) {
      if (t.departurePlatform != null && t.departurePlatform!.isNotEmpty) {
        parts.add(
            '${isArrival == null ? "Dep " : ""}$platformLabel: ${t.departurePlatform}');
      }
    }

    if (isArrival == null || isArrival) {
      if (t.arrivalPlatform != null && t.arrivalPlatform!.isNotEmpty) {
        parts.add(
            '${isArrival == null ? "Arr " : ""}$platformLabel: ${t.arrivalPlatform}');
      }
    }

    if (t.seatNumbers != null && t.seatNumbers!.isNotEmpty) {
      final seatStrings = t.seatNumbers!.entries
          .where((e) => e.value.isNotEmpty)
          .map((e) => '${e.key} (${e.value})')
          .join(', ');
      if (seatStrings.isNotEmpty) {
        parts.add('Seat${seatStrings.length > 1 ? 's' : ''}: $seatStrings');
      }
    }

    if (parts.isEmpty) {
      return null;
    }

    return pdf.Text(_sanitizePdfText(parts.join('  |  ')),
        style: const pdf.TextStyle(fontSize: 8, color: _dark));
  }

  List<TransitFacade> _filterTransits(
      List<TransitFacade> transits, PrintOptions options) {
    // First apply inter/intra city filter
    var filtered = transits.where((t) {
      final isInter = _isInterCity(t);
      if (isInter && !options.includeInterCityTransit) {
        return false;
      }
      if (!isInter && !options.includeIntraCityTransit) {
        return false;
      }
      return true;
    }).toList();

    // Then apply individual selection
    if (options.selectedTransitIds != null) {
      filtered = filtered
          .where(
              (t) => t.id != null && options.selectedTransitIds!.contains(t.id))
          .toList();
    }

    return filtered;
  }

  bool _isInterCity(TransitFacade t) {
    final dep = t.departureLocation?.context.city;
    final arr = t.arrivalLocation?.context.city;
    if (dep == null || arr == null) {
      return true;
    }
    return dep.toLowerCase() != arr.toLowerCase();
  }

  String _transitLabel(TransitOption option) {
    const labels = {
      TransitOption.flight: 'Flight',
      TransitOption.train: 'Train',
      TransitOption.bus: 'Bus',
      TransitOption.ferry: 'Ferry',
      TransitOption.cruise: 'Cruise',
      TransitOption.taxi: 'Taxi',
      TransitOption.walk: 'Walk',
      TransitOption.rentedVehicle: 'Car Rental',
      TransitOption.vehicle: 'Vehicle',
      TransitOption.publicTransport: 'Public Transit',
    };
    return labels[option] ?? option.name;
  }
}

/// A timed event in the per-day timeline.
class _TimelineEvent {
  final DateTime time;
  final pdf.Widget widget;

  const _TimelineEvent({required this.time, required this.widget});
}

/// Internal holder for itinerary day + date pair.
class _DayData {
  final DateTime day;
  final ItineraryFacade itinerary;

  const _DayData(this.day, this.itinerary);
}
