import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// App theme provider that creates ThemeData objects based on design tokens
class AppTheme {
  /// Creates a light theme using the design tokens
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: DesignTokens.fontFamily,

      // Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: DesignTokens.primaryColor,
        onPrimary: Colors.white,
        primaryContainer: DesignTokens.primaryColorLight,
        onPrimaryContainer: Colors.white,
        secondary: DesignTokens.secondaryColor,
        onSecondary: Colors.black,
        secondaryContainer: DesignTokens.secondaryColorLight,
        onSecondaryContainer: Colors.black,
        tertiary: DesignTokens.warningColor,
        onTertiary: Colors.white,
        tertiaryContainer: DesignTokens.warningColor,
        onTertiaryContainer: Colors.white,
        error: DesignTokens.errorColor,
        onError: Colors.white,
        errorContainer: DesignTokens.errorColor,
        onErrorContainer: Colors.white,
        surface: DesignTokens.surfaceColor,
        onSurface: DesignTokens.textPrimaryColor,
        surfaceContainerHighest: DesignTokens.cardColor,
        onSurfaceVariant: DesignTokens.textSecondaryColor,
        outline: DesignTokens.dividerColor,
        outlineVariant: DesignTokens.dividerColor,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: DesignTokens.textPrimaryColor,
        onInverseSurface: DesignTokens.surfaceColor,
        inversePrimary: DesignTokens.primaryColorLight,
        surfaceTint: DesignTokens.primaryColor,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: DesignTokens.fontSizeXXXLarge,
          fontWeight: DesignTokens.fontWeightBold,
          color: DesignTokens.textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: DesignTokens.fontSizeXXLarge,
          fontWeight: DesignTokens.fontWeightBold,
          color: DesignTokens.textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: DesignTokens.fontSizeXLarge,
          fontWeight: DesignTokens.fontWeightBold,
          color: DesignTokens.textPrimaryColor,
        ),
        headlineLarge: TextStyle(
          fontSize: DesignTokens.fontSizeXXLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: DesignTokens.fontSizeXLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.textPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: DesignTokens.fontSizeLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: DesignTokens.fontSizeLarge,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.textPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: DesignTokens.fontSizeXSmall,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.textSecondaryColor,
        ),
        labelLarge: TextStyle(
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textPrimaryColor,
        ),
        labelMedium: TextStyle(
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textPrimaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: DesignTokens.fontSizeXSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textSecondaryColor,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.surfaceColor,
        foregroundColor: DesignTokens.textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.textPrimaryColor,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: DesignTokens.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          side: const BorderSide(color: DesignTokens.dividerColor, width: 1),
        ),
        margin: const EdgeInsets.all(DesignTokens.spacingSmall),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLarge,
            vertical: DesignTokens.spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              DesignTokens.borderRadiusMedium,
            ),
          ),
          textStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeMedium,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.primaryColor,
          side: const BorderSide(color: DesignTokens.primaryColor, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLarge,
            vertical: DesignTokens.spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              DesignTokens.borderRadiusMedium,
            ),
          ),
          textStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeMedium,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: DesignTokens.primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMedium,
            vertical: DesignTokens.spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              DesignTokens.borderRadiusMedium,
            ),
          ),
          textStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeMedium,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMedium,
          vertical: DesignTokens.spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.dividerColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.errorColor,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.textSecondaryColor,
        ),
        hintStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.textTertiaryColor,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: DesignTokens.dividerColor,
        thickness: 1,
        space: DesignTokens.spacingMedium,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.surfaceColor,
        disabledColor: DesignTokens.dividerColor,
        selectedColor: DesignTokens.primaryColorLight,
        secondarySelectedColor: DesignTokens.primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSmall,
          vertical: DesignTokens.spacingXSmall,
        ),
        labelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.textPrimaryColor,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            DesignTokens.borderRadiusCircular,
          ),
          side: const BorderSide(color: DesignTokens.dividerColor, width: 1),
        ),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMedium,
          vertical: DesignTokens.spacingSmall,
        ),
        minLeadingWidth: 24,
        minVerticalPadding: DesignTokens.spacingSmall,
      ),

      // Scaffold Background Color
      scaffoldBackgroundColor: DesignTokens.backgroundColor,

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DesignTokens.textPrimaryColor,
        contentTextStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DesignTokens.primaryColor,
        circularTrackColor: DesignTokens.dividerColor,
        linearTrackColor: DesignTokens.dividerColor,
      ),
    );
  }

  /// Creates a dark theme using the design tokens
  static ThemeData darkTheme() {
    // For now, we'll just return the light theme
    // In a real app, you would create a proper dark theme
    return lightTheme();
  }
}
