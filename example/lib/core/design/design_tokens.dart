import 'package:flutter/material.dart';

/// Design tokens for the Pivox example app
/// These tokens define the core design elements like colors, typography, and spacing
class DesignTokens {
  // Light Theme Colors
  static const Color primaryColor = Color(0xFF4A6FFF);
  static const Color primaryColorLight = Color(0xFF7B93FF);
  static const Color primaryColorDark = Color(0xFF2A4FDF);

  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryColorLight = Color(0xFF66FFF8);
  static const Color secondaryColorDark = Color(0xFF00A896);

  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color infoColor = Color(0xFF2196F3);

  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Color(0xFFFFFFFF);

  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textTertiaryColor = Color(0xFFBDBDBD);

  static const Color dividerColor = Color(0xFFEEEEEE);

  static const Color chipTextColor = Color(0xFF757575);
  static const Color chipSelectedTextColor = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF3D5CCC);
  static const Color darkPrimaryColorLight = Color(0xFF5A78E2);
  static const Color darkPrimaryColorDark = Color(0xFF2A4099);

  static const Color darkSecondaryColor = Color(0xFF00BFA5);
  static const Color darkSecondaryColorLight = Color(0xFF33CFBA);
  static const Color darkSecondaryColorDark = Color(0xFF008C7A);

  static const Color darkErrorColor = Color(0xFFEF5350);
  static const Color darkSuccessColor = Color(0xFF66BB6A);
  static const Color darkWarningColor = Color(0xFFFFB74D);
  static const Color darkInfoColor = Color(0xFF42A5F5);

  static const Color darkSurfaceColor = Color(0xFF121212);
  static const Color darkBackgroundColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF2C2C2C);

  static const Color darkTextPrimaryColor = Color(0xFFE0E0E0);
  static const Color darkTextSecondaryColor = Color(0xFFAAAAAA);
  static const Color darkTextTertiaryColor = Color(0xFF666666);

  static const Color darkDividerColor = Color(0xFF424242);

  // Typography
  static const String fontFamily = 'Inter';

  static const double fontSizeXSmall = 12.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeXXXLarge = 30.0;

  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Spacing
  static const double spacingXXSmall = 2.0;
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  static const double spacingXXXLarge = 64.0;

  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusCircular = 999.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationLarge = 4.0;
  static const double elevationXLarge = 8.0;

  static const List<BoxShadow> elevationLevel1 = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevationLevel2 = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> elevationLevel3 = [
    BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  // Animation
  static const Duration durationShort = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationLong = Duration(milliseconds: 500);

  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveDecelerate = Curves.easeOut;
}
