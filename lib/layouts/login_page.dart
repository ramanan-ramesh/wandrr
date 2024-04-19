import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:wandrr/blocs/authentication_bloc/auth_bloc.dart';
import 'package:wandrr/blocs/authentication_bloc/auth_events.dart';
import 'package:wandrr/blocs/authentication_bloc/auth_states.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_bloc.dart';
import 'package:wandrr/blocs/master_page_bloc/master_page_events.dart';
import 'package:wandrr/platform_elements/form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  TabController? _tabController;
  static const String googleLogoAsset = 'assets/images/google_logo.png';
  static final _emailRegExValidator = RegExp('.*@.*.com');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(25))),
            child: BlocProvider<AuthenticationBloc>(
              create: (context) => AuthenticationBloc(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _createTabBar(),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildUserNamePasswordForm(),
                  ),
                  const SizedBox(height: 24.0),
                  ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 200, minWidth: 150),
                    child: SubmitButton(
                      submitAction: _submitLoginForm,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _buildAlternateLoginMethods(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitLoginForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      String username = _usernameController.text;
      String password = _passwordController.text;

      var authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
      authenticationBloc.add(AuthenticateWithUsernamePassword(
          userName: username,
          passWord: password,
          isLogin: _tabController!.index == 0));
    }
  }

  Column _buildAlternateLoginMethods(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.alternativeLogin,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 25,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAlternateLoginProviderButton(),
            const SizedBox(width: 16.0),
            _buildAlternateLoginProviderButton(),
            const SizedBox(width: 16.0),
            _buildAlternateLoginProviderButton(),
          ],
        ),
      ],
    );
  }

  Material _buildAlternateLoginProviderButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        splashColor: Colors.white30,
        onTap: () {},
        child: Ink.image(
          image: const AssetImage(googleLogoAsset),
          fit: BoxFit.cover,
          height: 60,
          width: 60,
        ),
      ),
    );
  }

  TabBar _createTabBar() {
    return TabBar(
      controller: _tabController,
      labelStyle: const TextStyle(fontSize: 22),
      unselectedLabelStyle: TextStyle(
        fontSize: 22,
      ),
      tabs: [
        Tab(text: AppLocalizations.of(context)!.login),
        Tab(text: AppLocalizations.of(context)!.register),
      ],
    );
  }

  Widget _buildUserNamePasswordForm() {
    return Form(
      key: _formKey,
      child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
        builder: (BuildContext context, AuthenticationState state) {
          return Column(
            children: [
              _createUserNameField(state),
              const SizedBox(height: 16.0),
              _createPasswordField(state)
            ],
          );
        },
        listener: (BuildContext context, AuthenticationState state) {},
      ),
    );
  }

  Widget _createPasswordField(AuthenticationState authState) {
    String? errorText;
    if (authState is AuthenticationFailure) {
      if (authState.failureReason == AuthenticationFailures.WrongPassword) {
        errorText = AppLocalizations.of(context)!.wrong_password_entered;
      }
    }
    return PlatformPasswordField(
      controller: _passwordController,
      labelText: AppLocalizations.of(context)!.password,
      errorText: errorText,
      validator: (password) {
        if (password != null) {
          if (password.length <= 6) {
            return AppLocalizations.of(context)!.password_short;
          }
        }
        return null;
      },
    );
  }

  Widget _createUserNameField(AuthenticationState authState) {
    String? errorText;
    if (authState is AuthenticationFailure) {
      if (authState.failureReason ==
          AuthenticationFailures.UsernameAlreadyExists) {
        errorText = AppLocalizations.of(context)!.userNameAlreadyExists;
      } else if (authState.failureReason ==
          AuthenticationFailures.NoSuchUsernameExists) {
        errorText = AppLocalizations.of(context)!.noSuchUserExists;
      }
    }
    return PlatformTextField(
      controller: _usernameController,
      icon: Icons.person_2_rounded,
      labelText: AppLocalizations.of(context)!.userName,
      errorText: errorText,
      validator: (username) {
        if (username != null) {
          var matches = _emailRegExValidator.firstMatch(username);
          final matchedText = matches?.group(0);
          if (matchedText != username) {
            return AppLocalizations.of(context)!.enterValidEmail;
          }
        }
        return null;
      },
    );
  }
}

class SubmitButton extends StatefulWidget {
  final Function(BuildContext)? submitAction;

  const SubmitButton({super.key, this.submitAction});

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  void _submitLoginForm() {
    widget.submitAction!(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {},
      builder: (context, state) {
        //TODO: BE should do this instead
        if (state is AuthenticationSuccess) {
          var masterPageBloc = BlocProvider.of<MasterPageBloc>(context);
          masterPageBloc.add(ChangeUser.signIn(
              authProviderUser: state.authProviderUser,
              authenticationType: state.authenticationType));
        }
        return FloatingActionButton(
          onPressed: _submitLoginForm,
          backgroundColor: Colors.black,
          child: state is Authenticating
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : Icon(
                  Icons.login_rounded,
                  color: Colors.white,
                ),
        );
      },
    );
  }
}
