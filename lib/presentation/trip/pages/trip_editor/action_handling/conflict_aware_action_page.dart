import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/blocs/trip/events.dart';
import 'package:wandrr/blocs/trip_entity_editor/bloc.dart';
import 'package:wandrr/blocs/trip_entity_editor/events.dart';
import 'package:wandrr/blocs/trip_entity_editor/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/services/trip_entity_update_plan.dart';
import 'package:wandrr/data/trip/models/trip_data.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/conflict_resolution/conflict_resolution_subpage.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

/// Enhanced action page that integrates conflict detection and resolution.
/// Supports any entity type (Transit/Lodging/Sight) that can have timeline conflicts.
///
/// Usage:
/// - Pass a [conflictDetectionCallback] to enable conflict detection.
/// - The page will show a conflict warning banner when conflicts are detected.
/// - Users can navigate to the conflict resolution subpage to resolve conflicts.
/// - FAB is disabled until conflicts are acknowledged.
class ConflictAwareActionPage<T extends TripEntity> extends StatefulWidget {
  final VoidCallback onClosePressed;
  final void Function(BuildContext context) onActionInvoked;
  final IconData actionIcon;
  final Widget Function(T editableEntity, ValueNotifier<bool> validityNotifier,
      VoidCallback onEntityUpdated) pageContentCreator;
  final String title;
  final ScrollController? scrollController;
  final T tripEntity;
  final TripDataFacade tripData;
  final bool isEditing;

  const ConflictAwareActionPage({
    super.key,
    required this.tripEntity,
    required this.scrollController,
    required this.title,
    required this.onClosePressed,
    required this.onActionInvoked,
    required this.pageContentCreator,
    required this.actionIcon,
    required this.tripData,
    required this.isEditing,
  });

  @override
  State<ConflictAwareActionPage<T>> createState() =>
      _ConflictAwareActionPageState<T>();
}

class _ConflictAwareActionPageState<T extends TripEntity>
    extends State<ConflictAwareActionPage<T>> {
  late final ValueNotifier<bool> _validityNotifier;
  late final Widget _pageContent;
  late final PageController _pageController;
  bool _isViewingConflictResolution = false;

  @override
  void initState() {
    super.initState();
    _validityNotifier = ValueNotifier<bool>(widget.tripEntity.validate());
    _pageController = PageController(initialPage: 0);
    _pageContent = widget.pageContentCreator(
        widget.tripEntity, _validityNotifier, _onEntityUpdated);
  }

  @override
  void dispose() {
    _validityNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double fabBottomMargin = 25.0;
    final double bottomPadding =
        TripEditorPageConstants.fabSize + fabBottomMargin + 16.0;

    return BlocProvider<TripEntityEditorBloc<T>>(
      create: (context) => widget.isEditing
          ? TripEntityEditorBloc<T>.forEditing(
              tripData: widget.tripData,
              entity: widget.tripEntity,
            )
          : TripEntityEditorBloc<T>.forCreation(
              tripData: widget.tripData,
              entity: widget.tripEntity,
            ),
      child: Builder(builder: (context) {
        return BlocListener<TripEntityEditorBloc<T>, TripEntityEditorState<T>>(
          listener: (context, state) {
            if (state is EntitySubmitted<T>) {
              _handleEntitySubmitted(context, state.editableEntity);
            } else if (state is ConflictedEntityTimeRangeError) {
              final errorState = state as ConflictedEntityTimeRangeError;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorState.errorMessage)),
              );
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
                  BlocSelector<TripEntityEditorBloc<T>,
                      TripEntityEditorState<T>, int>(
                    selector: (state) => state.currentPlan?.conflictCount ?? 0,
                    builder: _buildAppBar,
                  ),
                  BlocSelector<TripEntityEditorBloc<T>,
                      TripEntityEditorState<T>, bool>(
                    selector: (state) {
                      final plan = state.currentPlan;
                      return plan != null &&
                          plan.hasConflicts &&
                          !plan.isConfirmed;
                    },
                    builder: (context, hasUnconfirmedConflicts) {
                      if (hasUnconfirmedConflicts &&
                          !_isViewingConflictResolution) {
                        return _StickyConflictBanner<T>(
                          onViewConflicts: _navigateToConflictResolution,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {});
                      },
                      children: [
                        SingleChildScrollView(
                          controller: widget.scrollController,
                          padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                          child: _AnimatedActionPage(child: _pageContent),
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                          child: BlocSelector<TripEntityEditorBloc<T>,
                              TripEntityEditorState<T>, bool>(
                            selector: (state) => state.currentPlan != null,
                            builder: (context, hasPlan) {
                              return hasPlan
                                  ? ConflictResolutionSubpage<T>(
                                      onBackPressed: _navigateToEditor,
                                      onConflictsResolved: _navigateToEditor,
                                      onConflictsChanged: () {
                                        if (mounted) setState(() {});
                                      },
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_isViewingConflictResolution)
                Positioned(
                  bottom: fabBottomMargin,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: BlocBuilder<TripEntityEditorBloc<T>,
                        TripEntityEditorState<T>>(
                      buildWhen: (previous, current) =>
                          current is ConflictsAdded ||
                          current is ConflictsRemoved ||
                          current is ConflictsUpdated ||
                          current is ConflictItemUpdated ||
                          current is ConflictPlanConfirmed,
                      builder: (context, state) {
                        final conflictPlan = state.currentPlan;
                        final hasUnresolvedConflicts = conflictPlan != null &&
                            conflictPlan.hasConflicts &&
                            !conflictPlan.isConfirmed;
                        return _createActionButton(
                            context, hasUnresolvedConflicts, conflictPlan);
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _onEntityUpdated() {
    // Individual editors now dispatch their own events (LodgingEditor, TripDetailsEditor,
    // ItineraryPlanDataEditor, JourneyEditor) using their own valid BuildContext.
    // This removes the dependency on ConflictAwareActionPage's context for BLoC access.
  }

  void _navigateToConflictResolution() {
    if (_pageController.hasClients) {
      setState(() {
        _isViewingConflictResolution = true;
      });
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToEditor() {
    if (_pageController.hasClients) {
      setState(() {
        _isViewingConflictResolution = false;
      });
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildAppBar(BuildContext context, int conflictsCount) {
    final isLightTheme = context.isLightTheme;

    return AppBar(
      leading: _isViewingConflictResolution
          ? IconButton(
              icon: Icon(Icons.arrow_back),
              style: isLightTheme
                  ? ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(AppColors.brandSecondary),
                    )
                  : null,
              onPressed: _navigateToEditor,
            )
          : IconButton(
              icon: Icon(Icons.close),
              style: isLightTheme
                  ? ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(AppColors.brandSecondary),
                    )
                  : null,
              onPressed: widget.onClosePressed,
            ),
      title: Text(
          _isViewingConflictResolution ? 'Resolve Conflicts' : widget.title),
      centerTitle: true,
      elevation: 0,
      actions: [
        if (conflictsCount > 0 && !_isViewingConflictResolution)
          _createConflictCountIndicator(isLightTheme, conflictsCount),
      ],
    );
  }

  IconButton _createConflictCountIndicator(
      bool isLightTheme, int conflictsCount) {
    return IconButton(
      style: isLightTheme
          ? ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.brandSecondary),
            )
          : null,
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
                conflictsCount.toString(),
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
      onPressed: _navigateToConflictResolution,
    );
  }

  Widget _createActionButton(BuildContext context, bool hasUnresolvedConflicts,
      TripEntityUpdatePlan<T>? conflictPlan) {
    return SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: ValueListenableBuilder<bool>(
        valueListenable: _validityNotifier,
        builder: (context, isValid, child) {
          final canSubmit = isValid && !hasUnresolvedConflicts;
          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton(
              heroTag: null,
              onPressed: canSubmit
                  ? () {
                      context.addTripEntityEditorEvent<T>(const SubmitEntity());
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

  void _handleEntitySubmitted(BuildContext context, T editableEntity) {
    final conflictPlan = context.read<TripEntityEditorBloc<T>>().currentPlan;
    if (conflictPlan != null && conflictPlan.isConfirmed) {
      context.addTripManagementEvent(
          ApplyTripDataUpdatePlan(updatePlan: conflictPlan));
    }
    widget.onActionInvoked(context);
    Navigator.of(context).pop();
  }
}

/// Sticky conflict banner that stays at the top of the editor.
/// Provides clear messaging and navigation to conflict resolution.
class _StickyConflictBanner<T extends TripEntity> extends StatelessWidget {
  final VoidCallback onViewConflicts;

  const _StickyConflictBanner({
    required this.onViewConflicts,
  });

  @override
  Widget build(BuildContext context) {
    final conflictPlan = context.tripEntityUpdatePlan<T>()!;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final clampedCount = _countClampedEntities(conflictPlan);
    final deletionCount = _countDeletionEntities(conflictPlan);

    return Material(
      elevation: 4,
      child: InkWell(
        onTap: onViewConflicts,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
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
                    _createConflictCountText(conflictPlan, context),
                    const SizedBox(height: 4),
                    Text(
                      _buildDetailedMessage(clampedCount, deletionCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: isLightTheme
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _createReviewButton(isLightTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createConflictCountText(
      TripEntityUpdatePlan conflictPlan, BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${conflictPlan.conflictCount} CONFLICT${conflictPlan.conflictCount > 1 ? 'S' : ''}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Resolve to save',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.isLightTheme
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
        ),
      ],
    );
  }

  Widget _createReviewButton(bool isLightTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLightTheme ? AppColors.warning : AppColors.warningLight,
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
    );
  }

  int _countClampedEntities(TripEntityUpdatePlan conflictPlan) {
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

  int _countDeletionEntities(TripEntityUpdatePlan conflictPlan) {
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
