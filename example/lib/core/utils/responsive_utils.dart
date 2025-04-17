import 'package:flutter/material.dart';

/// Device screen types
enum DeviceScreenType { mobile, tablet, desktop }

/// Responsive utilities
class ResponsiveUtils {
  /// Get device screen type based on width
  static DeviceScreenType getDeviceScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return DeviceScreenType.mobile;
    } else if (width < 1200) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceScreenType(context) == DeviceScreenType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceScreenType(context) == DeviceScreenType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceScreenType(context) == DeviceScreenType.desktop;
  }

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenType = getDeviceScreenType(context);

    switch (screenType) {
      case DeviceScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceScreenType.tablet:
        return tablet ?? mobile;
      case DeviceScreenType.mobile:
        return mobile;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
    );
  }

  /// Get responsive horizontal padding based on screen size
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 48),
      desktop: const EdgeInsets.symmetric(horizontal: 64),
    );
  }

  /// Get responsive grid column count based on screen size
  static int getResponsiveGridCount(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? tabletFontSizeMultiplier,
    double? desktopFontSizeMultiplier,
  }) {
    final tabletMultiplier = tabletFontSizeMultiplier ?? 1.1;
    final desktopMultiplier = desktopFontSizeMultiplier ?? 1.2;

    return getResponsiveValue(
      context: context,
      mobile: baseFontSize,
      tablet: baseFontSize * tabletMultiplier,
      desktop: baseFontSize * desktopMultiplier,
    );
  }
}
