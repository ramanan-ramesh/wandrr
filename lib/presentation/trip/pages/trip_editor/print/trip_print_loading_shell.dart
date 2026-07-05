import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/trip_metadata.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_action_panel.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_form_content.dart';

/// Lightweight route shell while the requested trip is being activated.
class TripPrintLoadingShell extends StatefulWidget {
  final TripMetadataFacade? metadata;

  const TripPrintLoadingShell({super.key, this.metadata});

  @override
  State<TripPrintLoadingShell> createState() => _TripPrintLoadingShellState();
}

class _TripPrintLoadingShellState extends State<TripPrintLoadingShell> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.metadata?.name ?? '');
  }

  @override
  void didUpdateWidget(covariant TripPrintLoadingShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTitle = widget.metadata?.name ?? '';
    if (oldWidget.metadata?.name != nextTitle) {
      _titleController.text = nextTitle;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final pageBackground =
        isLight ? AppColors.lightBackground : AppColors.darkSurfaceVariant;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        title: Text(widget.metadata?.name ?? context.localizations.printTrip),
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: theme.appBarTheme.backgroundColor ?? cs.surface,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: ColoredBox(
        color: pageBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 800;
              return Column(
                children: [
                  Expanded(
                    child: PrintFormContent(
                      isLargeScreen: isLargeScreen,
                      transitsReady: false,
                      controlsEnabled: false,
                      titleController: _titleController,
                      includeChecklist: true,
                      includeExpenses: true,
                      includeSights: true,
                      includeNotes: true,
                      checklistEnabled: false,
                      expensesEnabled: false,
                      sightsEnabled: false,
                      notesEnabled: false,
                      includeInterCityTransit: true,
                      includeIntraCityTransit: true,
                      onIncludeChecklistChanged: (_) {},
                      onIncludeExpensesChanged: (_) {},
                      onIncludeSightsChanged: (_) {},
                      onIncludeNotesChanged: (_) {},
                      onIncludeInterCityTransitChanged: (_) {},
                      onIncludeIntraCityTransitChanged: (_) {},
                      transitContent: const SizedBox.shrink(),
                      transitLoadingContent:
                          PrintTransitLoadingList(isLargeScreen: isLargeScreen),
                    ),
                  ),
                  PrintActionPanel(
                    isLargeScreen: isLargeScreen,
                    transitsReady: false,
                    isGenerating: false,
                    onGenerate: () {},
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
