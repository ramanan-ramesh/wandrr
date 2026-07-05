import 'package:flutter/material.dart';
import 'package:wandrr/l10n/app_localizations.dart';

class PrintActionPanel extends StatelessWidget {
  final bool isLargeScreen;
  final bool transitsReady;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const PrintActionPanel({
    required this.isLargeScreen,
    required this.transitsReady,
    required this.isGenerating,
    required this.onGenerate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: isLargeScreen
              ? BorderSide(color: cs.outlineVariant)
              : BorderSide.none,
          left: isLargeScreen
              ? BorderSide(color: cs.outlineVariant)
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: isLargeScreen ? 420 : double.infinity),
          child: FilledButton.icon(
            onPressed: (!transitsReady || isGenerating) ? null : onGenerate,
            icon: isGenerating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.onPrimary,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 22),
            label: Text(
              isGenerating ? l10n.generatingPdf : l10n.generatePdf,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isLargeScreen ? 16 : 14,
                horizontal: 20,
              ),
              minimumSize: Size.fromHeight(isLargeScreen ? 56 : 48),
            ),
          ),
        ),
      ),
    );
  }
}
