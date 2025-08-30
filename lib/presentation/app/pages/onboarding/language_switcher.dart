import 'package:flutter/material.dart';
import 'package:wandrr/blocs/app/master_page_events.dart';
import 'package:wandrr/blocs/bloc_extensions.dart';
import 'package:wandrr/data/app/models/language_metadata.dart';
import 'package:wandrr/data/app/repository_extensions.dart';

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key});

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  List<Widget> _buildLanguageButtons() {
    return context.appDataRepository.languageMetadatas
        .map((e) => _LanguageButton(
            languageMetadata: e,
            visible: _isExpanded,
            onLanguageSelected: _toggleExpand))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._buildLanguageButtons().map((e) => Container(
              padding: const EdgeInsets.all(4),
              child: e,
            )),
        FloatingActionButton.large(
          onPressed: _toggleExpand,
          child: const Icon(
            Icons.translate,
            size: 75,
          ),
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final VoidCallback onLanguageSelected;

  const _LanguageButton(
      {required LanguageMetadata languageMetadata,
      required bool visible,
      required this.onLanguageSelected})
      : _languageMetadata = languageMetadata,
        _visible = visible;

  final LanguageMetadata _languageMetadata;
  final bool _visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
        visible: _visible,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            curve: Curves.fastOutSlowIn,
            opacity: _visible ? 1 : 0,
            child: FloatingActionButton.extended(
              onPressed: () {
                onLanguageSelected();
                context.addMasterPageEvent(ChangeLanguage(
                    languageToChangeTo: _languageMetadata.locale));
              },
              label: Text(
                _languageMetadata.name,
                style: const TextStyle(fontSize: 16.0),
              ),
              icon: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: Image.asset(
                  _languageMetadata.flagAssetLocation,
                  width: 35,
                  height: 35,
                  fit: BoxFit.fill,
                ),
              ),
            )));
  }
}
