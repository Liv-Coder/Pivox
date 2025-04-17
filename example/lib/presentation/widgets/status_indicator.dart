import 'package:flutter/material.dart';

/// Types of status indicators
enum StatusIndicatorType {
  /// Success status
  success,

  /// Warning status
  warning,

  /// Error status
  error,

  /// Info status
  info,

  /// Neutral status
  neutral,

  /// Loading status
  loading,
}

/// A widget that displays a status indicator
class StatusIndicator extends StatelessWidget {
  /// The type of status indicator
  final StatusIndicatorType type;

  /// The label to display
  final String label;

  /// Whether to animate the indicator
  final bool animate;

  /// The size of the indicator
  final double size;

  /// Creates a new [StatusIndicator]
  const StatusIndicator({
    super.key,
    required this.type,
    required this.label,
    this.animate = false,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIndicator(),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  /// Builds the indicator
  Widget _buildIndicator() {
    Color color;
    IconData? icon;
    bool showProgress = false;

    switch (type) {
      case StatusIndicatorType.success:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case StatusIndicatorType.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case StatusIndicatorType.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case StatusIndicatorType.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
      case StatusIndicatorType.neutral:
        color = Colors.grey;
        icon = Icons.circle;
        break;
      case StatusIndicatorType.loading:
        color = Colors.blue;
        showProgress = true;
        break;
    }

    if (showProgress) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (animate) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: icon != null
            ? Icon(
                icon,
                color: Colors.white,
                size: size * 0.8,
              )
            : null,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(
              icon,
              color: Colors.white,
              size: size * 0.8,
            )
          : null,
    );
  }
}

/// A widget that displays a status badge
class StatusBadge extends StatelessWidget {
  /// The type of status indicator
  final StatusIndicatorType type;

  /// The label to display
  final String label;

  /// Whether to animate the indicator
  final bool animate;

  /// Creates a new [StatusBadge]
  const StatusBadge({
    super.key,
    required this.type,
    required this.label,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (type) {
      case StatusIndicatorType.success:
        color = Colors.green;
        break;
      case StatusIndicatorType.warning:
        color = Colors.orange;
        break;
      case StatusIndicatorType.error:
        color = Colors.red;
        break;
      case StatusIndicatorType.info:
        color = Colors.blue;
        break;
      case StatusIndicatorType.neutral:
        color = Colors.grey;
        break;
      case StatusIndicatorType.loading:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusIndicator(
            type: type,
            label: '',
            animate: animate,
            size: 8,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
