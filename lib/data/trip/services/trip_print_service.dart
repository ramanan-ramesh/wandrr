import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wandrr/asset_manager/assets.gen.dart';
import 'package:wandrr/data/trip/models/budgeting/expense.dart';
import 'package:wandrr/data/trip/models/budgeting/money.dart';
import 'package:wandrr/data/trip/models/datetime_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/check_list.dart';
import 'package:wandrr/data/trip/models/itinerary/itinerary.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
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

  // ── Timeline constants ────────────────────────────────────────────────
  static const double _dotSize = 6.0;
  static const double _lineWidth = 1.0;
  static const double _timelineColWidth = 16.0;

  Future<Uint8List> generatePdf(
      TripDataFacade tripData, PrintOptions options) async {
    final logoBytes =
        (await rootBundle.load(Assets.images.logo.path)).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdf = pw.Document(title: options.title, author: 'Wandrr');
    final meta = tripData.tripMetadata;
    final startDate = meta.startDate!;
    final endDate = meta.endDate!;
    final totalDays =
        startDate.calculateDaysInBetween(endDate, includeExtraDay: true);

    // ── Resolve selected transits ─────────────────────────────────────
    final allTransits = tripData.transitCollection.collectionItems.toList()
      ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
          .compareTo(b.departureDateTime ?? DateTime(0)));
    final filteredTransits = _filterTransits(allTransits, options);

    final allExpenses = <ExpenseBearingTripEntity>[
      ...tripData.expenseCollection.collectionItems,
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
        '${startDate.monthDateYearFormat} \u2013 ${endDate.monthDateYearFormat}';

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (_) => _pageHeader(logoImage),
      footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted))),
      build: (_) => [
        _coverSection(options.title, dateRange, totalDays, meta.contributors,
            meta.budget),
        pw.SizedBox(height: 24),
        // Per-day timeline
        ...itineraryDays
            .expand((d) => _itineraryDay(d, options, filteredTransits)),
        // Untimed sights
        if (untimedSights.isNotEmpty) ...[
          _sectionHeader('SIGHTS / PLACES'),
          pw.SizedBox(height: 6),
          ...untimedSights.map(_untimedSightRow),
          pw.SizedBox(height: 20),
        ],
        if (options.includeExpenses && allExpenses.isNotEmpty) ...[
          _sectionHeader('EXPENSES'),
          pw.SizedBox(height: 6),
          _expenseTable(allExpenses, meta.budget.currency),
          pw.SizedBox(height: 20),
        ],
      ],
    ));

    return pdf.save();
  }

  // ── Page header ───────────────────────────────────────────────────────

  pw.Widget _pageHeader(pw.ImageProvider logo) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5))),
      child: pw.Row(children: [
        pw.Image(logo, width: 18, height: 18),
        pw.SizedBox(width: 6),
        pw.Text('Wandrr',
            style: pw.TextStyle(
                fontSize: 11, color: _dark, fontWeight: pw.FontWeight.bold)),
      ]));

  // ── Cover ─────────────────────────────────────────────────────────────

  pw.Widget _coverSection(String title, String dateRange, int totalDays,
      List<String> contributors, Money budget) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _dark, width: 1.5),
          borderRadius: pw.BorderRadius.circular(4)),
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 26, fontWeight: pw.FontWeight.bold, color: _black)),
        pw.SizedBox(height: 6),
        pw.Text(dateRange,
            style: const pw.TextStyle(fontSize: 12, color: _mid)),
        pw.SizedBox(height: 12),
        pw.Divider(color: _rule, thickness: 0.5),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _infoPill('$totalDays days'),
          pw.SizedBox(width: 10),
          if (contributors.isNotEmpty) ...[
            _infoPill(
                '${contributors.length} traveller${contributors.length > 1 ? "s" : ""}'),
            pw.SizedBox(width: 10),
          ],
          _infoPill('Budget: $budget'),
        ]),
      ]),
    );
  }

  pw.Widget _infoPill(String text) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
          color: _lightBg,
          border: pw.Border.all(color: _rule, width: 0.5),
          borderRadius: pw.BorderRadius.circular(3)),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9, color: _dark, fontWeight: pw.FontWeight.bold)));

  // ── Section header ────────────────────────────────────────────────────

  pw.Widget _sectionHeader(String title) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(
          color: _black, borderRadius: pw.BorderRadius.circular(2)),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.5)));

  // ── Timeline node (diamond marker + thin connecting line) ────────────

  pw.Widget _timelineRow({required pw.Widget content, bool isLast = false}) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(
          width: _timelineColWidth,
          child: pw.Column(children: [
            // Small filled diamond marker
            pw.Container(
                width: _dotSize,
                height: _dotSize,
                margin: const pw.EdgeInsets.only(top: 4),
                decoration: const pw.BoxDecoration(
                    color: _dark,
                    borderRadius:
                        pw.BorderRadius.all(pw.Radius.circular(1.5)))),
            // Thin connecting line
            if (!isLast)
              pw.Container(width: _lineWidth, height: 14, color: _rule),
          ])),
      pw.SizedBox(width: 6),
      pw.Expanded(child: content),
    ]);
  }

  // ── Untimed sight row (for standalone section) ────────────────────────

  pw.Widget _untimedSightRow(SightFacade sight) {
    return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: const pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: _dark, width: 3))),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(sight.name,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black)),
              pw.SizedBox(height: 1),
              pw.Text(sight.day.dayDateMonthFormat,
                  style: const pw.TextStyle(fontSize: 8, color: _mid)),
              if (sight.description != null && sight.description!.isNotEmpty)
                pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(sight.description!,
                        style: const pw.TextStyle(fontSize: 8, color: _muted))),
            ]));
  }

  // ── Expense table ─────────────────────────────────────────────────────

  pw.Widget _expenseTable(
      List<ExpenseBearingTripEntity> expenses, String currency) {
    expenses.sort((a, b) => (a.expense.dateTime ?? DateTime(9999))
        .compareTo(b.expense.dateTime ?? DateTime(9999)));

    final total = expenses.fold<double>(
        0, (sum, e) => sum + e.expense.totalExpense.amount);

    return pw.Table(
        border: pw.TableBorder.all(color: _rule, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.5),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(1.2),
          3: pw.FlexColumnWidth(1.5),
        },
        children: [
          _tableHeaderRow(['Title', 'Category', 'Amount', 'Date']),
          ...expenses.map((e) => _tableDataRow([
                e.title.isNotEmpty
                    ? e.title
                    : (e.expense.description ?? '\u2013'),
                e.category.name,
                e.expense.totalExpense.toString(),
                e.expense.dateTime?.dayDateMonthFormat ?? '\u2013',
              ])),
          // Total row
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: _lightBg),
              children: [
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('TOTAL',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _black))),
                pw.SizedBox(),
                pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${total.toStringAsFixed(2)} $currency',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: _black))),
                pw.SizedBox(),
              ]),
        ]);
  }

  pw.TableRow _tableHeaderRow(List<String> cells) => pw.TableRow(
      decoration: const pw.BoxDecoration(color: _black),
      children: cells
          .map((c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(c,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white))))
          .toList());

  pw.TableRow _tableDataRow(List<String> cells) => pw.TableRow(
      children: cells
          .map((c) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(c,
                  style: const pw.TextStyle(fontSize: 9, color: _dark))))
          .toList());

  // ── Itinerary day (unified chronological timeline) ────────────────────

  List<pw.Widget> _itineraryDay(
      _DayData dd, PrintOptions options, List<TransitFacade> transits) {
    final plan = dd.itinerary.planData;
    final day = dd.day;

    // Build a list of timed events for this day
    final events = <_TimelineEvent>[];

    // Check-out
    final checkOut = dd.itinerary.checkOutLodging;
    if (checkOut?.checkoutDateTime != null &&
        checkOut!.checkoutDateTime!.isOnSameDayAs(day)) {
      events.add(_TimelineEvent(
        time: checkOut.checkoutDateTime!,
        widget: _eventRow(
          label: 'CHECK-OUT',
          title: checkOut.location?.toString() ?? 'Accommodation',
          time: checkOut.checkoutDateTime!.hourMinuteAmPmFormat,
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
        if (handledJourneys.contains(jId)) continue;
        // Collect all legs of this journey in the filtered list
        final legs = transits.where((l) => l.journeyId == jId).toList()
          ..sort((a, b) => (a.departureDateTime ?? DateTime(0))
              .compareTo(b.departureDateTime ?? DateTime(0)));
        final first = legs.first;
        final last = legs.last;
        // Show departure on departure day
        if (first.departureDateTime != null &&
            first.departureDateTime!.isOnSameDayAs(day)) {
          events.add(_TimelineEvent(
            time: first.departureDateTime!,
            widget: _mergedJourneyEventRow(first, last),
          ));
        }
        // Show arrival on arrival day (if different from departure day)
        if (last.arrivalDateTime != null &&
            last.arrivalDateTime!.isOnSameDayAs(day) &&
            !(first.departureDateTime != null &&
                first.departureDateTime!.isOnSameDayAs(day))) {
          events.add(_TimelineEvent(
            time: last.arrivalDateTime!,
            widget: _transitArrivalRow(last),
          ));
        }
        handledJourneys.add(jId);
      } else {
        // Standalone or non-merged journey leg — single combined event
        final hasDep = t.departureDateTime != null &&
            t.departureDateTime!.isOnSameDayAs(day);
        final hasArr =
            t.arrivalDateTime != null && t.arrivalDateTime!.isOnSameDayAs(day);

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
        checkIn!.checkinDateTime!.isOnSameDayAs(day)) {
      events.add(_TimelineEvent(
        time: checkIn.checkinDateTime!,
        widget: _eventRow(
          label: 'CHECK-IN',
          title: checkIn.location?.toString() ?? 'Accommodation',
          time: checkIn.checkinDateTime!.hourMinuteAmPmFormat,
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
    if (!hasAnyContent) return [];

    // Merge timeline events + non-timeline items
    final allEntries = <pw.Widget>[
      ...events.map((e) => e.widget),
      if (hasNotes) _notesEntry(plan.notes),
      if (hasChecklists) ...plan.checkLists.map(_checklistEntry),
    ];

    return [
      pw.SizedBox(height: 14),
      // Day header
      pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _dark, width: 1),
              borderRadius: pw.BorderRadius.circular(2)),
          child: pw.Text(day.dayDateMonthFormat.toUpperCase(),
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _black,
                  letterSpacing: 1))),
      pw.SizedBox(height: 6),
      for (var i = 0; i < allEntries.length; i++)
        _timelineRow(
            content: allEntries[i], isLast: i == allEntries.length - 1),
    ];
  }

  // ── Timeline event renderers ──────────────────────────────────────────

  pw.Widget _eventRow({
    required String label,
    required String title,
    required String time,
  }) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pw.SizedBox(height: 1),
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black)),
              pw.Text(time,
                  style: const pw.TextStyle(fontSize: 8, color: _mid)),
            ]));
  }

  /// Renders a transit as a single combined timeline event showing
  /// departure → arrival with both locations and times.
  pw.Widget _transitCombinedRow(TransitFacade t) {
    final type = _transitLabel(t.transitOption).toUpperCase();
    final from = t.departureLocation?.toString() ?? '?';
    final to = t.arrivalLocation?.toString() ?? '?';
    final depTime = t.departureDateTime?.hourMinuteAmPmFormat ?? '\u2013';
    final arrTime = t.arrivalDateTime?.hourMinuteAmPmFormat ?? '\u2013';

    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(type,
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pw.SizedBox(height: 1),
              pw.Text('$from  \u2192  $to',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black)),
              pw.Text('$depTime  \u2013  $arrTime',
                  style: const pw.TextStyle(fontSize: 8, color: _mid)),
              if (t.operator != null && t.operator!.isNotEmpty)
                pw.Text(t.operator!,
                    style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ]));
  }

  /// Renders a transit arrival-only event (when arrival is on a different
  /// day from departure).
  pw.Widget _transitArrivalRow(TransitFacade t) {
    final type = _transitLabel(t.transitOption).toUpperCase();
    final location = t.arrivalLocation?.toString() ?? '?';
    final time = t.arrivalDateTime?.hourMinuteAmPmFormat ?? '\u2013';

    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$type \u2013 ARRIVE',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pw.SizedBox(height: 1),
              pw.Text(location,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black)),
              pw.Text(time,
                  style: const pw.TextStyle(fontSize: 8, color: _mid)),
            ]));
  }

  /// Renders a merged multi-leg journey as a single timeline entry showing
  /// the first leg's departure and the last leg's arrival.
  pw.Widget _mergedJourneyEventRow(
      TransitFacade firstLeg, TransitFacade lastLeg) {
    final type = _transitLabel(firstLeg.transitOption).toUpperCase();
    final from = firstLeg.departureLocation?.toString() ?? '?';
    final to = lastLeg.arrivalLocation?.toString() ?? '?';
    final depTime =
        firstLeg.departureDateTime?.hourMinuteAmPmFormat ?? '\u2013';
    final arrTime = lastLeg.arrivalDateTime?.hourMinuteAmPmFormat ?? '\u2013';

    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$type \u2013 JOURNEY',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pw.SizedBox(height: 1),
              pw.Text('$from  \u2192  $to',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black)),
              pw.Text('Depart $depTime  \u2022  Arrive $arrTime',
                  style: const pw.TextStyle(fontSize: 8, color: _mid)),
            ]));
  }

  pw.Widget _sightEventRow(SightFacade sight) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(sight.name,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black)),
              if (sight.visitTime != null)
                pw.Text(sight.visitTime!.hourMinuteAmPmFormat,
                    style: const pw.TextStyle(fontSize: 8, color: _mid)),
              if (sight.description != null && sight.description!.isNotEmpty)
                pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(sight.description!,
                        style: const pw.TextStyle(fontSize: 8, color: _muted))),
            ]));
  }

  pw.Widget _notesEntry(List<String> notes) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('NOTES',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pw.SizedBox(height: 2),
              ...notes.map((note) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 1),
                  child: pw.Text('\u2022  $note',
                      style: const pw.TextStyle(fontSize: 9, color: _dark)))),
            ]));
  }

  pw.Widget _checklistEntry(CheckListFacade cl) {
    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text((cl.title ?? 'Checklist').toString().toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _mid,
                      letterSpacing: 0.8)),
              pw.SizedBox(height: 2),
              ...cl.items.map<pw.Widget>((item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 1),
                  child: pw.Row(children: [
                    pw.Container(
                        width: 9,
                        height: 9,
                        decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _dark, width: 1),
                            borderRadius: pw.BorderRadius.circular(1.5),
                            color: item.isChecked ? _dark : PdfColors.white)),
                    pw.SizedBox(width: 5),
                    pw.Expanded(
                        child: pw.Text(item.item,
                            style: pw.TextStyle(
                                fontSize: 9,
                                decoration: item.isChecked
                                    ? pw.TextDecoration.lineThrough
                                    : null,
                                color: item.isChecked ? _muted : _dark))),
                  ]))),
            ]));
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  List<TransitFacade> _filterTransits(
      List<TransitFacade> transits, PrintOptions options) {
    // First apply inter/intra city filter
    var filtered = transits.where((t) {
      final isInter = _isInterCity(t);
      if (isInter && !options.includeInterCityTransit) return false;
      if (!isInter && !options.includeIntraCityTransit) return false;
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
    if (dep == null || arr == null) return true;
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
  final pw.Widget widget;

  const _TimelineEvent({required this.time, required this.widget});
}

/// Internal holder for itinerary day + date pair.
class _DayData {
  final DateTime day;
  final ItineraryFacade itinerary;

  const _DayData(this.day, this.itinerary);
}
