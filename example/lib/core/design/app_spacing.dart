/// App spacing constants
class AppSpacing {
  // Base spacing unit (4px)
  static const double unit = 4.0;

  // Spacing values
  static const double xs = unit; // 4px
  static const double sm = unit * 2; // 8px
  static const double md = unit * 4; // 16px
  static const double lg = unit * 6; // 24px
  static const double xl = unit * 8; // 32px
  static const double xxl = unit * 12; // 48px
  static const double xxxl = unit * 16; // 64px

  // Specific spacing for different UI elements
  static const double cardPadding = md;
  static const double cardBorderRadius = md;
  static const double buttonPadding = md;
  static const double buttonBorderRadius = sm;
  static const double inputPadding = md;
  static const double inputBorderRadius = sm;
  static const double listItemSpacing = sm;
  static const double sectionSpacing = xl;
  static const double screenPadding = md;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
