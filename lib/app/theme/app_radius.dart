/// KaoSure Design System V1
/// Border Radius Tokens
///
/// ใช้ค่า Radius จากไฟล์นี้เท่านั้น
/// ห้าม Hardcode BorderRadius.circular()

class AppRadius {
  AppRadius._();

  // ==========================================================================
  // Base Radius
  // ==========================================================================

  static const double none = 0.0;

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // ==========================================================================
  // Components
  // ==========================================================================

  /// Buttons
  static const double button = md;

  /// TextField
  static const double textField = md;

  /// Card
  static const double card = lg;

  /// Dialog
  static const double dialog = xl;

  /// Bottom Sheet
  static const double bottomSheet = xl;

  /// Chip
  static const double chip = 999.0;

  /// Badge
  static const double badge = 999.0;

  /// Avatar
  static const double avatar = 999.0;

  /// Fully Rounded
  static const double round = 999.0;
}