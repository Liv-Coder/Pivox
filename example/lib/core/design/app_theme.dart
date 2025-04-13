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
    return ThemeData(
      useMaterial3: true,
      fontFamily: DesignTokens.fontFamily,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: DesignTokens.darkPrimaryColor,
        onPrimary: Colors.white,
        primaryContainer: DesignTokens.darkPrimaryColorLight,
        onPrimaryContainer: Colors.white,
        secondary: DesignTokens.darkSecondaryColor,
        onSecondary: Colors.black,
        secondaryContainer: DesignTokens.darkSecondaryColorLight,
        onSecondaryContainer: Colors.black,
        tertiary: DesignTokens.darkWarningColor,
        onTertiary: Colors.black,
        tertiaryContainer: DesignTokens.darkWarningColor,
        onTertiaryContainer: Colors.black,
        error: DesignTokens.darkErrorColor,
        onError: Colors.white,
        errorContainer: DesignTokens.darkErrorColor,
        onErrorContainer: Colors.white,
        surface: DesignTokens.darkSurfaceColor,
        onSurface: DesignTokens.darkTextPrimaryColor,
        surfaceContainerHighest: DesignTokens.darkCardColor,
        onSurfaceVariant: DesignTokens.darkTextSecondaryColor,
        outline: DesignTokens.darkDividerColor,
        outlineVariant: DesignTokens.darkDividerColor,
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: DesignTokens.darkTextPrimaryColor,
        onInverseSurface: DesignTokens.darkSurfaceColor,
        inversePrimary: DesignTokens.darkPrimaryColorLight,
        surfaceTint: DesignTokens.darkPrimaryColor,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: DesignTokens.fontSizeXXXLarge,
          fontWeight: DesignTokens.fontWeightBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: DesignTokens.fontSizeXXLarge,
          fontWeight: DesignTokens.fontWeightBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: DesignTokens.fontSizeXLarge,
          fontWeight: DesignTokens.fontWeightBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        headlineLarge: TextStyle(
          fontSize: DesignTokens.fontSizeXXLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: DesignTokens.fontSizeXLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: DesignTokens.fontSizeLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: DesignTokens.fontSizeLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        titleSmall: TextStyle(
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: DesignTokens.fontSizeXSmall,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextSecondaryColor,
        ),
        labelLarge: TextStyle(
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        labelMedium: TextStyle(
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.darkTextPrimaryColor,
        ),
        labelSmall: TextStyle(
          fontSize: DesignTokens.fontSizeXSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.darkTextSecondaryColor,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.darkSurfaceColor,
        foregroundColor: DesignTokens.darkTextPrimaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeLarge,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.darkTextPrimaryColor,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: DesignTokens.darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          side: const BorderSide(
            color: DesignTokens.darkDividerColor,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(DesignTokens.spacingSmall),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.darkPrimaryColor,
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
          foregroundColor: DesignTokens.darkPrimaryColor,
          side: const BorderSide(
            color: DesignTokens.darkPrimaryColor,
            width: 1,
          ),
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
          foregroundColor: DesignTokens.darkPrimaryColor,
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
        fillColor: DesignTokens.darkSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMedium,
          vertical: DesignTokens.spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.darkDividerColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.darkDividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.darkPrimaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.darkErrorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
          borderSide: const BorderSide(
            color: DesignTokens.darkErrorColor,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextSecondaryColor,
        ),
        hintStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextTertiaryColor,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: DesignTokens.darkDividerColor,
        thickness: 1,
        space: DesignTokens.spacingMedium,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: DesignTokens.darkSurfaceColor,
        disabledColor: DesignTokens.darkDividerColor,
        selectedColor: DesignTokens.darkPrimaryColorLight,
        secondarySelectedColor: DesignTokens.darkPrimaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSmall,
          vertical: DesignTokens.spacingXSmall,
        ),
        labelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeSmall,
          fontWeight: DesignTokens.fontWeightMedium,
          color: DesignTokens.darkTextPrimaryColor,
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
          side: const BorderSide(
            color: DesignTokens.darkDividerColor,
            width: 1,
          ),
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
      scaffoldBackgroundColor: DesignTokens.darkBackgroundColor,

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: DesignTokens.darkTextPrimaryColor,
        contentTextStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: DesignTokens.fontSizeMedium,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkSurfaceColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DesignTokens.darkPrimaryColor,
        circularTrackColor: DesignTokens.darkDividerColor,
        linearTrackColor: DesignTokens.darkDividerColor,
      ),
    );
  }
}
