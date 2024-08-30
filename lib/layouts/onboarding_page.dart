import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnBoardingPage extends StatelessWidget {
  VoidCallback? loginCallback;

  OnBoardingPage({super.key, this.loginCallback});

  static const _onBoardingImageAsset = 'assets/images/plan_itinerary.jpg';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: Image(
            image: AssetImage(_onBoardingImageAsset),
            fit: BoxFit.fitHeight,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  AppLocalizations.of(context)!.plan_itinerary,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 45,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                )),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.only(right: 4),
            child: LanguageSwitcher(
              loginCallback: loginCallback,
            ),
          ),
        ),
      ],
    );
  }
}

class LanguageSwitcher extends StatefulWidget {
  VoidCallback? loginCallback;

  LanguageSwitcher({super.key, this.loginCallback});

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  bool _isExpanded = false;

  static const _hindiLanguage = 'हिंदी';
  static const _englishLanguage = 'English';
  static const _imageAssetsLocation = 'assets/images/flags/';

  final _languagesAndCountryFlagAssets = <String, String>{
    _hindiLanguage: '${_imageAssetsLocation}india.png',
    _englishLanguage: '${_imageAssetsLocation}britain.png'
  };

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  List<Widget> _buildLanguageButtons() {
    return [
      _LanguageButton(
        countryFlagAsset: _languagesAndCountryFlagAssets[_hindiLanguage]!,
        languageName: _hindiLanguage,
        visible: _isExpanded,
      ),
      _LanguageButton(
        countryFlagAsset: _languagesAndCountryFlagAssets[_englishLanguage]!,
        languageName: _englishLanguage,
        visible: _isExpanded,
      )
    ];
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
          child: Icon(
            Icons.translate,
            size: 75,
          ),
        ),
        if (widget.loginCallback != null)
          FloatingActionButton.large(
            onPressed: widget.loginCallback,
            shape: CircleBorder(),
            child: Icon(
              Icons.navigate_next_rounded,
              size: 75,
            ),
          )
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton(
      {required String countryFlagAsset,
      required String languageName,
      required bool visible})
      : _languageName = languageName,
        _countryFlagAsset = countryFlagAsset,
        _visible = visible;

  final String _countryFlagAsset;
  final String _languageName;
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
              onPressed: () {},
              label: Text(
                _languageName,
                style: const TextStyle(fontSize: 16.0),
              ),
              icon: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: Image.asset(
                  _countryFlagAsset,
                  width: 35,
                  height: 35,
                  fit: BoxFit.fill,
                ),
              ),
            )));
  }
}
