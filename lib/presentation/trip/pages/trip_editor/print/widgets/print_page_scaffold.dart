import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/print/widgets/print_action_panel.dart';

typedef PrintFormBuilder = Widget Function(
  BuildContext context, {
  required bool isLargeScreen,
});

class PrintPageScaffold extends StatelessWidget {
  final String appBarTitle;
  final bool showBackButton;
  final PrintFormBuilder formBuilder;
  final bool actionTransitsReady;
  final bool actionIsGenerating;
  final VoidCallback onGenerate;

  const PrintPageScaffold({
    required this.appBarTitle,
    required this.formBuilder,
    required this.actionTransitsReady,
    required this.actionIsGenerating,
    required this.onGenerate,
    this.showBackButton = false,
    super.key,
  });

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
        leading: showBackButton
            ? BackButton(onPressed: () => Navigator.of(context).pop())
            : null,
        title: Text(appBarTitle),
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
                    child: formBuilder(
                      context,
                      isLargeScreen: isLargeScreen,
                    ),
                  ),
                  PrintActionPanel(
                    isLargeScreen: isLargeScreen,
                    transitsReady: actionTransitsReady,
                    isGenerating: actionIsGenerating,
                    onGenerate: onGenerate,
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
