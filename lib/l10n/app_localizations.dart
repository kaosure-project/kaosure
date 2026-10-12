import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_lo.dart';
import 'app_localizations_my.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('lo'),
    Locale('my'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language. Please try again.'**
  String get languageSaveFailed;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KaoSure'**
  String get appName;

  /// No description provided for @kaoId.
  ///
  /// In en, this message translates to:
  /// **'Kao ID'**
  String get kaoId;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageThai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get languageThai;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChineseSimplified.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageChineseSimplified;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJapanese;

  /// No description provided for @languageBurmese.
  ///
  /// In en, this message translates to:
  /// **'Burmese'**
  String get languageBurmese;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationPreferencesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationPreferencesDescription;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyPermissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Privacy & permissions'**
  String get privacyPermissionsDescription;

  /// No description provided for @aboutKaoId.
  ///
  /// In en, this message translates to:
  /// **'About Kao ID'**
  String get aboutKaoId;

  /// No description provided for @aboutKaoIdDescription.
  ///
  /// In en, this message translates to:
  /// **'Version, licenses and legal'**
  String get aboutKaoIdDescription;

  /// No description provided for @passwordChangeDescription.
  ///
  /// In en, this message translates to:
  /// **'Change your password'**
  String get passwordChangeDescription;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @trustedDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage trusted devices'**
  String get trustedDevicesDescription;

  /// No description provided for @loginHistory.
  ///
  /// In en, this message translates to:
  /// **'Login History'**
  String get loginHistory;

  /// No description provided for @loginHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Recent sign-in activity'**
  String get loginHistoryDescription;

  /// No description provided for @twoFactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthentication;

  /// No description provided for @twoFactorDescription.
  ///
  /// In en, this message translates to:
  /// **'Protect your account'**
  String get twoFactorDescription;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @marketplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell on KaoSure'**
  String get marketplaceDescription;

  /// No description provided for @auction.
  ///
  /// In en, this message translates to:
  /// **'Auction'**
  String get auction;

  /// No description provided for @auctionDescription.
  ///
  /// In en, this message translates to:
  /// **'Item auctions'**
  String get auctionDescription;

  /// No description provided for @kaoPay.
  ///
  /// In en, this message translates to:
  /// **'KaoPay'**
  String get kaoPay;

  /// No description provided for @kaoPayDescription.
  ///
  /// In en, this message translates to:
  /// **'Digital wallet'**
  String get kaoPayDescription;

  /// No description provided for @moreServices.
  ///
  /// In en, this message translates to:
  /// **'More services'**
  String get moreServices;

  /// No description provided for @moreServicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore Kao Ecosystem services'**
  String get moreServicesDescription;

  /// No description provided for @serviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get serviceUnavailable;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get verifyIdentity;

  /// No description provided for @kaoCode.
  ///
  /// In en, this message translates to:
  /// **'Kao Code'**
  String get kaoCode;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get accountTitle;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account and security'**
  String get accountSecurity;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get identityVerification;

  /// No description provided for @identityVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to improve account security'**
  String get identityVerificationDescription;

  /// No description provided for @bankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank accounts'**
  String get bankAccounts;

  /// No description provided for @bankAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage bank accounts for receiving payments'**
  String get bankAccountsDescription;

  /// No description provided for @accountDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Review and manage signed-in devices'**
  String get accountDevicesDescription;

  /// No description provided for @accountSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions and sign-ins'**
  String get accountSessions;

  /// No description provided for @accountSessionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review sign-in activity'**
  String get accountSessionsDescription;

  /// No description provided for @businessAccount.
  ///
  /// In en, this message translates to:
  /// **'Business account'**
  String get businessAccount;

  /// No description provided for @organizations.
  ///
  /// In en, this message translates to:
  /// **'Companies / organizations'**
  String get organizations;

  /// No description provided for @organizationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage organizations and access permissions'**
  String get organizationsDescription;

  /// No description provided for @accountLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your Kao ID language'**
  String get accountLanguageDescription;

  /// No description provided for @accountNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage Kao ID notifications'**
  String get accountNotificationsDescription;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @kaoIdAvailableAfterVerification.
  ///
  /// In en, this message translates to:
  /// **'Available after identity verification'**
  String get kaoIdAvailableAfterVerification;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @displayNameExample.
  ///
  /// In en, this message translates to:
  /// **'For example, KaoSure Official'**
  String get displayNameExample;

  /// No description provided for @profileSharedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your display name and photo are used across Kao ID services. You can change them later.'**
  String get profileSharedDescription;

  /// No description provided for @displayNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must contain at least 3 characters'**
  String get displayNameMinLength;

  /// No description provided for @displayNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Name must contain no more than 30 characters'**
  String get displayNameMaxLength;

  /// No description provided for @profileVisibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Your profile photo and name appear across Kao ID services'**
  String get profileVisibilityDescription;

  /// No description provided for @editYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile'**
  String get editYourProfile;

  /// No description provided for @profileDescription.
  ///
  /// In en, this message translates to:
  /// **'You can change your Kao ID display name and profile photo. They appear in Marketplace and other Kao Ecosystem services.'**
  String get profileDescription;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get profileDetails;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get accountVerified;

  /// No description provided for @organizationAccount.
  ///
  /// In en, this message translates to:
  /// **'Organization account'**
  String get organizationAccount;

  /// No description provided for @accountRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get accountRegistered;

  /// No description provided for @accountStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard account'**
  String get accountStandard;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfile;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfile;

  /// No description provided for @completeProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up your basic Kao ID profile.'**
  String get completeProfileDescription;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name shown to other users'**
  String get displayNameHint;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a display name'**
  String get displayNameRequired;

  /// No description provided for @displayNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Display name must contain no more than 100 characters'**
  String get displayNameTooLong;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get preferredLanguage;

  /// No description provided for @languageCodeHint.
  ///
  /// In en, this message translates to:
  /// **'For example, th or en'**
  String get languageCodeHint;

  /// No description provided for @languageRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a language'**
  String get languageRequired;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again.'**
  String get profileLoadFailed;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @kaoIdUser.
  ///
  /// In en, this message translates to:
  /// **'Kao ID user'**
  String get kaoIdUser;

  /// No description provided for @usernameNotSet.
  ///
  /// In en, this message translates to:
  /// **'Username not set'**
  String get usernameNotSet;

  /// No description provided for @accountCompletion.
  ///
  /// In en, this message translates to:
  /// **'Account completion {percent}%'**
  String accountCompletion(int percent);

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your account. Please try again.'**
  String get dashboardLoadFailed;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// No description provided for @homeIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and security in one place.'**
  String get homeIntroduction;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @identityEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Check your status and continue identity verification through Kao ID.'**
  String get identityEntryDescription;

  /// No description provided for @viewIdentityStatus.
  ///
  /// In en, this message translates to:
  /// **'View verification status'**
  String get viewIdentityStatus;

  /// No description provided for @governanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get governanceLabel;

  /// No description provided for @governanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the platform with your assigned permissions'**
  String get governanceDescription;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authRegister;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Include at least one number'**
  String get authPasswordNumberRequired;

  /// No description provided for @authPasswordSpecialRequired.
  ///
  /// In en, this message translates to:
  /// **'Include at least one special character'**
  String get authPasswordSpecialRequired;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get authConfirmPasswordHint;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPassword;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordLink;

  /// No description provided for @authExistingAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authExistingAccount;

  /// No description provided for @authRegistrationSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get authRegistrationSucceeded;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authSendResetLink;

  /// No description provided for @authResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If this email can be used for account recovery, you will receive a reset link.'**
  String get authResetLinkSent;

  /// No description provided for @authVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyEmail;

  /// No description provided for @authVerificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get authVerificationEmailSent;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email has not been verified yet'**
  String get authEmailNotVerified;

  /// No description provided for @authEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get authEmailVerified;

  /// No description provided for @authVerifyEmailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Open your verification email and follow the link. If you cannot find it, you can request another email.'**
  String get authVerifyEmailInstructions;

  /// No description provided for @authResendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get authResendVerificationEmail;

  /// No description provided for @authCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get authCheckAgain;

  /// No description provided for @authVerifyLater.
  ///
  /// In en, this message translates to:
  /// **'Verify later'**
  String get authVerifyLater;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get authNewPasswordHint;

  /// No description provided for @authNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get authNewPasswordRequired;

  /// No description provided for @authConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get authConfirmNewPassword;

  /// No description provided for @authConfirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the new password again'**
  String get authConfirmNewPasswordHint;

  /// No description provided for @authConfirmNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get authConfirmNewPasswordRequired;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPassword;

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get authPasswordChanged;

  /// No description provided for @authInvalidRecoveryLink.
  ///
  /// In en, this message translates to:
  /// **'This password reset link is invalid or has expired'**
  String get authInvalidRecoveryLink;

  /// No description provided for @authInvalidRecoveryDescription.
  ///
  /// In en, this message translates to:
  /// **'Request a new reset link to confirm your password change.'**
  String get authInvalidRecoveryDescription;

  /// No description provided for @authRequestNewLink.
  ///
  /// In en, this message translates to:
  /// **'Request a new link'**
  String get authRequestNewLink;

  /// No description provided for @authVerificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get authVerificationCodeSent;

  /// No description provided for @authSendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send a verification code. Please try again.'**
  String get authSendCodeFailed;

  /// No description provided for @authChangePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change your password. Check the verification code and try again.'**
  String get authChangePasswordFailed;

  /// No description provided for @authVerificationCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get authVerificationCodeRequired;

  /// No description provided for @authReauthenticateTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify before changing your password'**
  String get authReauthenticateTitle;

  /// No description provided for @authReauthenticateDescription.
  ///
  /// In en, this message translates to:
  /// **'For security, we will send a code to the verified email address or phone number on your account.'**
  String get authReauthenticateDescription;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get authSendCode;

  /// No description provided for @authVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authVerificationCode;

  /// No description provided for @authVerificationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code you received'**
  String get authVerificationCodeHint;

  /// No description provided for @authSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get authSending;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Password requirements:'**
  String get authRequirementsTitle;

  /// No description provided for @authRequirementLength.
  ///
  /// In en, this message translates to:
  /// **'8 or more characters'**
  String get authRequirementLength;

  /// No description provided for @authRequirementNumber.
  ///
  /// In en, this message translates to:
  /// **'A number'**
  String get authRequirementNumber;

  /// No description provided for @authRequirementSpecial.
  ///
  /// In en, this message translates to:
  /// **'A special character'**
  String get authRequirementSpecial;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kao ID'**
  String get authWelcome;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your details and try again.'**
  String get authLoginFailed;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account. Check your details and try again.'**
  String get authRegistrationFailed;

  /// No description provided for @authResetRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not request a reset link. Please try again.'**
  String get authResetRequestFailed;

  /// No description provided for @authVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check or resend email verification. Please try again.'**
  String get authVerificationFailed;

  /// No description provided for @authResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset your password. Try again or request a new link.'**
  String get authResetFailed;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authBootstrapFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open your account. Please try again.'**
  String get authBootstrapFailed;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out?'**
  String get signOutConfirmation;

  /// No description provided for @signOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Please try again.'**
  String get signOutFailed;

  /// No description provided for @kycLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your verification details. Please try again.'**
  String get kycLoadFailed;

  /// No description provided for @kycInformation.
  ///
  /// In en, this message translates to:
  /// **'Verification details'**
  String get kycInformation;

  /// No description provided for @kycInformationDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your identity verification details and documents.'**
  String get kycInformationDescription;

  /// No description provided for @kycPermissions.
  ///
  /// In en, this message translates to:
  /// **'Access permissions'**
  String get kycPermissions;

  /// No description provided for @kycPermissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Your access depends on your verification status.'**
  String get kycPermissionsDescription;

  /// No description provided for @accountHubIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Manage your account, one section at a time.'**
  String get accountHubIntroduction;

  /// No description provided for @personalDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetailsTitle;

  /// No description provided for @personalDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'View and edit your display name and profile photo.'**
  String get personalDetailsDescription;

  /// No description provided for @securityHubDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your account password.'**
  String get securityHubDescription;

  /// No description provided for @settingsHubDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your language and manage sign-out.'**
  String get settingsHubDescription;

  /// No description provided for @openSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Open section'**
  String get openSectionLabel;

  /// No description provided for @kycHubIntro.
  ///
  /// In en, this message translates to:
  /// **'Manage your contact verification and identity documents by section.'**
  String get kycHubIntro;

  /// No description provided for @kycContactGroup.
  ///
  /// In en, this message translates to:
  /// **'Contact verification'**
  String get kycContactGroup;

  /// No description provided for @kycDocumentsGroup.
  ///
  /// In en, this message translates to:
  /// **'Identity documents'**
  String get kycDocumentsGroup;

  /// No description provided for @kycOtherGroup.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get kycOtherGroup;

  /// No description provided for @kycEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get kycEmailTitle;

  /// No description provided for @kycPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get kycPhoneTitle;

  /// No description provided for @kycIdCardTitle.
  ///
  /// In en, this message translates to:
  /// **'National ID card'**
  String get kycIdCardTitle;

  /// No description provided for @kycPassportTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get kycPassportTitle;

  /// No description provided for @kycResidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Residence permit'**
  String get kycResidenceTitle;

  /// No description provided for @kycBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get kycBankTitle;

  /// No description provided for @kycHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification history'**
  String get kycHistoryTitle;

  /// No description provided for @kycUnknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable'**
  String get kycUnknownStatus;

  /// No description provided for @kycVerifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kycVerifiedStatus;

  /// No description provided for @kycUnverifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get kycUnverifiedStatus;

  /// No description provided for @kycPendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get kycPendingStatus;

  /// No description provided for @kycRejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get kycRejectedStatus;

  /// No description provided for @kycExpiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get kycExpiredStatus;

  /// No description provided for @kycCancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get kycCancelledStatus;

  /// No description provided for @kycNoRequest.
  ///
  /// In en, this message translates to:
  /// **'No verification request'**
  String get kycNoRequest;

  /// No description provided for @kycRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest request'**
  String get kycRequestTitle;

  /// No description provided for @kycHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'View review results and status changes.'**
  String get kycHistoryDescription;

  /// No description provided for @kycHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No verification history yet.'**
  String get kycHistoryEmpty;

  /// No description provided for @kycHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load verification history. Please try again.'**
  String get kycHistoryFailed;

  /// No description provided for @kycHistoryEvent.
  ///
  /// In en, this message translates to:
  /// **'Verification update'**
  String get kycHistoryEvent;

  /// No description provided for @kycActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Verification approved'**
  String get kycActionApprove;

  /// No description provided for @kycActionReject.
  ///
  /// In en, this message translates to:
  /// **'Verification rejected'**
  String get kycActionReject;

  /// No description provided for @kycActionReview.
  ///
  /// In en, this message translates to:
  /// **'Review started'**
  String get kycActionReview;

  /// No description provided for @kycActionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Verification submitted'**
  String get kycActionSubmit;

  /// No description provided for @kycActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get kycActionCancel;

  /// No description provided for @kycResidenceLimited.
  ///
  /// In en, this message translates to:
  /// **'View existing details — upload is not available yet'**
  String get kycResidenceLimited;

  /// No description provided for @kycRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your request. Please try again.'**
  String get kycRequestFailed;

  /// No description provided for @contactPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a Thai mobile number or an international number starting with +.'**
  String get contactPhoneInvalid;

  /// No description provided for @contactOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6–10 digit code you received.'**
  String get contactOtpInvalid;

  /// No description provided for @contactOtpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify the code. It may be incorrect or expired. Please try again.'**
  String get contactOtpFailed;

  /// No description provided for @contactSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send a code. Please wait and try again.'**
  String get contactSendFailed;

  /// No description provided for @contactStillPending.
  ///
  /// In en, this message translates to:
  /// **'The new number is not confirmed yet. Please check again.'**
  String get contactStillPending;

  /// No description provided for @contactSessionChanged.
  ///
  /// In en, this message translates to:
  /// **'Your signed-in account changed. Please reopen this page.'**
  String get contactSessionChanged;

  /// No description provided for @contactLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your details. Please check again.'**
  String get contactLoadFailed;

  /// No description provided for @contactPhoneIntro.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you can receive a code at this number. A new number is confirmed only after server verification.'**
  String get contactPhoneIntro;

  /// No description provided for @contactNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number registered'**
  String get contactNoPhone;

  /// No description provided for @contactPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'For example, 0812345678 or +66812345678'**
  String get contactPhoneFormat;

  /// No description provided for @contactWait.
  ///
  /// In en, this message translates to:
  /// **'Wait before sending again'**
  String get contactWait;

  /// No description provided for @contactSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get contactSendCode;

  /// No description provided for @contactCodeDestination.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get contactCodeDestination;

  /// No description provided for @contactOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get contactOtpLabel;

  /// No description provided for @contactVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get contactVerifyCode;

  /// No description provided for @contactExpiryHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the latest code you received. If it expires, request another when the button becomes available.'**
  String get contactExpiryHelp;

  /// No description provided for @contactEmailRefreshHelp.
  ///
  /// In en, this message translates to:
  /// **'After opening the email link, return here and check again. If the link expires, request a new email.'**
  String get contactEmailRefreshHelp;

  /// No description provided for @changeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get changeEmailTitle;

  /// No description provided for @changePhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneTitle;

  /// No description provided for @changeContactIntro.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password to request a change. Your current contact stays active until the new contact is confirmed.'**
  String get changeContactIntro;

  /// No description provided for @changeContactCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current contact'**
  String get changeContactCurrent;

  /// No description provided for @changeContactPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get changeContactPending;

  /// No description provided for @changeEmailPending.
  ///
  /// In en, this message translates to:
  /// **'Open the confirmation email. You may need to confirm both your current and new email addresses. Then select Check again.'**
  String get changeEmailPending;

  /// No description provided for @changeEmailNew.
  ///
  /// In en, this message translates to:
  /// **'New email address'**
  String get changeEmailNew;

  /// No description provided for @changePhoneNew.
  ///
  /// In en, this message translates to:
  /// **'New phone number'**
  String get changePhoneNew;

  /// No description provided for @changeContactPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changeContactPassword;

  /// No description provided for @changeContactPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Use your Kao ID password. If you only sign in with an external provider and have no password, set a password through account recovery first.'**
  String get changeContactPasswordHelp;

  /// No description provided for @changeContactRequest.
  ///
  /// In en, this message translates to:
  /// **'Request change / resend confirmation'**
  String get changeContactRequest;

  /// No description provided for @changeContactDone.
  ///
  /// In en, this message translates to:
  /// **'Your new contact has been confirmed.'**
  String get changeContactDone;

  /// No description provided for @changeContactSame.
  ///
  /// In en, this message translates to:
  /// **'Enter a different email address or phone number.'**
  String get changeContactSame;

  /// No description provided for @changeEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get changeEmailInvalid;

  /// No description provided for @changeContactPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get changeContactPasswordRequired;

  /// No description provided for @changeContactFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete the request. Check your password and verification code, then try again after the waiting period. Check the current status before requesting another change.'**
  String get changeContactFailed;

  /// No description provided for @changeContactMfaRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your registered authenticator app.'**
  String get changeContactMfaRequired;

  /// No description provided for @changeContactMfaDevice.
  ///
  /// In en, this message translates to:
  /// **'Authenticator'**
  String get changeContactMfaDevice;

  /// No description provided for @changeContactMfaCode.
  ///
  /// In en, this message translates to:
  /// **'Authenticator code'**
  String get changeContactMfaCode;

  /// No description provided for @kycNationalIdCard.
  ///
  /// In en, this message translates to:
  /// **'National ID card'**
  String get kycNationalIdCard;

  /// No description provided for @kycUseYourNationalIdCardFor.
  ///
  /// In en, this message translates to:
  /// **'Use your national ID card for identity verification.'**
  String get kycUseYourNationalIdCardFor;

  /// No description provided for @kycChooseFrontImage.
  ///
  /// In en, this message translates to:
  /// **'Choose front image'**
  String get kycChooseFrontImage;

  /// No description provided for @kycChooseBackImage.
  ///
  /// In en, this message translates to:
  /// **'Choose back image'**
  String get kycChooseBackImage;

  /// No description provided for @kycFrontImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Front image selected'**
  String get kycFrontImageSelected;

  /// No description provided for @kycBackImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Back image selected'**
  String get kycBackImageSelected;

  /// No description provided for @kycVerifyWithYourNationalIdCard.
  ///
  /// In en, this message translates to:
  /// **'Verify with your national ID card'**
  String get kycVerifyWithYourNationalIdCard;

  /// No description provided for @kycUseYourOriginalIdCardMake.
  ///
  /// In en, this message translates to:
  /// **'Use your original ID card. Make sure all information is visible, sharp and free of glare.'**
  String get kycUseYourOriginalIdCardMake;

  /// No description provided for @kycDocumentRequirements.
  ///
  /// In en, this message translates to:
  /// **'Document requirements'**
  String get kycDocumentRequirements;

  /// No description provided for @kycBothSidesMustBeClear.
  ///
  /// In en, this message translates to:
  /// **'Both sides must be clear'**
  String get kycBothSidesMustBeClear;

  /// No description provided for @kycIncludeAllInformationOnTheCard.
  ///
  /// In en, this message translates to:
  /// **'Include all information on the card'**
  String get kycIncludeAllInformationOnTheCard;

  /// No description provided for @kycAvoidGlareAndBlurredImages.
  ///
  /// In en, this message translates to:
  /// **'Avoid glare and blurred images'**
  String get kycAvoidGlareAndBlurredImages;

  /// No description provided for @kycDocumentsAreUsedForIdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Documents are used for identity verification'**
  String get kycDocumentsAreUsedForIdentityVerification;

  /// No description provided for @kycSubmitIdentityDocumentsOnlyThroughKao.
  ///
  /// In en, this message translates to:
  /// **'Submit identity documents only through Kao ID.'**
  String get kycSubmitIdentityDocumentsOnlyThroughKao;

  /// No description provided for @kycPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get kycPassport;

  /// No description provided for @kycAddYourPassportInformationForIdentity.
  ///
  /// In en, this message translates to:
  /// **'Add your passport information for identity verification'**
  String get kycAddYourPassportInformationForIdentity;

  /// No description provided for @kycPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get kycPassportNumber;

  /// No description provided for @kycEnterTheNumberPrintedOnYour.
  ///
  /// In en, this message translates to:
  /// **'Enter the number printed on your passport'**
  String get kycEnterTheNumberPrintedOnYour;

  /// No description provided for @kycForExampleAa.
  ///
  /// In en, this message translates to:
  /// **'For example, AA1234567'**
  String get kycForExampleAa;

  /// No description provided for @kycEnterYourPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your passport number'**
  String get kycEnterYourPassportNumber;

  /// No description provided for @kycInvalidPassportNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid passport number'**
  String get kycInvalidPassportNumber;

  /// No description provided for @kycDocumentDates.
  ///
  /// In en, this message translates to:
  /// **'Document dates'**
  String get kycDocumentDates;

  /// No description provided for @kycPassportIssueAndExpiryDates.
  ///
  /// In en, this message translates to:
  /// **'Passport issue and expiry dates'**
  String get kycPassportIssueAndExpiryDates;

  /// No description provided for @kycIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get kycIssueDate;

  /// No description provided for @kycExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get kycExpiryDate;

  /// No description provided for @kycPassportDocument.
  ///
  /// In en, this message translates to:
  /// **'Passport document'**
  String get kycPassportDocument;

  /// No description provided for @kycChooseAClearImageOfThe.
  ///
  /// In en, this message translates to:
  /// **'Choose a clear image of the passport information page'**
  String get kycChooseAClearImageOfThe;

  /// No description provided for @kycAddPassportImage.
  ///
  /// In en, this message translates to:
  /// **'Add passport image'**
  String get kycAddPassportImage;

  /// No description provided for @kycTapToSelectAFileFrom.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a file from your device'**
  String get kycTapToSelectAFileFrom;

  /// No description provided for @kycFileSelectedNotSubmittedYet.
  ///
  /// In en, this message translates to:
  /// **'File selected; not submitted yet'**
  String get kycFileSelectedNotSubmittedYet;

  /// No description provided for @kycChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Change file'**
  String get kycChangeFile;

  /// No description provided for @kycDocumentPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Document privacy'**
  String get kycDocumentPrivacy;

  /// No description provided for @kycDocumentsAreUsedForIdentityVerification32.
  ///
  /// In en, this message translates to:
  /// **'Documents are used for identity verification. Selecting a file does not submit it.'**
  String get kycDocumentsAreUsedForIdentityVerification32;

  /// No description provided for @kycSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get kycSaving;

  /// No description provided for @kycSavePassport.
  ///
  /// In en, this message translates to:
  /// **'Save passport'**
  String get kycSavePassport;

  /// No description provided for @kycSelectBothIssueAndExpiryDates.
  ///
  /// In en, this message translates to:
  /// **'Select both issue and expiry dates'**
  String get kycSelectBothIssueAndExpiryDates;

  /// No description provided for @kycExpiryDateMustBeAfterIssue.
  ///
  /// In en, this message translates to:
  /// **'Expiry date must be after issue date'**
  String get kycExpiryDateMustBeAfterIssue;

  /// No description provided for @kycSelectAPassportImage.
  ///
  /// In en, this message translates to:
  /// **'Select a passport image'**
  String get kycSelectAPassportImage;

  /// No description provided for @kycPleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get kycPleaseSignInAgain;

  /// No description provided for @kycPassportSaved.
  ///
  /// In en, this message translates to:
  /// **'Passport saved'**
  String get kycPassportSaved;

  /// No description provided for @kycSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get kycSelectDate;

  /// No description provided for @kycResidencePermit.
  ///
  /// In en, this message translates to:
  /// **'Residence permit'**
  String get kycResidencePermit;

  /// No description provided for @kycAResidencePermitIsUsedTo.
  ///
  /// In en, this message translates to:
  /// **'A residence permit is used to verify your right of residence.'**
  String get kycAResidencePermitIsUsedTo;

  /// No description provided for @kycStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get kycStatus;

  /// No description provided for @kycNoResidencePermitAdded.
  ///
  /// In en, this message translates to:
  /// **'No residence permit added'**
  String get kycNoResidencePermitAdded;

  /// No description provided for @kycUploadResidencePermit.
  ///
  /// In en, this message translates to:
  /// **'Upload residence permit'**
  String get kycUploadResidencePermit;

  /// No description provided for @kycFrontOfCard.
  ///
  /// In en, this message translates to:
  /// **'Front of card'**
  String get kycFrontOfCard;

  /// No description provided for @kycBackOfCard.
  ///
  /// In en, this message translates to:
  /// **'Back of card'**
  String get kycBackOfCard;

  /// No description provided for @kycToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get kycToday;

  /// No description provided for @kycYouCanChooseAnotherFileTo.
  ///
  /// In en, this message translates to:
  /// **'You can choose another file to replace this selection'**
  String get kycYouCanChooseAnotherFileTo;

  /// No description provided for @kycSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get kycSelected;

  /// No description provided for @kycUploadRequirements.
  ///
  /// In en, this message translates to:
  /// **'Upload requirements'**
  String get kycUploadRequirements;

  /// No description provided for @kycCheckTheInformationBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Check the information before submitting'**
  String get kycCheckTheInformationBeforeSubmitting;

  /// No description provided for @kycChooseImagesOfBothSidesOf.
  ///
  /// In en, this message translates to:
  /// **'Choose images of both sides of your national ID card'**
  String get kycChooseImagesOfBothSidesOf;

  /// No description provided for @kycJpgAndPngSupported.
  ///
  /// In en, this message translates to:
  /// **'JPG and PNG supported'**
  String get kycJpgAndPngSupported;

  /// No description provided for @kycCheckThatTheImageIsClear.
  ///
  /// In en, this message translates to:
  /// **'Check that the image is clear before selecting it'**
  String get kycCheckThatTheImageIsClear;

  /// No description provided for @kycSelectingAFileDoesNotUpload.
  ///
  /// In en, this message translates to:
  /// **'Selecting a file does not upload or submit it'**
  String get kycSelectingAFileDoesNotUpload;

  /// No description provided for @kycFileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get kycFileName;

  /// No description provided for @kycFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get kycFileSize;

  /// No description provided for @kycUploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded on'**
  String get kycUploadedOn;

  /// No description provided for @kycChooseDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose document'**
  String get kycChooseDocument;

  /// No description provided for @kycTapToSelectAFileFrom61.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a file from your device'**
  String get kycTapToSelectAFileFrom61;

  /// No description provided for @kycChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get kycChooseFile;

  /// No description provided for @kycProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get kycProcessing;

  /// No description provided for @kycCheckThatTheImageIsClear64.
  ///
  /// In en, this message translates to:
  /// **'Check that the image is clear before selecting it'**
  String get kycCheckThatTheImageIsClear64;

  /// No description provided for @kycSelectingAFileDoesNotUpload65.
  ///
  /// In en, this message translates to:
  /// **'Selecting a file does not upload or submit it'**
  String get kycSelectingAFileDoesNotUpload65;

  /// No description provided for @kycApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get kycApproved;

  /// No description provided for @kycAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get kycAwaitingReview;

  /// No description provided for @kycRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kycRejected;

  /// No description provided for @kycNoDocumentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No document submitted'**
  String get kycNoDocumentSubmitted;

  /// No description provided for @kycBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get kycBankAccount;

  /// No description provided for @kycAddingBankAccountsIsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Adding bank accounts is not available yet'**
  String get kycAddingBankAccountsIsNotAvailable;

  /// No description provided for @kycManagingBankAccountsIsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Managing bank accounts is not available yet'**
  String get kycManagingBankAccountsIsNotAvailable;

  /// No description provided for @kycBankAccountVerification.
  ///
  /// In en, this message translates to:
  /// **'Bank account verification'**
  String get kycBankAccountVerification;

  /// No description provided for @kycViewBankAccountVerificationForKao.
  ///
  /// In en, this message translates to:
  /// **'View bank account verification for Kao Ecosystem services'**
  String get kycViewBankAccountVerificationForKao;

  /// No description provided for @kycCheckAccountStatusAndItsMatch.
  ///
  /// In en, this message translates to:
  /// **'Check account status and its match with KYC information'**
  String get kycCheckAccountStatusAndItsMatch;

  /// No description provided for @kycLoadingBankAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading bank account details…'**
  String get kycLoadingBankAccountDetails;

  /// No description provided for @kycCouldNotLoadTheDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load the details'**
  String get kycCouldNotLoadTheDetails;

  /// No description provided for @kycTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get kycTryAgain;

  /// No description provided for @kycNoBankAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'No bank account added'**
  String get kycNoBankAccountAdded;

  /// No description provided for @kycBankAccountRegistrationIsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Bank account registration is not available yet.'**
  String get kycBankAccountRegistrationIsNotAvailable;

  /// No description provided for @kycAddBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Add bank account'**
  String get kycAddBankAccount;

  /// No description provided for @kycAccountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account holder name'**
  String get kycAccountHolderName;

  /// No description provided for @kycPrimaryAccount.
  ///
  /// In en, this message translates to:
  /// **'Primary account'**
  String get kycPrimaryAccount;

  /// No description provided for @kycAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get kycAccountNumber;

  /// No description provided for @kycVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get kycVerificationStatus;

  /// No description provided for @kycNameMatchWithKyc.
  ///
  /// In en, this message translates to:
  /// **'Name match with KYC'**
  String get kycNameMatchWithKyc;

  /// No description provided for @kycRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get kycRejectionReason;

  /// No description provided for @kycVerifiedBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Verified bank account'**
  String get kycVerifiedBankAccount;

  /// No description provided for @kycSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get kycSecurity;

  /// No description provided for @kycTheAccountIsVerifiedAndIts.
  ///
  /// In en, this message translates to:
  /// **'The account is verified and its holder name matches the verified identity'**
  String get kycTheAccountIsVerifiedAndIts;

  /// No description provided for @kycTheAccountHolderNameMustMatch.
  ///
  /// In en, this message translates to:
  /// **'The account holder name must match the verified identity before the account can be trusted'**
  String get kycTheAccountHolderNameMustMatch;

  /// No description provided for @kycCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get kycCheckAgain;

  /// No description provided for @kycManageBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage bank account'**
  String get kycManageBankAccount;

  /// No description provided for @kycVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kycVerified;

  /// No description provided for @kycTheBankAccountHasBeenVerified.
  ///
  /// In en, this message translates to:
  /// **'The bank account has been verified'**
  String get kycTheBankAccountHasBeenVerified;

  /// No description provided for @kycUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get kycUnderReview;

  /// No description provided for @kycTheBankAccountIsBeingReviewed.
  ///
  /// In en, this message translates to:
  /// **'The bank account is being reviewed'**
  String get kycTheBankAccountIsBeingReviewed;

  /// No description provided for @kycAdditionalReview.
  ///
  /// In en, this message translates to:
  /// **'Additional review'**
  String get kycAdditionalReview;

  /// No description provided for @kycFurtherReviewIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Further review is required'**
  String get kycFurtherReviewIsRequired;

  /// No description provided for @kycNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get kycNotVerified;

  /// No description provided for @kycTheBankAccountDidNotPass.
  ///
  /// In en, this message translates to:
  /// **'The bank account did not pass verification'**
  String get kycTheBankAccountDidNotPass;

  /// No description provided for @kycExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get kycExpired;

  /// No description provided for @kycTheBankAccountVerificationHasExpired.
  ///
  /// In en, this message translates to:
  /// **'The bank account verification has expired'**
  String get kycTheBankAccountVerificationHasExpired;

  /// No description provided for @kycVerificationNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Verification not started'**
  String get kycVerificationNotStarted;

  /// No description provided for @kycTheBankAccountHasNotEntered.
  ///
  /// In en, this message translates to:
  /// **'The bank account has not entered verification'**
  String get kycTheBankAccountHasNotEntered;

  /// No description provided for @kycAccountNameMatchesKyc.
  ///
  /// In en, this message translates to:
  /// **'Account name matches KYC'**
  String get kycAccountNameMatchesKyc;

  /// No description provided for @kycTheAccountHolderNameMatchesThe.
  ///
  /// In en, this message translates to:
  /// **'The account holder name matches the verified identity'**
  String get kycTheAccountHolderNameMatchesThe;

  /// No description provided for @kycAccountNameDoesNotMatchKyc.
  ///
  /// In en, this message translates to:
  /// **'Account name does not match KYC'**
  String get kycAccountNameDoesNotMatchKyc;

  /// No description provided for @kycTheAccountHolderNameDiffersFrom.
  ///
  /// In en, this message translates to:
  /// **'The account holder name differs from the verified identity'**
  String get kycTheAccountHolderNameDiffersFrom;

  /// No description provided for @kycReviewingAccountName.
  ///
  /// In en, this message translates to:
  /// **'Reviewing account name'**
  String get kycReviewingAccountName;

  /// No description provided for @kycMoreInformationMustBeReviewedBefore.
  ///
  /// In en, this message translates to:
  /// **'More information must be reviewed before a decision'**
  String get kycMoreInformationMustBeReviewedBefore;

  /// No description provided for @kycAwaitingNameCheck.
  ///
  /// In en, this message translates to:
  /// **'Awaiting name check'**
  String get kycAwaitingNameCheck;

  /// No description provided for @kycTheAccountHolderNameWillBe.
  ///
  /// In en, this message translates to:
  /// **'The account holder name will be checked against KYC'**
  String get kycTheAccountHolderNameWillBe;

  /// No description provided for @kycDocumentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the document. Please try again.'**
  String get kycDocumentSaveFailed;

  /// No description provided for @contactVerifiedHelp.
  ///
  /// In en, this message translates to:
  /// **'This contact is verified. You can request a change below.'**
  String get contactVerifiedHelp;

  /// No description provided for @kycRejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kycRejectedLabel;

  /// No description provided for @kycNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get kycNotAdded;

  /// No description provided for @kycExpiryDateNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Expiry date not provided'**
  String get kycExpiryDateNotProvided;

  /// No description provided for @kycSelectPassportExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select passport expiry date'**
  String get kycSelectPassportExpiryDate;

  /// No description provided for @kycCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get kycCancel;

  /// No description provided for @kycSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get kycSelect;

  /// No description provided for @kycNoBankAccountAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'No bank account added'**
  String get kycNoBankAccountAddedLabel;

  /// No description provided for @kycAdditionalReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional review'**
  String get kycAdditionalReviewLabel;

  /// No description provided for @kycNotVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get kycNotVerifiedLabel;

  /// No description provided for @kycNameMatchesKyc.
  ///
  /// In en, this message translates to:
  /// **'Name matches KYC'**
  String get kycNameMatchesKyc;

  /// No description provided for @kycNameDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Name does not match'**
  String get kycNameDoesNotMatch;

  /// No description provided for @kycAdditionalNameReview.
  ///
  /// In en, this message translates to:
  /// **'Additional name review'**
  String get kycAdditionalNameReview;

  /// No description provided for @kycAwaitingKycNameCheck.
  ///
  /// In en, this message translates to:
  /// **'Awaiting KYC name check'**
  String get kycAwaitingKycNameCheck;

  /// No description provided for @kycVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get kycVerifiedLabel;

  /// No description provided for @kycVerificationHistory.
  ///
  /// In en, this message translates to:
  /// **'Verification history'**
  String get kycVerificationHistory;

  /// No description provided for @kycReviewVerificationResultsAndChanges.
  ///
  /// In en, this message translates to:
  /// **'Review verification results and changes'**
  String get kycReviewVerificationResultsAndChanges;

  /// No description provided for @kycIdentityVerificationProgress.
  ///
  /// In en, this message translates to:
  /// **'Identity verification progress'**
  String get kycIdentityVerificationProgress;

  /// No description provided for @kycYourIdentityVerificationIsComplete.
  ///
  /// In en, this message translates to:
  /// **'Your identity verification is complete'**
  String get kycYourIdentityVerificationIsComplete;

  /// No description provided for @kycVerifyAdditionalInformationToCompleteYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify additional information to complete your identity verification'**
  String get kycVerifyAdditionalInformationToCompleteYourIdentity;

  /// No description provided for @kycVerificationComplete.
  ///
  /// In en, this message translates to:
  /// **'Verification complete'**
  String get kycVerificationComplete;

  /// No description provided for @kycInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get kycInProgress;

  /// No description provided for @kycChooseAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get kycChooseAnotherFile;

  /// No description provided for @kycEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get kycEmail;

  /// No description provided for @kycNotVerifiedLabelText.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get kycNotVerifiedLabelText;

  /// No description provided for @kycPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get kycPhoneNumber;

  /// No description provided for @kycInformationRecorded.
  ///
  /// In en, this message translates to:
  /// **'Information recorded'**
  String get kycInformationRecorded;

  /// No description provided for @kycAccessPermissions.
  ///
  /// In en, this message translates to:
  /// **'Access permissions'**
  String get kycAccessPermissions;

  /// No description provided for @kycIdentityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity verified'**
  String get kycIdentityVerified;

  /// No description provided for @kycIdentityNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity not verified'**
  String get kycIdentityNotVerified;

  /// No description provided for @kycAccountCompleteness.
  ///
  /// In en, this message translates to:
  /// **'Account completeness'**
  String get kycAccountCompleteness;

  /// No description provided for @kycYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get kycYourAccount;

  /// No description provided for @kycIdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get kycIdentityVerification;

  /// No description provided for @kycAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account security'**
  String get kycAccountSecurity;

  /// No description provided for @kycDocumentPrivacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Document privacy'**
  String get kycDocumentPrivacyLabel;

  /// No description provided for @kycSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get kycSignIn;

  /// No description provided for @kycEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get kycEditProfile;

  /// No description provided for @kycVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get kycVerifyEmail;

  /// No description provided for @kycVerifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify phone number'**
  String get kycVerifyPhoneNumber;

  /// No description provided for @kycBuyItems.
  ///
  /// In en, this message translates to:
  /// **'Buy items'**
  String get kycBuyItems;

  /// No description provided for @kycSellItems.
  ///
  /// In en, this message translates to:
  /// **'Sell items'**
  String get kycSellItems;

  /// No description provided for @kycWithdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'Withdraw funds'**
  String get kycWithdrawFunds;

  /// No description provided for @kycExpiresOnDate.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String kycExpiresOnDate(String date);

  /// No description provided for @idViewDocument.
  ///
  /// In en, this message translates to:
  /// **'View document'**
  String get idViewDocument;

  /// No description provided for @idPreviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this image. Please try again.'**
  String get idPreviewFailed;

  /// No description provided for @idFileInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid JPG or PNG image, 100 pixels or larger on each side, at most 24 megapixels and 10 MB.'**
  String get idFileInvalid;

  /// No description provided for @idFormInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name, 13-digit ID number, valid dates and both card images.'**
  String get idFormInvalid;

  /// No description provided for @idSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted for review. Submission does not mean verification is approved.'**
  String get idSubmitted;

  /// No description provided for @idSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission could not be confirmed. Check again or retry the same submission.'**
  String get idSaveFailed;

  /// No description provided for @idIntro.
  ///
  /// In en, this message translates to:
  /// **'Submit your own national ID card for review. Use clear images with all corners visible.'**
  String get idIntro;

  /// No description provided for @idViewFront.
  ///
  /// In en, this message translates to:
  /// **'View front of card'**
  String get idViewFront;

  /// No description provided for @idViewBack.
  ///
  /// In en, this message translates to:
  /// **'View back of card'**
  String get idViewBack;

  /// No description provided for @idFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name on card'**
  String get idFullName;

  /// No description provided for @idNumber.
  ///
  /// In en, this message translates to:
  /// **'National ID number (13 digits)'**
  String get idNumber;

  /// No description provided for @idLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime card (no expiry date)'**
  String get idLifetime;

  /// No description provided for @idFileHelp.
  ///
  /// In en, this message translates to:
  /// **'JPG/PNG, up to 10 MB per image. Images are stored privately. Keep this page open until submission finishes.'**
  String get idFileHelp;

  /// No description provided for @idSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get idSubmit;

  /// No description provided for @idRetrySubmission.
  ///
  /// In en, this message translates to:
  /// **'Retry this submission'**
  String get idRetrySubmission;

  /// No description provided for @idLegacyRecord.
  ///
  /// In en, this message translates to:
  /// **'An existing document is on file. Its original workflow is preserved; contact support if its images cannot be opened.'**
  String get idLegacyRecord;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review identity documents'**
  String get reviewTitle;

  /// No description provided for @reviewQueueHelp.
  ///
  /// In en, this message translates to:
  /// **'Oldest 50 pending requests. Refresh after reviewing to load the next requests. You cannot review your own documents.'**
  String get reviewQueueHelp;

  /// No description provided for @reviewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load requests. Check your reviewer permission and try again.'**
  String get reviewLoadFailed;

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'No requests are available for you to review. Your own request must be reviewed by another officer.'**
  String get reviewEmpty;

  /// No description provided for @reviewApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve request'**
  String get reviewApprove;

  /// No description provided for @reviewReject.
  ///
  /// In en, this message translates to:
  /// **'Reject and request correction'**
  String get reviewReject;

  /// No description provided for @reviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record this decision? It will update the account and document status and create an audit record.'**
  String get reviewConfirm;

  /// No description provided for @reviewChecked.
  ///
  /// In en, this message translates to:
  /// **'I checked all required images, holder details, validity and legibility.'**
  String get reviewChecked;

  /// No description provided for @reviewReason.
  ///
  /// In en, this message translates to:
  /// **'Review notes / reason (required for rejection)'**
  String get reviewReason;

  /// No description provided for @reviewActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this action. Rejection needs a reason of at least 3 characters. Refresh the queue to check whether a decision was already saved.'**
  String get reviewActionFailed;

  /// No description provided for @issueLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your Kao ID. Please try again.'**
  String get issueLoadFailed;

  /// No description provided for @issueActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get issueActive;

  /// No description provided for @issueInactive.
  ///
  /// In en, this message translates to:
  /// **'This Kao ID is currently unavailable. Contact support.'**
  String get issueInactive;

  /// No description provided for @issueReady.
  ///
  /// In en, this message translates to:
  /// **'Identity review approved. You can request your Kao ID.'**
  String get issueReady;

  /// No description provided for @issueAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Your Kao ID becomes available after identity review is approved.'**
  String get issueAwaitingReview;

  /// No description provided for @issueRequest.
  ///
  /// In en, this message translates to:
  /// **'Request my Kao ID'**
  String get issueRequest;

  /// No description provided for @issueFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not issue your Kao ID. Check again; approval and account status are verified by the server.'**
  String get issueFailed;

  /// No description provided for @reviewNoPermission.
  ///
  /// In en, this message translates to:
  /// **'This account does not have active KYC reviewer permission.'**
  String get reviewNoPermission;

  /// No description provided for @reviewAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'This request has already been reviewed. Return to the queue and refresh.'**
  String get reviewAlreadyDone;

  /// No description provided for @reviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This request is unavailable or belongs to your own account. Return to the queue.'**
  String get reviewUnavailable;

  /// No description provided for @reviewMissingFiles.
  ///
  /// In en, this message translates to:
  /// **'Required evidence is missing. Return the request for correction.'**
  String get reviewMissingFiles;

  /// No description provided for @reviewInvalidDocument.
  ///
  /// In en, this message translates to:
  /// **'The document is incomplete, expired or not ready for approval. Check the details.'**
  String get reviewInvalidDocument;

  /// No description provided for @reviewDuplicateDocument.
  ///
  /// In en, this message translates to:
  /// **'This document number is already approved for another account. Refer this case to the administrator.'**
  String get reviewDuplicateDocument;

  /// No description provided for @reviewReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a rejection reason of at least 3 characters.'**
  String get reviewReasonRequired;

  /// No description provided for @idFirstName.
  ///
  /// In en, this message translates to:
  /// **'Given name (as shown on your ID card)'**
  String get idFirstName;

  /// No description provided for @idLastName.
  ///
  /// In en, this message translates to:
  /// **'Surname (as shown on your ID card)'**
  String get idLastName;

  /// No description provided for @idFirstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your given name.'**
  String get idFirstNameRequired;

  /// No description provided for @idLastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your surname.'**
  String get idLastNameRequired;

  /// No description provided for @idNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Given name and surname must total no more than 200 characters.'**
  String get idNameTooLong;

  /// No description provided for @idNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the 13-digit ID number.'**
  String get idNumberRequired;

  /// No description provided for @idIssuedRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the issue date.'**
  String get idIssuedRequired;

  /// No description provided for @idExpiryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select an expiry date after the issue date, or select a lifetime card.'**
  String get idExpiryRequired;

  /// No description provided for @idFrontRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the front image of your ID card.'**
  String get idFrontRequired;

  /// No description provided for @idBackRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the back image of your ID card.'**
  String get idBackRequired;

  /// No description provided for @idCheckHighlightedFields.
  ///
  /// In en, this message translates to:
  /// **'Document not sent. Check the listed fields and images.'**
  String get idCheckHighlightedFields;

  /// No description provided for @idSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting your document. Please wait.'**
  String get idSubmitting;

  /// No description provided for @passportIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the details exactly as shown on your passport and attach a clear image of its personal information page.'**
  String get passportIntro;

  /// No description provided for @passportOtherPending.
  ///
  /// In en, this message translates to:
  /// **'You already have a verification request awaiting review. Complete that request before submitting another document.'**
  String get passportOtherPending;

  /// No description provided for @passportCompleteForm.
  ///
  /// In en, this message translates to:
  /// **'Document not sent. Complete the required fields, dates and passport image.'**
  String get passportCompleteForm;

  /// No description provided for @passportRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get passportRequired;

  /// No description provided for @passportSingleName.
  ///
  /// In en, this message translates to:
  /// **'My passport has only one name (no separate given name or surname).'**
  String get passportSingleName;

  /// No description provided for @passportOnlyName.
  ///
  /// In en, this message translates to:
  /// **'Name exactly as shown on the passport'**
  String get passportOnlyName;

  /// No description provided for @passportGiven.
  ///
  /// In en, this message translates to:
  /// **'Given name(s), including middle names'**
  String get passportGiven;

  /// No description provided for @passportFamily.
  ///
  /// In en, this message translates to:
  /// **'Family name / Surname'**
  String get passportFamily;

  /// No description provided for @passportFamilyFirst.
  ///
  /// In en, this message translates to:
  /// **'Show family name before given name'**
  String get passportFamilyFirst;

  /// No description provided for @passportIssuingCountry.
  ///
  /// In en, this message translates to:
  /// **'Issuing country or authority, as shown on the passport'**
  String get passportIssuingCountry;

  /// No description provided for @passportBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get passportBirth;

  /// No description provided for @passportDatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose all dates. Issue date must not precede birth, and expiry must be after issue.'**
  String get passportDatesInvalid;

  /// No description provided for @passportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit passport for review'**
  String get passportSubmit;

  /// No description provided for @passportPendingHelp.
  ///
  /// In en, this message translates to:
  /// **'Submission is not approval. Your document must be reviewed before it can verify your identity.'**
  String get passportPendingHelp;

  /// No description provided for @passportCountryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the full issuing country or authority name.'**
  String get passportCountryInvalid;

  /// No description provided for @residenceIntro.
  ///
  /// In en, this message translates to:
  /// **'Submit a residence permit only when it is needed for your case. Enter the details as shown on the document. This is supporting evidence, not automatic identity approval.'**
  String get residenceIntro;

  /// No description provided for @residenceOtherPending.
  ///
  /// In en, this message translates to:
  /// **'You already have a verification request awaiting review. Wait for its outcome before submitting another document.'**
  String get residenceOtherPending;

  /// No description provided for @residenceCompleteForm.
  ///
  /// In en, this message translates to:
  /// **'Document not sent. Check the required fields, dates and images.'**
  String get residenceCompleteForm;

  /// No description provided for @residenceSingleName.
  ///
  /// In en, this message translates to:
  /// **'The document shows a single name only.'**
  String get residenceSingleName;

  /// No description provided for @residenceOnlyName.
  ///
  /// In en, this message translates to:
  /// **'Name as shown on the document'**
  String get residenceOnlyName;

  /// No description provided for @residenceIssuingCountry.
  ///
  /// In en, this message translates to:
  /// **'Issuing country or authority'**
  String get residenceIssuingCountry;

  /// No description provided for @residenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Residence permit number'**
  String get residenceNumber;

  /// No description provided for @residenceNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry date is shown on the document'**
  String get residenceNoExpiry;

  /// No description provided for @residencePendingHelp.
  ///
  /// In en, this message translates to:
  /// **'Submitting a residence permit does not confirm your identity or create a Kao ID. It requires review by an authorized officer.'**
  String get residencePendingHelp;

  /// No description provided for @residenceDatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose the issue date and an expiry date after it, or confirm that no expiry is shown.'**
  String get residenceDatesInvalid;

  /// No description provided for @residenceSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit residence permit for review'**
  String get residenceSubmit;

  /// No description provided for @residenceCardFormat.
  ///
  /// In en, this message translates to:
  /// **'Card with front and back'**
  String get residenceCardFormat;

  /// No description provided for @residenceTwoSides.
  ///
  /// In en, this message translates to:
  /// **'Attach both sides, including any notes on the back.'**
  String get residenceTwoSides;

  /// No description provided for @residenceOnePage.
  ///
  /// In en, this message translates to:
  /// **'Single-page document: attach the complete page.'**
  String get residenceOnePage;

  /// No description provided for @residenceFront.
  ///
  /// In en, this message translates to:
  /// **'Front of the residence card'**
  String get residenceFront;

  /// No description provided for @residenceBack.
  ///
  /// In en, this message translates to:
  /// **'Back of the residence card'**
  String get residenceBack;

  /// No description provided for @residencePage.
  ///
  /// In en, this message translates to:
  /// **'Complete residence permit page'**
  String get residencePage;

  /// No description provided for @residenceViewFront.
  ///
  /// In en, this message translates to:
  /// **'View front / document page'**
  String get residenceViewFront;

  /// No description provided for @residenceViewBack.
  ///
  /// In en, this message translates to:
  /// **'View back'**
  String get residenceViewBack;

  /// No description provided for @residenceImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose an image for this side or page.'**
  String get residenceImageRequired;

  /// No description provided for @bankSubmissionIntro.
  ///
  /// In en, this message translates to:
  /// **'Add a personal bank account in Thailand (THB) for review. Adding an account does not verify it or enable payments.'**
  String get bankSubmissionIntro;

  /// No description provided for @bankPendingHelp.
  ///
  /// In en, this message translates to:
  /// **'This account is awaiting review. Wait for the result before submitting another account. Bank review is separate from identity-document review.'**
  String get bankPendingHelp;

  /// No description provided for @bankDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This account already exists. Refresh the account list.'**
  String get bankDuplicate;

  /// No description provided for @bankCompleteForm.
  ///
  /// In en, this message translates to:
  /// **'Check the account details and attach evidence before submitting.'**
  String get bankCompleteForm;

  /// No description provided for @bankEvidence.
  ///
  /// In en, this message translates to:
  /// **'Bank account evidence'**
  String get bankEvidence;

  /// No description provided for @bankEvidenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Attach a passbook page or account confirmation showing the bank, account holder and account number clearly. Use an account in your own name.'**
  String get bankEvidenceHelp;

  /// No description provided for @bankViewEvidence.
  ///
  /// In en, this message translates to:
  /// **'View submitted evidence'**
  String get bankViewEvidence;

  /// No description provided for @bankInstitutionName.
  ///
  /// In en, this message translates to:
  /// **'Bank name as shown on the document'**
  String get bankInstitutionName;

  /// No description provided for @bankHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account holder name as shown on the bank document'**
  String get bankHolderName;

  /// No description provided for @bankBranchOptional.
  ///
  /// In en, this message translates to:
  /// **'Branch (optional)'**
  String get bankBranchOptional;

  /// No description provided for @bankAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get bankAccountType;

  /// No description provided for @bankSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get bankSavings;

  /// No description provided for @bankCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get bankCurrent;

  /// No description provided for @bankNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 6–20 digits, including any leading zeros.'**
  String get bankNumberInvalid;

  /// No description provided for @bankEvidenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Attach bank account evidence.'**
  String get bankEvidenceRequired;

  /// No description provided for @bankSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit account for review'**
  String get bankSubmitReview;

  /// No description provided for @bankResubmitHelp.
  ///
  /// In en, this message translates to:
  /// **'You can submit corrected details and evidence for a new review. The previous record is retained.'**
  String get bankResubmitHelp;

  /// No description provided for @bankRetryHelp.
  ///
  /// In en, this message translates to:
  /// **'These details are retained for retry. Submit again or refresh the list to check whether the save completed.'**
  String get bankRetryHelp;

  /// No description provided for @bankNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No bank accounts yet'**
  String get bankNoAccounts;

  /// No description provided for @bankAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add bank account'**
  String get bankAddAccount;

  /// No description provided for @bankAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Bank account number'**
  String get bankAccountNumber;

  /// No description provided for @adminMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'User accounts'**
  String get adminMembersTitle;

  /// No description provided for @adminReadOnly.
  ///
  /// In en, this message translates to:
  /// **'View member information. Searches are recorded.'**
  String get adminReadOnly;

  /// No description provided for @adminSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Exact email, account ID or Kao ID'**
  String get adminSearchHint;

  /// No description provided for @adminSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get adminSearch;

  /// No description provided for @adminSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching member found'**
  String get adminSearchEmpty;

  /// No description provided for @adminAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view members'**
  String get adminAccessDenied;

  /// No description provided for @adminUserId.
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get adminUserId;

  /// No description provided for @adminAccountState.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get adminAccountState;

  /// No description provided for @adminIdentityState.
  ///
  /// In en, this message translates to:
  /// **'Kao ID status'**
  String get adminIdentityState;

  /// No description provided for @adminNotIssued.
  ///
  /// In en, this message translates to:
  /// **'Not issued'**
  String get adminNotIssued;

  /// No description provided for @adminActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminActive;

  /// No description provided for @adminSuspended.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get adminSuspended;

  /// No description provided for @adminClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get adminClosed;

  /// No description provided for @staffActor.
  ///
  /// In en, this message translates to:
  /// **'Performed by'**
  String get staffActor;

  /// No description provided for @staffAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get staffAdmin;

  /// No description provided for @staffAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign role'**
  String get staffAssign;

  /// No description provided for @staffAssignments.
  ///
  /// In en, this message translates to:
  /// **'Staff assignments'**
  String get staffAssignments;

  /// No description provided for @staffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm this role change? Assignment does not approve KYC.'**
  String get staffConfirm;

  /// No description provided for @staffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get staffEmpty;

  /// No description provided for @staffHelp.
  ///
  /// In en, this message translates to:
  /// **'Only the Owner can assign or revoke roles. New assignments have no expiry; revoke them when no longer needed.'**
  String get staffHelp;

  /// No description provided for @staffHistory.
  ///
  /// In en, this message translates to:
  /// **'Assignment history'**
  String get staffHistory;

  /// No description provided for @staffInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive or expired'**
  String get staffInactive;

  /// No description provided for @staffKycRequired.
  ///
  /// In en, this message translates to:
  /// **'This role requires approved KYC and an active Kao ID.'**
  String get staffKycRequired;

  /// No description provided for @staffLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest 100 records'**
  String get staffLatest;

  /// No description provided for @staffNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'Until revoked'**
  String get staffNoExpiry;

  /// No description provided for @staffPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permission codes'**
  String get staffPermissions;

  /// No description provided for @staffReviewScope.
  ///
  /// In en, this message translates to:
  /// **'Can review national ID, passport, residence and bank requests from other accounts. Residence or bank approval alone does not issue a Kao ID.'**
  String get staffReviewScope;

  /// No description provided for @staffReviewer.
  ///
  /// In en, this message translates to:
  /// **'KYC officer'**
  String get staffReviewer;

  /// No description provided for @staffRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke role'**
  String get staffRevoke;

  /// No description provided for @staffRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffRole;

  /// No description provided for @staffSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super administrator'**
  String get staffSuperAdmin;

  /// No description provided for @staffSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get staffSupport;

  /// No description provided for @staffTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select an active account with verified email. The Owner cannot be assigned here.'**
  String get staffTargetInvalid;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff management'**
  String get staffTitle;

  /// No description provided for @reviewIdentityName.
  ///
  /// In en, this message translates to:
  /// **'Verified identity name'**
  String get reviewIdentityName;

  /// No description provided for @reviewBankNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Approve identity verification first. The bank holder name must match a valid approved identity document.'**
  String get reviewBankNameRequired;

  /// No description provided for @adminHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Kao ID administration'**
  String get adminHubTitle;

  /// No description provided for @adminHubScope.
  ///
  /// In en, this message translates to:
  /// **'Manage central accounts and identity verification. Trading is managed in Secondhand.'**
  String get adminHubScope;

  /// No description provided for @adminHubStaffHelp.
  ///
  /// In en, this message translates to:
  /// **'Assign or revoke staff roles and view the action history.'**
  String get adminHubStaffHelp;

  /// No description provided for @adminHubReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Review evidence and decide requests from other accounts. You cannot review your own request.'**
  String get adminHubReviewHelp;

  /// No description provided for @accountStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Central account status'**
  String get accountStateTitle;

  /// No description provided for @accountSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend account'**
  String get accountSuspend;

  /// No description provided for @accountRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore account'**
  String get accountRestore;

  /// No description provided for @accountStateHelp.
  ///
  /// In en, this message translates to:
  /// **'Restrict profile changes and identity-verification actions while preserving existing KYC and Kao ID. A reason is required. Suspension is not account closure or KYC revocation.'**
  String get accountStateHelp;

  /// No description provided for @accountStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: access may be denied, the account protected, or its status changed. Search for the account again before retrying.'**
  String get accountStateFailed;

  /// No description provided for @accountStateHistory.
  ///
  /// In en, this message translates to:
  /// **'Latest 50 status events'**
  String get accountStateHistory;

  /// No description provided for @accountStateActor.
  ///
  /// In en, this message translates to:
  /// **'Performed by'**
  String get accountStateActor;

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get noticeTitle;

  /// No description provided for @noticeHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows the latest 30 notifications. Tap the message to mark it as read. Use the open button on the right for current details; access is checked again.'**
  String get noticeHelp;

  /// No description provided for @noticeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noticeEmpty;

  /// No description provided for @noticeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Identity request received'**
  String get noticeSubmitted;

  /// No description provided for @noticeApproved.
  ///
  /// In en, this message translates to:
  /// **'Identity request approved'**
  String get noticeApproved;

  /// No description provided for @noticeRejected.
  ///
  /// In en, this message translates to:
  /// **'Identity request rejected. View the reason in your history.'**
  String get noticeRejected;

  /// No description provided for @noticeBankApproved.
  ///
  /// In en, this message translates to:
  /// **'Bank account verified'**
  String get noticeBankApproved;

  /// No description provided for @noticeBankRejected.
  ///
  /// In en, this message translates to:
  /// **'Bank review rejected. View the reason in your history.'**
  String get noticeBankRejected;

  /// No description provided for @noticeSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account actions suspended'**
  String get noticeSuspended;

  /// No description provided for @noticeRestored.
  ///
  /// In en, this message translates to:
  /// **'Account access restored'**
  String get noticeRestored;

  /// No description provided for @noticeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your account has an update'**
  String get noticeUpdated;

  /// No description provided for @lifeTitle.
  ///
  /// In en, this message translates to:
  /// **'Account closure and return'**
  String get lifeTitle;

  /// No description provided for @lifeHelp.
  ///
  /// In en, this message translates to:
  /// **'Submitting a request does not close your account immediately. You can cancel while it is pending. Recovering a previous Kao ID requires identity verification; matching an email or phone number is not enough. Staff permissions are not restored automatically.'**
  String get lifeHelp;

  /// No description provided for @lifeOwner.
  ///
  /// In en, this message translates to:
  /// **'The Owner cannot request account closure from this page.'**
  String get lifeOwner;

  /// No description provided for @lifeClose.
  ///
  /// In en, this message translates to:
  /// **'Request account closure'**
  String get lifeClose;

  /// No description provided for @lifeRecover.
  ///
  /// In en, this message translates to:
  /// **'Request to return'**
  String get lifeRecover;

  /// No description provided for @lifePending.
  ///
  /// In en, this message translates to:
  /// **'Pending processing'**
  String get lifePending;

  /// No description provided for @lifeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get lifeCancelled;

  /// No description provided for @adminCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get adminCopy;

  /// No description provided for @adminAccountCode.
  ///
  /// In en, this message translates to:
  /// **'Account reference'**
  String get adminAccountCode;

  /// No description provided for @adminActorRole.
  ///
  /// In en, this message translates to:
  /// **'Role at the time of action'**
  String get adminActorRole;

  /// No description provided for @adminOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get adminOwner;

  /// No description provided for @ownerRequests.
  ///
  /// In en, this message translates to:
  /// **'Account requests'**
  String get ownerRequests;

  /// No description provided for @ownerRequestsHelp.
  ///
  /// In en, this message translates to:
  /// **'Review closure and return requests, reasons and recorded history.'**
  String get ownerRequestsHelp;

  /// No description provided for @adminMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get adminMore;

  /// No description provided for @lifeRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get lifeRejected;

  /// No description provided for @lifeReject.
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get lifeReject;

  /// No description provided for @lifeChecks.
  ///
  /// In en, this message translates to:
  /// **'Account checks'**
  String get lifeChecks;

  /// No description provided for @lifeChecksHelp.
  ///
  /// In en, this message translates to:
  /// **'Counts below come from current tables. Total records do not mean outstanding obligations have been cleared.'**
  String get lifeChecksHelp;

  /// No description provided for @lifeOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders: total records'**
  String get lifeOrders;

  /// No description provided for @lifeDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes: total records'**
  String get lifeDisputes;

  /// No description provided for @lifeKycPending.
  ///
  /// In en, this message translates to:
  /// **'Pending identity reviews'**
  String get lifeKycPending;

  /// No description provided for @lifeWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet: balance / held balance'**
  String get lifeWallet;

  /// No description provided for @lifeNoWallet.
  ///
  /// In en, this message translates to:
  /// **'No wallet record'**
  String get lifeNoWallet;

  /// No description provided for @lifeCloseBlocked.
  ///
  /// In en, this message translates to:
  /// **'Account closure is not yet available. Session termination and checks across connected services must be completed first.'**
  String get lifeCloseBlocked;

  /// No description provided for @lifeApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get lifeApproved;

  /// No description provided for @closeAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account closed'**
  String get closeAccountTitle;

  /// No description provided for @closeAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'This account is closed. Your existing Kao ID and identity history are retained. You may request to return, but access and staff permissions will not be restored automatically.'**
  String get closeAccountHelp;

  /// No description provided for @closeSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'This session has ended. Sign out and sign in again to view the account status.'**
  String get closeSessionEnded;

  /// No description provided for @closeAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Close account now'**
  String get closeAccountAction;

  /// No description provided for @closeAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'This closes account access, ends existing sessions, revokes staff permissions and cancels pending identity reviews. The existing Kao ID and history are retained. Confirm only after reviewing the request.'**
  String get closeAccountConfirm;

  /// No description provided for @closeAccountReady.
  ///
  /// In en, this message translates to:
  /// **'Current checks passed. The server checks again when you confirm.'**
  String get closeAccountReady;

  /// No description provided for @closeAccountBlocked.
  ///
  /// In en, this message translates to:
  /// **'Closure is unavailable. Review the account state and service records below. A service record is not necessarily an outstanding debt. Recovery requests require a separate identity review.'**
  String get closeAccountBlocked;

  /// No description provided for @closeServiceReview.
  ///
  /// In en, this message translates to:
  /// **'Service records requiring review'**
  String get closeServiceReview;

  /// No description provided for @recoveryEvidenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify identity to return'**
  String get recoveryEvidenceTitle;

  /// No description provided for @recoveryEvidenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Submit a new national ID card or passport for staff review. Your account stays closed until approved. An existing Kao ID is retained; staff permissions are not restored.'**
  String get recoveryEvidenceHelp;

  /// No description provided for @recoveryActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this action. Check the information, expiry date and session, then retry. If retained identity evidence is unavailable, contact the Owner.'**
  String get recoveryActionFailed;

  /// No description provided for @recoveryRetryHelp.
  ///
  /// In en, this message translates to:
  /// **'Retry with the same files after a connection failure. To replace files already uploaded, cancel this request and create a new recovery request.'**
  String get recoveryRetryHelp;

  /// No description provided for @recoveryReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Account recovery review'**
  String get recoveryReviewTitle;

  /// No description provided for @recoveryReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Compare the new evidence with retained identity records. Approving restores this account and its existing Kao ID. It does not restore staff permissions. Record why the evidence belongs to the same person.'**
  String get recoveryReviewHelp;

  /// No description provided for @recoveryPreviousEvidence.
  ///
  /// In en, this message translates to:
  /// **'View retained evidence'**
  String get recoveryPreviousEvidence;

  /// No description provided for @recoveryConfirmPerson.
  ///
  /// In en, this message translates to:
  /// **'I have verified the applicant’s identity and compared available retained evidence.'**
  String get recoveryConfirmPerson;

  /// No description provided for @recoveryRestored.
  ///
  /// In en, this message translates to:
  /// **'Account access restored'**
  String get recoveryRestored;

  /// No description provided for @restrictedAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'This account is restricted. Account actions are unavailable. Contact the administrator for review.'**
  String get restrictedAccountHelp;

  /// No description provided for @unavailableAccountHelp.
  ///
  /// In en, this message translates to:
  /// **'Account information is unavailable. Retry or sign out.'**
  String get unavailableAccountHelp;

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Signed-in sessions'**
  String get sessionTitle;

  /// No description provided for @sessionHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows up to 100 live sign-in sessions. Browser and IP details come from the authentication service; missing details are shown as —.'**
  String get sessionHelp;

  /// No description provided for @sessionCurrent.
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get sessionCurrent;

  /// No description provided for @sessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get sessionStarted;

  /// No description provided for @sessionRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Last token refresh'**
  String get sessionRefreshed;

  /// No description provided for @sessionRevoke.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get sessionRevoke;

  /// No description provided for @sessionOthers.
  ///
  /// In en, this message translates to:
  /// **'End all other sessions'**
  String get sessionOthers;

  /// No description provided for @sessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'The affected sessions must sign in again. This session will remain active.'**
  String get sessionConfirm;

  /// No description provided for @documentHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Document validity and renewal'**
  String get documentHealthTitle;

  /// No description provided for @documentHealthHelp.
  ///
  /// In en, this message translates to:
  /// **'Renew within 30 days of expiry, or submit new evidence after expiry or revocation. Previous records and your Kao ID are retained. New evidence requires review.'**
  String get documentHealthHelp;

  /// No description provided for @documentRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke document approval'**
  String get documentRevoke;

  /// No description provided for @documentRevokeHelp.
  ///
  /// In en, this message translates to:
  /// **'Record a reason. If no valid primary identity document remains, Kao ID use is suspended until fresh evidence is approved. History is retained.'**
  String get documentRevokeHelp;

  /// No description provided for @documentRevoked.
  ///
  /// In en, this message translates to:
  /// **'Approval revoked'**
  String get documentRevoked;

  /// No description provided for @documentRenew.
  ///
  /// In en, this message translates to:
  /// **'Open document / submit replacement'**
  String get documentRenew;

  /// No description provided for @documentHistory.
  ///
  /// In en, this message translates to:
  /// **'Revocation and expiry history'**
  String get documentHistory;

  /// No description provided for @documentSystem.
  ///
  /// In en, this message translates to:
  /// **'System · document expiry check'**
  String get documentSystem;

  /// No description provided for @documentExpiring.
  ///
  /// In en, this message translates to:
  /// **'Your document expires within 30 days. Please prepare a replacement.'**
  String get documentExpiring;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Central wallet'**
  String get walletTitle;

  /// No description provided for @walletReadHelp.
  ///
  /// In en, this message translates to:
  /// **'View recorded balances and transactions. Funding and purchases are not available yet. Recorded balances do not confirm spendable funds.'**
  String get walletReadHelp;

  /// No description provided for @walletLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load wallet data. Please try again.'**
  String get walletLoadFailed;

  /// No description provided for @walletMissing.
  ///
  /// In en, this message translates to:
  /// **'No wallet has been created for this account.'**
  String get walletMissing;

  /// No description provided for @walletRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded balance'**
  String get walletRecorded;

  /// No description provided for @walletHeld.
  ///
  /// In en, this message translates to:
  /// **'Recorded held amount'**
  String get walletHeld;

  /// No description provided for @walletStateCode.
  ///
  /// In en, this message translates to:
  /// **'Status code'**
  String get walletStateCode;

  /// No description provided for @walletUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get walletUpdated;

  /// No description provided for @walletHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history'**
  String get walletHistory;

  /// No description provided for @walletNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recorded transactions.'**
  String get walletNoTransactions;

  /// No description provided for @walletTypeCode.
  ///
  /// In en, this message translates to:
  /// **'Transaction type code'**
  String get walletTypeCode;

  /// No description provided for @walletReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction reference'**
  String get walletReference;

  /// No description provided for @walletAfter.
  ///
  /// In en, this message translates to:
  /// **'Recorded balance after transaction'**
  String get walletAfter;

  /// No description provided for @walletMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get walletMore;

  /// No description provided for @partnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial partners'**
  String get partnerTitle;

  /// No description provided for @partnerHelp.
  ///
  /// In en, this message translates to:
  /// **'Owner manages each partner and environment separately. Approval alone does not enable a connection or move money.'**
  String get partnerHelp;

  /// No description provided for @partnerFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete this request. Access may have changed or the record may be outdated. Reload and check before retrying.'**
  String get partnerFailed;

  /// No description provided for @partnerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No registered partners.'**
  String get partnerEmpty;

  /// No description provided for @partnerAdd.
  ///
  /// In en, this message translates to:
  /// **'Register partner'**
  String get partnerAdd;

  /// No description provided for @partnerSandbox.
  ///
  /// In en, this message translates to:
  /// **'Test mode'**
  String get partnerSandbox;

  /// No description provided for @partnerLive.
  ///
  /// In en, this message translates to:
  /// **'Live mode'**
  String get partnerLive;

  /// No description provided for @partnerPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get partnerPending;

  /// No description provided for @partnerApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get partnerApproved;

  /// No description provided for @partnerRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get partnerRejected;

  /// No description provided for @partnerDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get partnerDisabled;

  /// No description provided for @partnerApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve partner'**
  String get partnerApprove;

  /// No description provided for @partnerReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get partnerReject;

  /// No description provided for @partnerDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable connection'**
  String get partnerDisable;

  /// No description provided for @partnerResubmit.
  ///
  /// In en, this message translates to:
  /// **'Request review again'**
  String get partnerResubmit;

  /// No description provided for @partnerEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable connection'**
  String get partnerEnable;

  /// No description provided for @partnerBalance.
  ///
  /// In en, this message translates to:
  /// **'Read balance'**
  String get partnerBalance;

  /// No description provided for @partnerPayment.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get partnerPayment;

  /// No description provided for @partnerRefund.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get partnerRefund;

  /// No description provided for @partnerPayout.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get partnerPayout;

  /// No description provided for @partnerTopup.
  ///
  /// In en, this message translates to:
  /// **'Top-ups'**
  String get partnerTopup;

  /// No description provided for @partnerReadiness.
  ///
  /// In en, this message translates to:
  /// **'Adapter report'**
  String get partnerReadiness;

  /// No description provided for @partnerReady.
  ///
  /// In en, this message translates to:
  /// **'Technical checks are current'**
  String get partnerReady;

  /// No description provided for @partnerNotReady.
  ///
  /// In en, this message translates to:
  /// **'Connection is not ready; server setup and test evidence are required'**
  String get partnerNotReady;

  /// No description provided for @partnerConnected.
  ///
  /// In en, this message translates to:
  /// **'Connection enabled'**
  String get partnerConnected;

  /// No description provided for @partnerNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Connection inactive'**
  String get partnerNotConnected;

  /// No description provided for @partnerCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Permitted services'**
  String get partnerCapabilities;

  /// No description provided for @partnerExpires.
  ///
  /// In en, this message translates to:
  /// **'Readiness expires'**
  String get partnerExpires;

  /// No description provided for @partnerHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent history (20 entries)'**
  String get partnerHistory;

  /// No description provided for @partnerActor.
  ///
  /// In en, this message translates to:
  /// **'Performed by'**
  String get partnerActor;

  /// No description provided for @partnerSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get partnerSystem;

  /// No description provided for @partnerFormHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter a real partner name and a unique lowercase code (letters, digits, _ or -; 2–40 characters). Do not enter API keys or passwords.'**
  String get partnerFormHelp;

  /// No description provided for @partnerCode.
  ///
  /// In en, this message translates to:
  /// **'Partner code'**
  String get partnerCode;

  /// No description provided for @partnerName.
  ///
  /// In en, this message translates to:
  /// **'Partner name'**
  String get partnerName;

  /// No description provided for @partnerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Check the partner, environment and permitted services. Approval does not transfer funds. A technical readiness report is required before enabling.'**
  String get partnerConfirm;

  /// No description provided for @partnerReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (at least 3 characters)'**
  String get partnerReason;

  /// No description provided for @carrierTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping partners'**
  String get carrierTitle;

  /// No description provided for @carrierQuote.
  ///
  /// In en, this message translates to:
  /// **'Shipping quote'**
  String get carrierQuote;

  /// No description provided for @carrierShipment.
  ///
  /// In en, this message translates to:
  /// **'Create shipment'**
  String get carrierShipment;

  /// No description provided for @carrierTracking.
  ///
  /// In en, this message translates to:
  /// **'Track shipment'**
  String get carrierTracking;

  /// No description provided for @carrierCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel shipment'**
  String get carrierCancel;

  /// No description provided for @linkedWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner-linked wallets'**
  String get linkedWalletTitle;

  /// No description provided for @linkedWalletHelp.
  ///
  /// In en, this message translates to:
  /// **'Balances are provider reports as of the shown time. Providers and test/live funds are kept separate. Payments are not enabled here.'**
  String get linkedWalletHelp;

  /// No description provided for @linkedWalletEmpty.
  ///
  /// In en, this message translates to:
  /// **'No linked partner wallet.'**
  String get linkedWalletEmpty;

  /// No description provided for @linkedReference.
  ///
  /// In en, this message translates to:
  /// **'Provider reference'**
  String get linkedReference;

  /// No description provided for @linkedNoSnapshot.
  ///
  /// In en, this message translates to:
  /// **'No balance report received.'**
  String get linkedNoSnapshot;

  /// No description provided for @linkedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available reported by provider'**
  String get linkedAvailable;

  /// No description provided for @linkedPending.
  ///
  /// In en, this message translates to:
  /// **'Pending reported by provider'**
  String get linkedPending;

  /// No description provided for @linkedObserved.
  ///
  /// In en, this message translates to:
  /// **'Provider observation time'**
  String get linkedObserved;

  /// No description provided for @linkedStale.
  ///
  /// In en, this message translates to:
  /// **'This report is over 30 minutes old. Refreshing this page does not fetch a new provider balance.'**
  String get linkedStale;

  /// No description provided for @linkedUnreconciled.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation against the transaction ledger has not been completed.'**
  String get linkedUnreconciled;

  /// No description provided for @linkedApplied.
  ///
  /// In en, this message translates to:
  /// **'Balance report applied'**
  String get linkedApplied;

  /// No description provided for @linkedOlder.
  ///
  /// In en, this message translates to:
  /// **'Older report retained without replacing the latest balance'**
  String get linkedOlder;

  /// No description provided for @mfaHelp.
  ///
  /// In en, this message translates to:
  /// **'Use an authenticator app to protect your account. Never share its setup key or codes.'**
  String get mfaHelp;

  /// No description provided for @mfaFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete this step. Check your password or code, verify MFA again if needed, and retry.'**
  String get mfaFailed;

  /// No description provided for @mfaSessionVerified.
  ///
  /// In en, this message translates to:
  /// **'This session has passed MFA. Sensitive actions require a code verified within 10 minutes.'**
  String get mfaSessionVerified;

  /// No description provided for @mfaSessionRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify an authenticator code before using protected tools.'**
  String get mfaSessionRequired;

  /// No description provided for @mfaFactorCount.
  ///
  /// In en, this message translates to:
  /// **'Verified authenticators'**
  String get mfaFactorCount;

  /// No description provided for @mfaChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose an authenticator'**
  String get mfaChoose;

  /// No description provided for @mfaManualSetup.
  ///
  /// In en, this message translates to:
  /// **'In your authenticator app, add a time-based account named Kao ID and enter this setup key. Then verify its six-digit code.'**
  String get mfaManualSetup;

  /// No description provided for @mfaShowSecret.
  ///
  /// In en, this message translates to:
  /// **'Show / hide setup key'**
  String get mfaShowSecret;

  /// No description provided for @mfaCode.
  ///
  /// In en, this message translates to:
  /// **'Six-digit code'**
  String get mfaCode;

  /// No description provided for @mfaVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get mfaVerify;

  /// No description provided for @mfaBackupHelp.
  ///
  /// In en, this message translates to:
  /// **'Add a backup authenticator on a separate device. Verify an existing authenticator before adding another.'**
  String get mfaBackupHelp;

  /// No description provided for @mfaDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Authenticator name'**
  String get mfaDeviceName;

  /// No description provided for @mfaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add authenticator'**
  String get mfaAdd;

  /// No description provided for @mfaRecoveryHelp.
  ///
  /// In en, this message translates to:
  /// **'If a device is lost, sign in and verify with your backup authenticator. If all factors are lost, project-level identity recovery is required; email alone cannot reset privileged access.'**
  String get mfaRecoveryHelp;

  /// No description provided for @securityEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable staff protection'**
  String get securityEnable;

  /// No description provided for @securityEnableHelp.
  ///
  /// In en, this message translates to:
  /// **'Requires two verified authenticators for Owner and two other active KYC officers with MFA. Enabling requires MFA for administrative access and two different reviewers for document and identity-recovery decisions. There is no one-click downgrade.'**
  String get securityEnableHelp;

  /// No description provided for @securityReadyReviewers.
  ///
  /// In en, this message translates to:
  /// **'KYC officers with MFA'**
  String get securityReadyReviewers;

  /// No description provided for @securityEnabled.
  ///
  /// In en, this message translates to:
  /// **'Staff protection enabled'**
  String get securityEnabled;

  /// No description provided for @securitySetupPending.
  ///
  /// In en, this message translates to:
  /// **'Setup pending; existing approval rules still apply'**
  String get securitySetupPending;

  /// No description provided for @dualReviewHelp.
  ///
  /// In en, this message translates to:
  /// **'Two independent reviewers must agree before the result is applied.'**
  String get dualReviewHelp;

  /// No description provided for @dualWaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting a second reviewer'**
  String get dualWaiting;

  /// No description provided for @dualFirstDecision.
  ///
  /// In en, this message translates to:
  /// **'First proposed result'**
  String get dualFirstDecision;

  /// No description provided for @dualOwnVote.
  ///
  /// In en, this message translates to:
  /// **'You recorded the first result. Another authorized reviewer must decide.'**
  String get dualOwnVote;

  /// No description provided for @dualDisagreeHelp.
  ///
  /// In en, this message translates to:
  /// **'Choosing the opposite result returns the request for a new review; it does not finalize a rejection.'**
  String get dualDisagreeHelp;

  /// No description provided for @securityNotice.
  ///
  /// In en, this message translates to:
  /// **'Account security settings changed'**
  String get securityNotice;

  /// No description provided for @securityOperations.
  ///
  /// In en, this message translates to:
  /// **'Security operations'**
  String get securityOperations;

  /// No description provided for @securityPendingReviews.
  ///
  /// In en, this message translates to:
  /// **'Awaiting second review'**
  String get securityPendingReviews;

  /// No description provided for @securityExpiredReviews.
  ///
  /// In en, this message translates to:
  /// **'Review window expired'**
  String get securityExpiredReviews;

  /// No description provided for @securityFailedEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed email jobs'**
  String get securityFailedEmail;

  /// No description provided for @securityStalledEmail.
  ///
  /// In en, this message translates to:
  /// **'Email jobs with expired leases'**
  String get securityStalledEmail;

  /// No description provided for @securityPendingEmail.
  ///
  /// In en, this message translates to:
  /// **'Pending email jobs'**
  String get securityPendingEmail;

  /// No description provided for @securityOperationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Live queue counts. These do not prove email delivery or system capacity. Refresh to check again.'**
  String get securityOperationsHelp;

  /// No description provided for @noticeReviewNew.
  ///
  /// In en, this message translates to:
  /// **'New request awaiting review'**
  String get noticeReviewNew;

  /// No description provided for @noticeReviewSecond.
  ///
  /// In en, this message translates to:
  /// **'Awaiting a second reviewer'**
  String get noticeReviewSecond;

  /// No description provided for @noticeReviewRestart.
  ///
  /// In en, this message translates to:
  /// **'Reviewers disagreed; review again'**
  String get noticeReviewRestart;

  /// No description provided for @noticeRoleAssigned.
  ///
  /// In en, this message translates to:
  /// **'Staff role assigned'**
  String get noticeRoleAssigned;

  /// No description provided for @noticeRoleRevoked.
  ///
  /// In en, this message translates to:
  /// **'Staff role inactive or revoked'**
  String get noticeRoleRevoked;

  /// No description provided for @noticeOpenItem.
  ///
  /// In en, this message translates to:
  /// **'Open related item'**
  String get noticeOpenItem;

  /// No description provided for @noticeCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current status'**
  String get noticeCurrentStatus;

  /// No description provided for @noticeTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is complete or is no longer available for review.'**
  String get noticeTargetUnavailable;

  /// No description provided for @noticeAccessFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this item. Check your connection, current permissions and MFA, then retry.'**
  String get noticeAccessFailed;

  /// No description provided for @businessRegTitle.
  ///
  /// In en, this message translates to:
  /// **'Register your business'**
  String get businessRegTitle;

  /// No description provided for @businessRegSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your business once and use it across Kao services.'**
  String get businessRegSubtitle;

  /// No description provided for @businessRegStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String businessRegStepCounter(int current, int total);

  /// No description provided for @businessRegStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get businessRegStepDetails;

  /// No description provided for @businessRegStepDocument.
  ///
  /// In en, this message translates to:
  /// **'Business document'**
  String get businessRegStepDocument;

  /// No description provided for @businessRegStepBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get businessRegStepBank;

  /// No description provided for @businessRegStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get businessRegStepReview;

  /// No description provided for @businessRegSecureNotice.
  ///
  /// In en, this message translates to:
  /// **'Your information is encrypted and used only to verify your business.'**
  String get businessRegSecureNotice;

  /// No description provided for @businessRegDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your business'**
  String get businessRegDetailsHeading;

  /// No description provided for @businessRegDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the details exactly as they appear on your registration document.'**
  String get businessRegDetailsDescription;

  /// No description provided for @businessRegTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Business type'**
  String get businessRegTypeLabel;

  /// No description provided for @businessRegTypeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company or partnership'**
  String get businessRegTypeCompany;

  /// No description provided for @businessRegTypeCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Registered juristic person with a 13-digit registration number'**
  String get businessRegTypeCompanyHint;

  /// No description provided for @businessRegTypeOrganization.
  ///
  /// In en, this message translates to:
  /// **'Foundation or association'**
  String get businessRegTypeOrganization;

  /// No description provided for @businessRegTypeOrganizationHint.
  ///
  /// In en, this message translates to:
  /// **'Registered non-profit organization'**
  String get businessRegTypeOrganizationHint;

  /// No description provided for @businessRegNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Registered business name'**
  String get businessRegNameLabel;

  /// No description provided for @businessRegNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get businessRegNumberLabel;

  /// No description provided for @businessRegNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'13 digits, numbers only'**
  String get businessRegNumberHelp;

  /// No description provided for @businessRegCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Business category'**
  String get businessRegCategoryLabel;

  /// No description provided for @businessRegCategoryRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get businessRegCategoryRetail;

  /// No description provided for @businessRegCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food and beverage'**
  String get businessRegCategoryFood;

  /// No description provided for @businessRegCategoryServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get businessRegCategoryServices;

  /// No description provided for @businessRegCategoryTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get businessRegCategoryTechnology;

  /// No description provided for @businessRegCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get businessRegCategoryOther;

  /// No description provided for @businessRegDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'About your business (optional)'**
  String get businessRegDescriptionLabel;

  /// No description provided for @businessRegFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get businessRegFieldRequired;

  /// No description provided for @businessRegNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 13-digit registration number'**
  String get businessRegNumberInvalid;

  /// No description provided for @businessRegDocumentHeading.
  ///
  /// In en, this message translates to:
  /// **'Upload your registration document'**
  String get businessRegDocumentHeading;

  /// No description provided for @businessRegDocumentDescription.
  ///
  /// In en, this message translates to:
  /// **'A company certificate or registration certificate showing the business name and number.'**
  String get businessRegDocumentDescription;

  /// No description provided for @businessRegDocumentRequirements.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF, up to 10 MB. All text must be clearly readable.'**
  String get businessRegDocumentRequirements;

  /// No description provided for @businessRegDocumentChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get businessRegDocumentChoose;

  /// No description provided for @businessRegDocumentReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace file'**
  String get businessRegDocumentReplace;

  /// No description provided for @businessRegDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded'**
  String get businessRegDocumentUploaded;

  /// No description provided for @businessRegDocumentUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading securely…'**
  String get businessRegDocumentUploading;

  /// No description provided for @businessRegDocumentMissing.
  ///
  /// In en, this message translates to:
  /// **'No document uploaded yet'**
  String get businessRegDocumentMissing;

  /// No description provided for @businessRegBankHeading.
  ///
  /// In en, this message translates to:
  /// **'Payout bank account'**
  String get businessRegBankHeading;

  /// No description provided for @businessRegBankDescription.
  ///
  /// In en, this message translates to:
  /// **'Business payouts go to the bank account verified with your Kao ID.'**
  String get businessRegBankDescription;

  /// No description provided for @businessRegBankApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get businessRegBankApproved;

  /// No description provided for @businessRegBankPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get businessRegBankPending;

  /// No description provided for @businessRegBankRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get businessRegBankRejected;

  /// No description provided for @businessRegBankMissing.
  ///
  /// In en, this message translates to:
  /// **'No verified bank account yet'**
  String get businessRegBankMissing;

  /// No description provided for @businessRegBankRequiredHelp.
  ///
  /// In en, this message translates to:
  /// **'You can submit once your bank account is verified.'**
  String get businessRegBankRequiredHelp;

  /// No description provided for @businessRegBankVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify a bank account'**
  String get businessRegBankVerifyAction;

  /// No description provided for @businessRegBankCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get businessRegBankCheckAgain;

  /// No description provided for @businessRegReviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Review your details'**
  String get businessRegReviewHeading;

  /// No description provided for @businessRegReviewDescription.
  ///
  /// In en, this message translates to:
  /// **'Make sure everything is correct. You can\'t edit while it\'s under review.'**
  String get businessRegReviewDescription;

  /// No description provided for @businessRegEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get businessRegEdit;

  /// No description provided for @businessRegConsent.
  ///
  /// In en, this message translates to:
  /// **'I confirm this information is accurate and allow Kao ID to verify it.'**
  String get businessRegConsent;

  /// No description provided for @businessRegSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get businessRegSubmit;

  /// No description provided for @businessRegContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get businessRegContinue;

  /// No description provided for @businessRegBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get businessRegBack;

  /// No description provided for @businessRegSubmitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your registration?'**
  String get businessRegSubmitConfirmTitle;

  /// No description provided for @businessRegSubmitConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review your business and notify you of the result.'**
  String get businessRegSubmitConfirmBody;

  /// No description provided for @businessRegCancelDraft.
  ///
  /// In en, this message translates to:
  /// **'Cancel registration'**
  String get businessRegCancelDraft;

  /// No description provided for @businessRegCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this registration?'**
  String get businessRegCancelConfirmTitle;

  /// No description provided for @businessRegCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your draft and uploaded document will no longer be used.'**
  String get businessRegCancelConfirmBody;

  /// No description provided for @businessRegKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get businessRegKeepEditing;

  /// No description provided for @businessRegStatusReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your business'**
  String get businessRegStatusReviewTitle;

  /// No description provided for @businessRegStatusReviewBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you as soon as the review is complete.'**
  String get businessRegStatusReviewBody;

  /// No description provided for @businessRegStatusApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your business is verified'**
  String get businessRegStatusApprovedTitle;

  /// No description provided for @businessRegStatusApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'You can now use your business with Kao services.'**
  String get businessRegStatusApprovedBody;

  /// No description provided for @businessRegStatusRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration not approved'**
  String get businessRegStatusRejectedTitle;

  /// No description provided for @businessRegStatusRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'You can start a new registration with updated information.'**
  String get businessRegStatusRejectedBody;

  /// No description provided for @businessRegStatusActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Action needed'**
  String get businessRegStatusActionTitle;

  /// No description provided for @businessRegStatusActionBody.
  ///
  /// In en, this message translates to:
  /// **'Check your notifications for what to update.'**
  String get businessRegStatusActionBody;

  /// No description provided for @businessRegRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get businessRegRefreshStatus;

  /// No description provided for @businessRegStartNew.
  ///
  /// In en, this message translates to:
  /// **'Start a new registration'**
  String get businessRegStartNew;

  /// No description provided for @businessRegBackToAccount.
  ///
  /// In en, this message translates to:
  /// **'Back to my account'**
  String get businessRegBackToAccount;

  /// No description provided for @businessRegErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get businessRegErrorGeneric;

  /// No description provided for @businessRegErrorSession.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get businessRegErrorSession;

  /// No description provided for @businessRegErrorRestricted.
  ///
  /// In en, this message translates to:
  /// **'Your account can\'t register a business right now.'**
  String get businessRegErrorRestricted;

  /// No description provided for @businessRegErrorActiveExists.
  ///
  /// In en, this message translates to:
  /// **'You already have a registration in progress.'**
  String get businessRegErrorActiveExists;

  /// No description provided for @businessRegErrorNotEditable.
  ///
  /// In en, this message translates to:
  /// **'This registration can no longer be changed.'**
  String get businessRegErrorNotEditable;

  /// No description provided for @businessRegErrorDocumentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload your registration document.'**
  String get businessRegErrorDocumentRequired;

  /// No description provided for @businessRegErrorBankRequired.
  ///
  /// In en, this message translates to:
  /// **'A verified bank account is required before you submit.'**
  String get businessRegErrorBankRequired;

  /// No description provided for @businessRegErrorFile.
  ///
  /// In en, this message translates to:
  /// **'This file can\'t be used. Choose a JPG, PNG or PDF up to 10 MB.'**
  String get businessRegErrorFile;

  /// No description provided for @businessRegErrorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This registration number is already registered.'**
  String get businessRegErrorDuplicate;

  /// No description provided for @businessRegHubDescription.
  ///
  /// In en, this message translates to:
  /// **'Verify your business to open a store and receive payouts.'**
  String get businessRegHubDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'ja',
    'lo',
    'my',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'lo':
      return AppLocalizationsLo();
    case 'my':
      return AppLocalizationsMy();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
