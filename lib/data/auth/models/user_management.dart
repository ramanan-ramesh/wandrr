import 'package:wandrr/data/auth/models/auth_type.dart';
import 'package:wandrr/data/auth/models/platform_user.dart';
import 'package:wandrr/data/auth/models/status.dart';

abstract interface class UserManagementFacade {
  PlatformUser? get activeUser;
}

abstract interface class UserManagementModifier extends UserManagementFacade {
  Future<void> initialize();

  Future<AuthStatus> trySignInWithThirdParty(
      AuthenticationType authenticationType);

  Future<AuthStatus> trySignInWithUsernamePassword(
      {required String userName, required String password});

  Future<AuthStatus> trySignUpWithUsernamePassword(
      {required String userName, required String password});

  Future<bool> resendVerificationEmail(String email, String password);

  Future<bool> trySignOut();
}
