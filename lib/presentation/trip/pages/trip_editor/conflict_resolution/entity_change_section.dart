import 'package:flutter/material.dart';
import 'package:wandrr/data/trip/models/services/entity_change.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/entity_change_message_provider.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';

/// A reusable expandable section for displaying a list of items with a header.
/// Used for both AffectedEntitiesEditor and ConflictResolutionSubpage.
class EntityChangeSection<T> extends StatefulWidget {
  /// Section icon
  final IconData icon;

  /// Section title (e.g., "Affected Stays (3)")
  final String title;

  /// Icon color
  final Color? iconColor;

  /// List of items to display
  final List<T> items;

  /// Builder function for each item
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Optional info message to display at the top of the expanded section
  final EntityChangeInfoMessage? infoMessage;

  /// Whether the section is initially expanded
  final bool initiallyExpanded;

  /// Callback when expansion state changes
  final ValueChanged<bool>? onExpansionChanged;

  const EntityChangeSection({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    required this.items,
    required this.itemBuilder,
    this.infoMessage,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<EntityChangeSection<T>> createState() => _EntityChangeSectionState<T>();
}

class _EntityChangeSectionState<T> extends State<EntityChangeSection<T>> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final effectiveIconColor = widget.iconColor ??
        (isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight);

    return EditorTheme.createSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorTheme.createSectionHeader(
            context,
            icon: widget.icon,
            title: widget.title,
            iconColor: effectiveIconColor,
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: _toggleExpansion,
            ),
            onTap: _toggleExpansion,
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            if (widget.infoMessage != null)
              _InfoBanner(message: widget.infoMessage!),
            const SizedBox(height: 12),
            ...widget.items.map((item) => widget.itemBuilder(context, item)),
          ],
        ],
      ),
    );
  }

  void _toggleExpansion() {
    setState(() => _isExpanded = !_isExpanded);
    widget.onExpansionChanged?.call(_isExpanded);
  }
}

/// Info banner widget for displaying section information
class _InfoBanner extends StatelessWidget {
  final EntityChangeInfoMessage message;

  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.info.withValues(alpha: 0.1)
            : AppColors.infoLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme
              ? AppColors.info.withValues(alpha: 0.3)
              : AppColors.infoLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isLightTheme ? AppColors.info : AppColors.infoLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isLightTheme ? AppColors.info : AppColors.infoLight,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.details,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLightTheme
                      ? Colors.grey.shade700
                      : Colors.grey.shade400,
                ),
          ),
        ],
      ),
    );
  }
}

/// A reusable card for displaying an individual entity change item.
/// Provides consistent styling for both affected entities and conflict items.
class EntityChangeItemCard extends StatelessWidget {
  /// Whether the item is marked for deletion
  final bool isDeleted;

  /// Whether the item was clamped (auto-adjusted)
  final bool isClamped;

  /// Leading icon
  final IconData icon;

  /// Icon color (when not deleted)
  final Color? iconColor;

  /// Item title
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Callback when delete/restore is toggled
  final VoidCallback onToggleDelete;

  /// Child widget to display when not deleted (e.g., datetime editors)
  final Widget? child;

  /// Optional conflict source information
  final ConflictSource? conflictSource;

  const EntityChangeItemCard({
    super.key,
    required this.isDeleted,
    this.isClamped = false,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onToggleDelete,
    this.child,
    this.conflictSource,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final effectiveIconColor = iconColor ??
        (isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight);

    return Opacity(
      opacity: isDeleted ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDeleted
              ? (isLightTheme
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.errorLight.withValues(alpha: 0.08))
              : isClamped
                  ? (isLightTheme
                      ? AppColors.success.withValues(alpha: 0.06)
                      : AppColors.successLight.withValues(alpha: 0.06))
                  : (isLightTheme
                      ? Colors.grey.shade100
                      : Colors.grey.shade800.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDeleted
                ? (isLightTheme ? AppColors.error : AppColors.errorLight)
                : isClamped
                    ? (isLightTheme
                        ? AppColors.success
                        : AppColors.successLight)
                    : (isLightTheme
                        ? Colors.grey.shade300
                        : Colors.grey.shade700),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon, title, status badge, and delete/restore button
            Row(
              children: [
                Icon(icon, size: 18, color: effectiveIconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  isDeleted ? TextDecoration.lineThrough : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Status indicator
                if (isClamped && !isDeleted)
                  _StatusChip(
                    label: 'Adjusted',
                    color: isLightTheme
                        ? AppColors.success
                        : AppColors.successLight,
                  ),
                if (isDeleted)
                  _StatusChip(
                    label: 'Delete',
                    color:
                        isLightTheme ? AppColors.error : AppColors.errorLight,
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    isDeleted ? Icons.undo : Icons.delete_outline,
                    size: 20,
                  ),
                  tooltip: isDeleted ? 'Restore' : 'Delete',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onToggleDelete,
                ),
              ],
            ),
            // Conflict source - compact single line
            if (conflictSource != null && !isDeleted) ...[
              const SizedBox(height: 6),
              _ConflictSourceChip(source: conflictSource!),
            ],
            // Content when not deleted
            if (!isDeleted && child != null) ...[
              const SizedBox(height: 8),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple status chip
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Compact chip showing the source of a conflict with times
class _ConflictSourceChip extends StatelessWidget {
  final ConflictSource source;

  const _ConflictSourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final color = isLightTheme ? Colors.grey.shade700 : Colors.grey.shade400;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Conflicts with ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11,
                ),
          ),
          TextSpan(
            text: source.shortMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLightTheme ? AppColors.error : AppColors.errorLight,
                  fontSize: 11,
                ),
          ),
          TextSpan(
            text: ' (${source.compactTimeRange})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
