import 'package:flutter/material.dart';

/// App animations
class AppAnimations {
  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double begin = 0.0,
    double end = 1.0,
    bool animate = true,
  }) {
    if (!animate) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  /// Slide in animation
  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Offset begin = const Offset(0.0, 0.2),
    Offset end = Offset.zero,
    bool animate = true,
  }) {
    if (!animate) return child;

    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value.dx * 100, value.dy * 100),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale in animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double begin = 0.8,
    double end = 1.0,
    bool animate = true,
  }) {
    if (!animate) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }

  /// Combined fade and slide animation
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    Offset slideBegin = const Offset(0.0, 0.2),
    Offset slideEnd = Offset.zero,
    double fadeBegin = 0.0,
    double fadeEnd = 1.0,
    bool animate = true,
  }) {
    if (!animate) return child;

    return fadeIn(
      begin: fadeBegin,
      end: fadeEnd,
      duration: duration,
      curve: curve,
      child: slideIn(
        begin: slideBegin,
        end: slideEnd,
        duration: duration,
        curve: curve,
        child: child,
      ),
    );
  }

  /// Staggered list animation
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration initialDelay = Duration.zero,
    Duration staggerDuration = const Duration(milliseconds: 50),
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    bool animate = true,
  }) {
    if (!animate) return children;

    return List.generate(children.length, (index) {
      final delay = initialDelay + (staggerDuration * index);

      return AnimatedBuilder(
        animation: AlwaysStoppedAnimation(0),
        builder: (context, child) {
          return FutureBuilder(
            future: Future.delayed(delay),
            builder: (context, snapshot) {
              final isDelayComplete =
                  snapshot.connectionState == ConnectionState.done;

              return fadeSlideIn(
                animate: isDelayComplete,
                duration: animationDuration,
                curve: curve,
                child: children[index],
              );
            },
          );
        },
      );
    });
  }
}
