import 'package:flutter/material.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/itinerary/sight.dart';
import 'package:wandrr/data/trip/models/lodging.dart';
import 'package:wandrr/data/trip/models/transit.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/data/trip/models/trip_entity_update/trip_metadata_update.dart';
import 'package:wandrr/data/trip/services/conflict_detection_provider.dart';
import 'package:wandrr/data/trip/services/timeline_conflict_detector.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_resolution_subpage.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';
import 'package:wandrr/presentation/trip/repository_extensions.dart';

/// Enhanced action page that integrates conflict detection and resolution.
/// Supports any entity type (Transit/Lodging/Sight) that can have timeline conflicts.
///
/// Usage:
/// - Pass a [conflictDetectionProvider] to enable conflict detection.
/// - The page will show a conflict warning banner when conflicts are detected.
/// - Users can navigate to the conflict resolution subpage to resolve conflicts.
/// - FAB is disabled until conflicts are acknowledged.
class ConflictAwareActionPage<T extends TripEntity> extends StatefulWidget {
  final void Function(BuildContext context) onClosePressed;
  final void Function(BuildContext context) onActionInvoked;
  final IconData actionIcon;
  final Widget Function(
          ValueNotifier<bool> validityNotifier, VoidCallback onEntityUpdated)
      pageContentCreator;
  final String title;
  final ScrollController? scrollController;
  final T tripEntity;

  /// Optional provider for conflict detection.
  /// If null, no conflict detection is performed.
  final ConflictDetectionProvider? conflictDetectionProvider;

  const ConflictAwareActionPage({
    super.key,
    required this.tripEntity,
    required this.scrollController,
    required this.title,
    required this.onClosePressed,
    required this.onActionInvoked,
    required this.pageContentCreator,
    required this.actionIcon,
    this.conflictDetectionProvider,
  });

  @override
  State<ConflictAwareActionPage<T>> createState() =>
      _ConflictAwareActionPageState<T>();
}

class _ConflictAwareActionPageState<T extends TripEntity>
    extends State<ConflictAwareActionPage<T>> {
  late final ValueNotifier<bool> _validityNotifier;
  late Widget _pageContent;
  bool _showConflictResolution = false;
  TripEntityUpdatePlan? _conflictPlan;

  @override
  void initState() {
    super.initState();
    _validityNotifier = ValueNotifier<bool>(widget.tripEntity.validate());
    _pageContent =
        widget.pageContentCreator(_validityNotifier, _onEntityUpdated);
    _detectConflicts();
  }

  @override
  void dispose() {
    _validityNotifier.dispose();
    super.dispose();
  }

  void _onEntityUpdated() {
    _validityNotifier.value = widget.tripEntity.validate();
    _detectConflicts();
  }

  void _detectConflicts() {
    if (widget.conflictDetectionProvider == null) return;

    final detector = TimelineConflictDetector(tripData: context.activeTrip);
    final newPlan = widget.conflictDetectionProvider!.detectConflicts(detector);

    if (mounted) {
      setState(() {
        _conflictPlan = newPlan;
      });
    }
  }

  bool get _hasUnresolvedConflicts =>
      _conflictPlan != null &&
      _conflictPlan!.hasConflicts &&
      !_conflictPlan!.isAcknowledged;

  @override
  Widget build(BuildContext context) {
    const double fabBottomMargin = 25.0;
    final double bottomPadding =
        TripEditorPageConstants.fabSize + fabBottomMargin + 16.0;

    return Stack(
      children: [
        Column(
          children: [
            _buildAppBar(context),
            // Sticky conflict banner - always visible at top when there are conflicts
            if (_hasUnresolvedConflicts && !_showConflictResolution)
              _StickyConflictBanner(
                conflictPlan: _conflictPlan!,
                onViewConflicts: () {
                  setState(() {
                    _showConflictResolution = true;
                  });
                },
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final slideAnimation = Tween<Offset>(
                    begin: _showConflictResolution
                        ? const Offset(1.0, 0.0)
                        : const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ));

                  return SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: _showConflictResolution && _conflictPlan != null
                    ? SingleChildScrollView(
                        key: const ValueKey('conflict_resolution'),
                        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                        child: ConflictResolutionSubpage(
                          conflictPlan: _conflictPlan!,
                          onBackPressed: () {
                            setState(() {
                              _showConflictResolution = false;
                            });
                          },
                          onConflictsResolved: () {
                            setState(() {
                              _showConflictResolution = false;
                              // Re-detect to check if conflicts are truly resolved
                              _detectConflicts();
                            });
                          },
                        ),
                      )
                    : SingleChildScrollView(
                        key: const ValueKey('editor'),
                        controller: widget.scrollController,
                        padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                        child: _AnimatedActionPage(child: _pageContent),
                      ),
              ),
            ),
          ],
        ),
        if (!_showConflictResolution)
          Positioned(
            bottom: fabBottomMargin,
            left: 0,
            right: 0,
            child: Center(
              child: _createActionButton(context),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isLightTheme = context.isLightTheme;

    return AppBar(
      leading: IconButton(
        icon: Icon(_showConflictResolution ? Icons.arrow_back : Icons.close),
        style: isLightTheme
            ? ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll(AppColors.brandSecondary),
              )
            : null,
        onPressed: () {
          if (_showConflictResolution) {
            setState(() {
              _showConflictResolution = false;
            });
          } else {
            widget.onClosePressed(context);
          }
        },
      ),
      title: Text(_showConflictResolution ? 'Resolve Conflicts' : widget.title),
      centerTitle: true,
      elevation: 0,
      actions: [
        if (_hasUnresolvedConflicts && !_showConflictResolution)
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.warning_amber_rounded),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${_conflictPlan!.totalConflicts}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _showConflictResolution = true;
              });
            },
            tooltip: 'View conflicts',
          ),
      ],
    );
  }

  Widget _createActionButton(BuildContext context) {
    return SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: ValueListenableBuilder<bool>(
        valueListenable: _validityNotifier,
        builder: (context, isValid, child) {
          final canSubmit = isValid && !_hasUnresolvedConflicts;
          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton(
              onPressed: canSubmit
                  ? () {
                      // First dispatch any buffered conflict resolution events
                      _dispatchConflictResolutionEvents(context);
                      // Then invoke the main action (create/update the entity)
                      widget.onActionInvoked(context);
                      Navigator.of(context).pop();
                    }
                  : null,
              backgroundColor:
                  canSubmit ? AppColors.brandPrimary : Colors.grey.shade400,
              child: Icon(widget.actionIcon),
            ),
          );
        },
      ),
    );
  }

  /// Dispatches all buffered conflict resolution events
  void _dispatchConflictResolutionEvents(BuildContext context) {
    if (_conflictPlan == null || !_conflictPlan!.isAcknowledged) return;

    // Process transit changes
    for (final change in _conflictPlan!.transitChanges) {
      if (change.isMarkedForDeletion) {
        context.addTripManagementEvent(
          UpdateTripEntity<TransitFacade>.delete(
              tripEntity: change.originalEntity),
        );
      } else if (change.isClamped ||
          (change.modifiedEntity.departureDateTime != null &&
              change.modifiedEntity.arrivalDateTime != null)) {
        context.addTripManagementEvent(
          UpdateTripEntity<TransitFacade>.update(
              tripEntity: change.modifiedEntity),
        );
      }
    }

    // Process stay changes
    for (final change in _conflictPlan!.stayChanges) {
      if (change.isMarkedForDeletion) {
        context.addTripManagementEvent(
          UpdateTripEntity<LodgingFacade>.delete(
              tripEntity: change.originalEntity),
        );
      } else if (change.isClamped ||
          (change.modifiedEntity.checkinDateTime != null &&
              change.modifiedEntity.checkoutDateTime != null)) {
        context.addTripManagementEvent(
          UpdateTripEntity<LodgingFacade>.update(
              tripEntity: change.modifiedEntity),
        );
      }
    }

    // Process sight changes
    for (final change in _conflictPlan!.sightChanges) {
      if (change.isMarkedForDeletion) {
        context.addTripManagementEvent(
          UpdateTripEntity<SightFacade>.delete(
              tripEntity: change.originalEntity),
        );
      } else {
        context.addTripManagementEvent(
          UpdateTripEntity<SightFacade>.update(
              tripEntity: change.modifiedEntity),
        );
      }
    }
  }
}

/// Sticky conflict banner that stays at the top of the editor.
/// Provides clear messaging and navigation to conflict resolution.
class _StickyConflictBanner extends StatelessWidget {
  final TripEntityUpdatePlan conflictPlan;
  final VoidCallback onViewConflicts;

  const _StickyConflictBanner({
    required this.conflictPlan,
    required this.onViewConflicts,
  });

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final clampedCount = _countClampedEntities();
    final deletionCount = _countDeletionEntities();

    return Material(
      elevation: 4,
      child: InkWell(
        onTap: onViewConflicts,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLightTheme
                  ? [
                      AppColors.warning.withValues(alpha: 0.2),
                      AppColors.error.withValues(alpha: 0.15),
                    ]
                  : [
                      AppColors.warning.withValues(alpha: 0.4),
                      AppColors.errorLight.withValues(alpha: 0.25),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLightTheme
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : AppColors.warningLight.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color:
                      isLightTheme ? AppColors.warning : AppColors.warningLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conflictPlan.totalConflicts} CONFLICT${conflictPlan.totalConflicts > 1 ? 'S' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Resolve to save',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isLightTheme
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildDetailedMessage(clampedCount, deletionCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isLightTheme
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isLightTheme ? AppColors.warning : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Review',
                      style: TextStyle(
                        color: isLightTheme ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: isLightTheme ? Colors.white : Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countClampedEntities() {
    int count = 0;
    for (final change in conflictPlan.transitChanges) {
      if (change.isClamped) count++;
    }
    for (final change in conflictPlan.stayChanges) {
      if (change.isClamped) count++;
    }
    for (final change in conflictPlan.sightChanges) {
      if (change.isClamped) count++;
    }
    return count;
  }

  int _countDeletionEntities() {
    int count = 0;
    for (final change in conflictPlan.transitChanges) {
      if (change.isMarkedForDeletion) count++;
    }
    for (final change in conflictPlan.stayChanges) {
      if (change.isMarkedForDeletion) count++;
    }
    for (final change in conflictPlan.sightChanges) {
      if (change.isMarkedForDeletion) count++;
    }
    return count;
  }

  String _buildDetailedMessage(int clampedCount, int deletionCount) {
    final parts = <String>[];
    if (clampedCount > 0) {
      parts.add('$clampedCount adjusted');
    }
    if (deletionCount > 0) {
      parts.add('$deletionCount need attention');
    }
    if (parts.isEmpty) {
      return 'Tap to review and confirm changes';
    }
    return '${parts.join(', ')} - Tap to review';
  }
}

/// Animated wrapper for the action page content.
class _AnimatedActionPage extends StatefulWidget {
  final Widget child;

  const _AnimatedActionPage({required this.child});

  @override
  State<_AnimatedActionPage> createState() => _AnimatedActionPageState();
}

class _AnimatedActionPageState extends State<_AnimatedActionPage>
    with TickerProviderStateMixin {
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 50),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildEditorCard(context, widget.child),
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, Widget child) {
    final isBigLayout = context.isBigLayout;
    final cardBorderRadius = EditorTheme.getCardBorderRadius(isBigLayout);
    return Container(
      margin: EdgeInsets.all(
        isBigLayout
            ? EditorTheme.cardMarginHorizontalBig
            : EditorTheme.cardMarginHorizontalSmall,
      ),
      constraints: isBigLayout ? const BoxConstraints(maxWidth: 800) : null,
      decoration: EditorTheme.createCardDecoration(
        isLightTheme: context.isLightTheme,
        isBigLayout: isBigLayout,
        borderRadius: cardBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardBorderRadius - 2),
        child: child,
      ),
    );
  }
}
