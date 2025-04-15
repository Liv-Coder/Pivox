import 'package:flutter/material.dart';

/// Design tokens for the Pivox example app
/// These tokens define the core design elements like colors, typography, and spacing
class DesignTokens {
  // Light Theme Colors
  static const Color primaryColor = Color(0xFF5E6AD2); // Modern indigo
  static const Color primaryColorLight = Color(0xFF8A94E2); // Lighter indigo
  static const Color primaryColorDark = Color(0xFF3A45A0); // Darker indigo

  static const Color secondaryColor = Color(0xFF00C2B8); // Teal
  static const Color secondaryColorLight = Color(0xFF5EEAE0); // Light teal
  static const Color secondaryColorDark = Color(0xFF00958D); // Dark teal

  static const Color errorColor = Color(0xFFE5484D); // Modern red
  static const Color successColor = Color(0xFF30A46C); // Modern green
  static const Color warningColor = Color(0xFFF76B15); // Modern orange
  static const Color infoColor = Color(0xFF0091FF); // Modern blue

  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color backgroundColor = Color(0xFFF8F9FC); // Light gray-blue
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color cardHoverColor = Color(0xFFF0F2F5); // Light gray for hover

  static const Color textPrimaryColor = Color(0xFF1A1D1F); // Near black
  static const Color textSecondaryColor = Color(0xFF6F767E); // Medium gray
  static const Color textTertiaryColor = Color(0xFFA5ACB8); // Light gray

  static const Color dividerColor = Color(0xFFEEF0F3); // Light gray
  static const Color borderColor = Color(0xFFDFE3E8); // Medium light gray

  static const Color chipTextColor = Color(0xFF6F767E); // Medium gray
  static const Color chipSelectedTextColor = Color(0xFFFFFFFF); // White

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(
    0xFF7B82D8,
  ); // Brighter indigo for dark theme
  static const Color darkPrimaryColorLight = Color(
    0xFF9CA2E8,
  ); // Lighter indigo
  static const Color darkPrimaryColorDark = Color(0xFF5A61B3); // Darker indigo

  static const Color darkSecondaryColor = Color(0xFF0CDFCF); // Brighter teal
  static const Color darkSecondaryColorLight = Color(0xFF6EEEE4); // Light teal
  static const Color darkSecondaryColorDark = Color(0xFF00ADA3); // Dark teal

  static const Color darkErrorColor = Color(0xFFFF6369); // Brighter red
  static const Color darkSuccessColor = Color(0xFF4CC38A); // Brighter green
  static const Color darkWarningColor = Color(0xFFFF8F3E); // Brighter orange
  static const Color darkInfoColor = Color(0xFF3AA8FF); // Brighter blue

  static const Color darkSurfaceColor = Color(0xFF111827); // Dark blue-gray
  static const Color darkBackgroundColor = Color(
    0xFF0F172A,
  ); // Darker blue-gray
  static const Color darkCardColor = Color(0xFF1E293B); // Medium dark blue-gray
  static const Color darkCardHoverColor = Color(
    0xFF283548,
  ); // Slightly lighter for hover

  static const Color darkTextPrimaryColor = Color(0xFFF1F5F9); // Off-white
  static const Color darkTextSecondaryColor = Color(0xFFCBD5E1); // Light gray
  static const Color darkTextTertiaryColor = Color(0xFF64748B); // Medium gray

  static const Color darkDividerColor = Color(0xFF334155); // Medium dark gray
  static const Color darkBorderColor = Color(0xFF475569); // Medium gray

  // Typography
  static const String fontFamily = 'Inter';

  static const double fontSizeXXSmall = 10.0; // Micro text
  static const double fontSizeXSmall = 12.0; // Caption
  static const double fontSizeSmall = 14.0; // Small text
  static const double fontSizeMedium = 16.0; // Body text
  static const double fontSizeLarge = 18.0; // Subtitle
  static const double fontSizeXLarge = 22.0; // Title
  static const double fontSizeXXLarge = 28.0; // Heading
  static const double fontSizeXXXLarge = 36.0; // Display
  static const double fontSizeHuge = 48.0; // Hero text

  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // Line heights
  static const double lineHeightTight = 1.2; // Headings
  static const double lineHeightNormal = 1.5; // Body text
  static const double lineHeightRelaxed = 1.75; // Readable text

  // Letter spacing
  static const double letterSpacingTight = -0.5; // Headings
  static const double letterSpacingNormal = 0.0; // Normal text
  static const double letterSpacingWide = 0.5; // Buttons, labels

  // Spacing - 8pt grid system
  static const double spacingXXSmall = 2.0; // Micro spacing
  static const double spacingXSmall = 4.0; // Tiny spacing
  static const double spacingSmall = 8.0; // Small spacing
  static const double spacingMedium = 16.0; // Medium spacing
  static const double spacingLarge = 24.0; // Large spacing
  static const double spacingXLarge = 32.0; // Extra large spacing
  static const double spacingXXLarge = 48.0; // 2x large spacing
  static const double spacingXXXLarge = 64.0; // 3x large spacing
  static const double spacingHuge = 96.0; // Huge spacing

  // Layout spacing
  static const double layoutGutterSmall = 16.0; // Small gutter
  static const double layoutGutterMedium = 24.0; // Medium gutter
  static const double layoutGutterLarge = 32.0; // Large gutter

  // Border Radius
  static const double borderRadiusXSmall = 4.0; // Subtle radius
  static const double borderRadiusSmall = 8.0; // Small radius
  static const double borderRadiusMedium = 12.0; // Medium radius
  static const double borderRadiusLarge = 16.0; // Large radius
  static const double borderRadiusXLarge = 24.0; // Extra large radius
  static const double borderRadiusCircular = 999.0; // Circular

  // Border Width
  static const double borderWidthThin = 1.0; // Thin border
  static const double borderWidthMedium = 2.0; // Medium border
  static const double borderWidthThick = 3.0; // Thick border

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationLarge = 4.0;
  static const double elevationXLarge = 8.0;

  // Shadows - Light theme
  static const List<BoxShadow> shadowAmbient = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowElevation1 = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 3,
      spreadRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowElevation2 = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 5,
      spreadRadius: 1,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowElevation3 = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      spreadRadius: 1,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> shadowElevation4 = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 12,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 12),
    ),
  ];

  // Shadows - Dark theme
  static const List<BoxShadow> darkShadowAmbient = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 2,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> darkShadowElevation1 = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 3,
      spreadRadius: 1,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> darkShadowElevation2 = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 5,
      spreadRadius: 1,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkShadowElevation3 = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 8,
      spreadRadius: 1,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> darkShadowElevation4 = [
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 12,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 12),
    ),
  ];

  // Animation
  static const Duration durationFast = Duration(
    milliseconds: 100,
  ); // Quick feedback
  static const Duration durationShort = Duration(
    milliseconds: 200,
  ); // Simple animations
  static const Duration durationMedium = Duration(
    milliseconds: 300,
  ); // Standard animations
  static const Duration durationLong = Duration(
    milliseconds: 500,
  ); // Complex animations
  static const Duration durationXLong = Duration(
    milliseconds: 800,
  ); // Page transitions

  static const Curve curveStandard = Curves.easeOutCubic; // Standard easing
  static const Curve curveAccelerate =
      Curves.easeInCubic; // Accelerating easing
  static const Curve curveDecelerate =
      Curves.easeOutCubic; // Decelerating easing
  static const Curve curveSharp = Curves.easeInOutCubic; // Sharp easing
  static const Curve curveEmphasized =
      Curves.easeInOutCubic; // Emphasized easing
  static const Curve curveBounce = Curves.elasticOut; // Bouncy easing
}
