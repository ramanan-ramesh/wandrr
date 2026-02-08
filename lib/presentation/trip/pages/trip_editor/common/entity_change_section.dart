import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/common/entity_change_message_provider.dart';
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

  /// Leading icon
  final IconData icon;

  /// Icon color (when not deleted)
  final Color? iconColor;

  /// Item title
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Original time description (displayed as a chip)
  final String? originalTimeDescription;

  /// Action message explaining what user should do (e.g., "Update check-in/check-out dates")
  final String? actionMessage;

  /// Callback when delete/restore is toggled
  final VoidCallback onToggleDelete;

  /// Child widget to display when not deleted (e.g., datetime editors)
  final Widget? child;

  /// Custom message to show when deleted
  final String? deletedMessage;

  const EntityChangeItemCard({
    super.key,
    required this.isDeleted,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.originalTimeDescription,
    this.actionMessage,
    required this.onToggleDelete,
    this.child,
    this.deletedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final effectiveIconColor = iconColor ??
        (isLightTheme ? AppColors.brandPrimary : AppColors.brandPrimaryLight);

    return Opacity(
      opacity: isDeleted ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDeleted
              ? (isLightTheme
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.errorLight.withValues(alpha: 0.1))
              : (isLightTheme
                  ? Colors.grey.shade100
                  : Colors.grey.shade800.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDeleted
                ? (isLightTheme ? AppColors.error : AppColors.errorLight)
                : (isLightTheme ? Colors.grey.shade300 : Colors.grey.shade700),
            width: isDeleted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon, title, and delete/restore button
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration:
                                  isDeleted ? TextDecoration.lineThrough : null,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDeleted ? Icons.restore : Icons.delete_outline,
                  ),
                  tooltip: isDeleted ? 'Restore' : 'Delete',
                  onPressed: onToggleDelete,
                ),
              ],
            ),
            // Original time chip
            if (originalTimeDescription != null) ...[
              const SizedBox(height: 8),
              _OriginalTimeChip(description: originalTimeDescription!),
            ],
            // Action message (what user should do)
            if (!isDeleted && actionMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isLightTheme
                      ? AppColors.info.withValues(alpha: 0.1)
                      : AppColors.infoLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color:
                          isLightTheme ? AppColors.info : AppColors.infoLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        actionMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isLightTheme
                                  ? AppColors.info
                                  : AppColors.infoLight,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Content when not deleted
            if (!isDeleted && child != null) ...[
              const SizedBox(height: 12),
              child!,
            ],
            // Deletion message
            if (isDeleted) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  deletedMessage ?? 'This item will be deleted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isLightTheme
                            ? AppColors.error
                            : AppColors.errorLight,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip showing the original time of an entity
class _OriginalTimeChip extends StatelessWidget {
  final String description;

  const _OriginalTimeChip({required this.description});

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 14,
            color: isLightTheme ? AppColors.warning : AppColors.warningLight,
          ),
          const SizedBox(width: 4),
          Text(
            'Was: $description',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isLightTheme ? AppColors.warning : AppColors.warningLight,
                ),
          ),
        ],
      ),
    );
  }
}
