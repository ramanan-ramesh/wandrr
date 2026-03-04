import 'package:flutter/material.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

class UnifiedTripDialog extends StatelessWidget {
  final String title;
  final Widget? icon;
  final Widget content;
  final List<Widget> actions;
  final Widget? headerBackground;
  final double? maxWidth;

  const UnifiedTripDialog({
    super.key,
    required this.title,
    this.icon,
    required this.content,
    required this.actions,
    this.headerBackground,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isBig = context.isBigLayout;
    final effectiveMaxWidth = maxWidth ?? (isBig ? 600.0 : 500.0);

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: effectiveMaxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        margin: const EdgeInsets.all(24),
        child: Material(
          elevation: 24,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: content,
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        if (headerBackground != null)
          Positioned.fill(child: headerBackground!)
        else
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Row(
            children: [
              if (icon != null) ...[
                Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme:
                        const IconThemeData(color: Colors.black, size: 32),
                  ),
                  child: icon!,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.black54),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: action,
          );
        }).toList(),
      ),
    );
  }
}
