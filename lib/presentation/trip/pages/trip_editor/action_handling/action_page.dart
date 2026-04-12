import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wandrr/blocs/trip/bloc.dart';
import 'package:wandrr/blocs/trip/states.dart';
import 'package:wandrr/data/app/repository_extensions.dart';
import 'package:wandrr/data/trip/models/trip_entity.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/trip_editor_constants.dart';

class TripEditorActionPage<T extends TripEntity> extends StatefulWidget {
  /// Dispatches update events and returns the number of pending operations.
  final int Function(BuildContext context) onActionInvoked;
  final IconData actionIcon;
  final Widget Function(ValueNotifier<bool> validityNotifier)
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

class _TripEditorActionPageState<T extends TripEntity>
    extends State<TripEditorActionPage<T>> {
  late final ValueNotifier<bool> validityNotifier;
  late final Widget pageContent;
  bool _isSubmitting = false;
  int _pendingOperations = 0;

  @override
  void initState() {
    super.initState();
    validityNotifier = ValueNotifier<bool>(widget.tripEntity.validate());
    pageContent = widget.pageContentCreator(validityNotifier);
  }

  @override
  void dispose() {
    validityNotifier.dispose();
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
              AppBar(
                leading: IconButton(
                    icon: const Icon(Icons.close),
                    style: context.isLightTheme
                        ? const ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                                AppColors.brandSecondary),
                          )
                        : null,
                    onPressed: () {
                      widget.onClosePressed();
                    }),
                title: Text(widget.title),
                centerTitle: true,
                elevation: 0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.only(bottom: bottomPadding),
                  child: _AnimatedActionPage(
                    child: pageContent,
                  ),
                ),
              ),
            ],
          ),
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
        child: ValueListenableBuilder<bool>(
          valueListenable: validityNotifier,
          builder: (context, isValid, _) {
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
