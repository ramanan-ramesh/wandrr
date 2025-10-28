import 'package:flutter/material.dart';
import 'package:wandrr/l10n/extension.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';
import 'package:wandrr/presentation/app/widgets/dialog.dart';
import 'package:wandrr/presentation/app/widgets/text.dart';
import 'package:wandrr/presentation/trip/pages/trip_editor/editor_theme.dart';

class TripContributorsEditor extends StatefulWidget {
  final Iterable<String> contributors;
  final ValueChanged<Iterable<String>> onContributorsChanged;

  const TripContributorsEditor({
    super.key,
    required this.contributors,
    required this.onContributorsChanged,
  });

  @override
  State<TripContributorsEditor> createState() => _TripContributorsEditorState();
}

class _TripContributorsEditorState extends State<TripContributorsEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _contributorController;
  late List<String> _contributors;
  bool _isAddContributorFieldVisible = false;

  @override
  void initState() {
    super.initState();
    _contributorController = TextEditingController();
    _contributors = List.from(widget.contributors);
  }

  @override
  void dispose() {
    _contributorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return EditorTheme.buildSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EditorTheme.buildSectionHeader(
                context,
                icon: Icons.people_rounded,
                title: 'Trip Mates',
                iconColor:
                    isLightTheme ? AppColors.success : AppColors.successLight,
              ),
              _buildAddContributorButton(context),
            ],
          ),
          const SizedBox(height: 12),
          _buildContributorsList(context),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isAddContributorFieldVisible
                ? _buildAddContributorField(context)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContributorButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isAddContributorFieldVisible = !_isAddContributorFieldVisible;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isAddContributorFieldVisible
                  ? [AppColors.error, AppColors.errorLight]
                  : [AppColors.success, AppColors.successLight],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (_isAddContributorFieldVisible
                        ? AppColors.error
                        : AppColors.success)
                    .withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isAddContributorFieldVisible
                    ? Icons.close
                    : Icons.person_add_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                _isAddContributorFieldVisible ? 'Cancel' : 'Add',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributorsList(BuildContext context) {
    if (_contributors.isEmpty) {
      return _buildEmptyContributorsState(context);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _contributors.map((contributor) {
        return _buildContributorChip(context, contributor);
      }).toList(),
    );
  }

  Widget _buildEmptyContributorsState(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLightTheme
            ? AppColors.neutral200.withValues(alpha: 0.5)
            : AppColors.darkSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLightTheme
              ? AppColors.neutral400.withValues(alpha: 0.3)
              : AppColors.neutral600.withValues(alpha: 0.3),
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_add_alt_1_rounded,
            color: isLightTheme ? AppColors.neutral600 : AppColors.neutral400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No trip mates added yet. Tap "Add" to invite someone!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isLightTheme
                        ? AppColors.neutral600
                        : AppColors.neutral400,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorChip(BuildContext context, String contributor) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isLightTheme
                  ? AppColors.brandPrimaryLight.withValues(alpha: 0.2)
                  : AppColors.brandPrimary.withValues(alpha: 0.3),
              isLightTheme
                  ? AppColors.brandAccent.withValues(alpha: 0.15)
                  : AppColors.brandPrimaryDark.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLightTheme
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : AppColors.brandPrimaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isLightTheme
                  ? AppColors.brandPrimary
                  : AppColors.brandPrimaryLight,
              child: Text(
                contributor.isNotEmpty ? contributor[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              contributor,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _removeContributor(contributor),
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                Icons.close,
                size: 16,
                color: isLightTheme ? AppColors.error : AppColors.errorLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddContributorField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              child: PlatformTextElements.createUsernameFormField(
                context: context,
                controller: _contributorController,
                textInputAction: TextInputAction.done,
                readonly: false,
                inputDecoration: InputDecoration(
                  icon: const Icon(Icons.person_2_rounded),
                  labelText: context.localizations.userName,
                ),
                onFieldSubmitted: (_) => _validateAndAddContributor(),
                validator: _validateContributor,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _validateAndAddContributor,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, AppColors.successLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndAddContributor() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final name = _contributorController.text.trim();
    if (name.isNotEmpty && !_contributors.contains(name)) {
      PlatformDialogElements.showAlertDialog(context, (dialogContext) {
        return AlertDialog(
          title:
              Text(context.localizations.splitExpensesWithNewTripMateMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(context.localizations.no),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _contributors.add(name);
                  widget.onContributorsChanged(_contributors);
                  _contributorController.clear();
                  _isAddContributorFieldVisible = false;
                });
                Navigator.of(dialogContext).pop();
              },
              child: Text(context.localizations.yes),
            ),
          ],
        );
      });
    }
  }

  String? _validateContributor(String? name) {
    if (_contributors.contains(name?.trim())) {
      return 'This name is already added.';
    }
    return null;
  }

  void _removeContributor(String contributor) {
    setState(() {
      _contributors.remove(contributor);
      widget.onContributorsChanged(_contributors);
    });
  }
}
