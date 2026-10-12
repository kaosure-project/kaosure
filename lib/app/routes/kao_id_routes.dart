final class KaoIdRoutes {
  const KaoIdRoutes._();

  static const String landing = '/';
  static const String kaoIdLanding = '/kao-id';
  static const String completeProfile = '/complete-profile';

  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  static const String bootstrap = '/bootstrap';

  static const String dashboard = '/dashboard';
  static const String governance = '/governance';

  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String personalInfo = '/profile/personal';

  static const String identity = '/identity';
  static const String kyc = '/identity/verification';

  static const String devices = '/devices';
  static const String sessions = '/sessions';

  static const String security = '/security';
  static const String changePassword = '/security/password';

  static const String settings = '/settings';

  /// Routes behind the Kao ID header tabs, in tab order.
  static const List<String> accountTabs = [dashboard, profile, security, settings];

  static const String businessRegistration = '/kao-id/business/register';
  static const String businessInformation = '/kao-id/business/information';
  static const String businessDocument = '/kao-id/business/document';
  static const String businessReview = '/kao-id/business/review';
  static const String businessCompleted = '/kao-id/business/completed';
}
