import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/action_handling/validation_error_subpage.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

class TripEditorActionPage<T extends TripEntity<Enum>> extends StatefulWidget {
  /// Dispatches update events and returns the number of pending operations.
  final int Function(BuildContext context) onActionInvoked;
  final IconData actionIcon;
  final Widget Function(ValueNotifier<Iterable<Enum>> validityNotifier)
      pageContentCreator;
  final String title;
  final ScrollController? scrollController;
  final T tripEntity;
  final VoidCallback onClosePressed;

  const TripEditorActionPage({
    required this.tripEntity,
    required this.scrollController,
    required this.title,
    required this.onActionInvoked,
    required this.pageContentCreator,
    required this.actionIcon,
    required this.onClosePressed,
    super.key,
  });

  @override
  State<TripEditorActionPage<T>> createState() =>
      _TripEditorActionPageState<T>();
}

class _TripEditorActionPageState<T extends TripEntity<Enum>>
    extends State<TripEditorActionPage<T>> {
  late final ValueNotifier<Iterable<Enum>> validityNotifier;
  late final Widget pageContent;
  late final PageController _pageController;
  int _pageIndex = 0;
  bool _isSubmitting = false;
  int _pendingOperations = 0;

  @override
  void initState() {
    super.initState();
    validityNotifier =
        ValueNotifier<Iterable<Enum>>(widget.tripEntity.getValidationErrors());
    _pageController = PageController(initialPage: 0);
    pageContent = widget.pageContentCreator(validityNotifier);
  }

  @override
  void dispose() {
    validityNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fabBottomMargin = 25.0;
    const bottomPadding =
        TripEditorPageConstants.fabSize + fabBottomMargin + 16.0;

    return BlocListener<TripManagementBloc, TripManagementState>(
      listenWhen: (_, current) => _isSubmitting && current is UpdatedTripEntity,
      listener: (context, state) {
        if (!_isSubmitting) {
          return;
        }
        if (state is UpdatedTripEntity) {
          _pendingOperations--;
          if (_pendingOperations <= 0) {
            _isSubmitting = false;
            _pendingOperations = 0;
            Navigator.of(context).pop();
          }
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              ValueListenableBuilder<Iterable<Enum>>(
                valueListenable: validityNotifier,
                builder: (context, errors, child) {
                  return AppBar(
                    leading: _pageIndex != 0
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            style: context.isLightTheme
                                ? const ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        AppColors.brandSecondary),
                                  )
                                : null,
                            onPressed: _navigateToEditor,
                          )
                        : IconButton(
                            icon: const Icon(Icons.close),
                            style: context.isLightTheme
                                ? const ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                        AppColors.brandSecondary),
                                  )
                                : null,
                            onPressed: widget.onClosePressed,
                          ),
                    title: Text(_pageIndex == 1 ? 'Fix Errors' : widget.title),
                    centerTitle: true,
                    elevation: 0,
                    actions: [
                      if (errors.isNotEmpty && _pageIndex == 0)
                        _createErrorCountIndicator(
                            context.isLightTheme, errors.length),
                    ],
                  );
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
                      padding: const EdgeInsets.only(bottom: bottomPadding),
                      child: _AnimatedActionPage(
                        child: pageContent,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: bottomPadding),
                      child: ValueListenableBuilder<Iterable<Enum>>(
                        valueListenable: validityNotifier,
                        builder: (context, errors, _) {
                          return ValidationErrorSubpage<T>(
                            onBackPressed: _navigateToEditor,
                            errors: errors,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_pageIndex == 0)
            Positioned(
              bottom: fabBottomMargin,
              left: 0,
              right: 0,
              child: Center(
                child: _createActionButton(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _createActionButton(BuildContext context) {
    return SizedBox(
      height: TripEditorPageConstants.fabSize,
      width: TripEditorPageConstants.fabSize,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 3000),
        child: ValueListenableBuilder<Iterable<Enum>>(
          valueListenable: validityNotifier,
          builder: (context, errors, _) {
            final isValid = errors.isEmpty;
            final canSubmit = isValid && !_isSubmitting;
            return FloatingActionButton(
              heroTag: null,
              onPressed: canSubmit ? _onSubmit : null,
              backgroundColor:
                  canSubmit ? AppColors.brandPrimary : Colors.grey.shade400,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(widget.actionIcon),
            );
          },
        ),
      ),
    );
  }

  void _onSubmit() {
    final operationCount = widget.onActionInvoked(context);
    setState(() {
      _isSubmitting = true;
      _pendingOperations = operationCount;
    });
  }

  void _navigateToValidationErrors() {
    if (_pageController.hasClients) {
      setState(() {
        _pageIndex = 1;
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
        _pageIndex = 0;
      });
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  IconButton _createErrorCountIndicator(bool isLightTheme, int errorCount) {
    return IconButton(
      style: isLightTheme
          ? const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.brandSecondary),
            )
          : null,
      icon: Stack(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                errorCount.toString(),
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
      onPressed: _navigateToValidationErrors,
    );
  }
}

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
    final cardBorderRadius =
        EditorTheme.getCardBorderRadius(isBigLayout: isBigLayout);
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
