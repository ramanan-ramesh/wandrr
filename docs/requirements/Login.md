# Login

## Requirements

### Login

#### Login.ModeSwitching

- **REQ_LOGIN_002**: Switching between Login and Register modes does not clear the entered username or password.

#### Login.Username

- **REQ_LOGIN_003**: The username field accepts an email address.

##### Login.Username.Validation

- **REQ_LOGIN_004**: The username must be a valid email address before email-and-password authentication can be submitted.

#### Login.Password

- **REQ_LOGIN_005**: The password field hides the entered password by default.

##### Login.Password.Visibility

- **REQ_LOGIN_006**: The user can toggle password visibility.

##### Login.Password.Validation

- **REQ_LOGIN_007**: Passwords must be 8 to 20 characters and include uppercase, lowercase, numeric, and special characters.

#### Login.Submission

- **REQ_LOGIN_012**: In Login mode, submitting valid credentials attempts to sign the user in.

- **REQ_LOGIN_013**: In Register mode, submitting valid credentials attempts to create a new account.

#### Login.Loading

- **REQ_LOGIN_014**: Authentication actions are unavailable while an authentication request is in progress.

#### Login.GoogleSignIn

- **REQ_LOGIN_015**: The login page provides a Google sign-in option.

##### Login.GoogleSignIn.Loading

- **REQ_LOGIN_016**: Google sign-in is unavailable while another authentication request is in progress.

#### Login.Success

- **REQ_LOGIN_017**: After successful authentication, the user is taken to the trips list.

#### Login.EmailVerification

##### Login.EmailVerification.Pending

- **REQ_LOGIN_018**: When email verification is pending, the page shows a verification-required message.

##### Login.EmailVerification.Resend

- **REQ_LOGIN_019**: When email verification is pending, the user can request another verification email.

##### Login.EmailVerification.Resent

- **REQ_LOGIN_020**: After a verification email is resent, the page continues to show the verification status.

#### Login.Errors

##### Login.Errors.WrongPassword

- **REQ_LOGIN_021**: Authentication failures show appropriate field-level errors for the affected credential fields.

##### Login.Errors.InvalidCredentials

- **REQ_LOGIN_024**: When credentials fail validation, the user is prevented from submitting until the errors are corrected.

#### Login.KeyboardNavigation

- **REQ_LOGIN_025**: Form controls follow a logical order for keyboard navigation.
