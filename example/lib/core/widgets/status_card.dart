import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../design/design_tokens.dart';

/// Status types for the status card
enum StatusType {
  /// Success status
  success,

  /// Error status
  error,

  /// Warning status
  warning,

  /// Info status
  info,
}

/// A card that displays a status message
class StatusCard extends StatelessWidget {
  /// The status message to display
  final String message;

  /// The type of status
  final StatusType type;

  /// Creates a new [StatusCard] with the given [message] and [type]
  const StatusCard({
    super.key,
    required this.message,
    this.type = StatusType.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingMedium),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: _getIconColor(), size: 24),
          const SizedBox(width: DesignTokens.spacingMedium),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _getTextColor()),
            ),
          ),
        ],
      ),
    );
  }

  /// Gets the background color based on the status type
  Color _getBackgroundColor() {
    switch (type) {
      case StatusType.success:
        return DesignTokens.successColor.withAlpha(25);
      case StatusType.error:
        return DesignTokens.errorColor.withAlpha(25);
      case StatusType.warning:
        return DesignTokens.warningColor.withAlpha(25);
      case StatusType.info:
        return DesignTokens.infoColor.withAlpha(25);
    }
  }

  /// Gets the border color based on the status type
  Color _getBorderColor() {
    switch (type) {
      case StatusType.success:
        return DesignTokens.successColor.withAlpha(75);
      case StatusType.error:
        return DesignTokens.errorColor.withAlpha(75);
      case StatusType.warning:
        return DesignTokens.warningColor.withAlpha(75);
      case StatusType.info:
        return DesignTokens.infoColor.withAlpha(75);
    }
  }

  /// Gets the icon color based on the status type
  Color _getIconColor() {
    switch (type) {
      case StatusType.success:
        return DesignTokens.successColor;
      case StatusType.error:
        return DesignTokens.errorColor;
      case StatusType.warning:
        return DesignTokens.warningColor;
      case StatusType.info:
        return DesignTokens.infoColor;
    }
  }

  /// Gets the text color based on the status type
  Color _getTextColor() {
    switch (type) {
      case StatusType.success:
        return DesignTokens.successColor.withAlpha(204);
      case StatusType.error:
        return DesignTokens.errorColor.withAlpha(204);
      case StatusType.warning:
        return DesignTokens.warningColor.withAlpha(204);
      case StatusType.info:
        return DesignTokens.infoColor.withAlpha(204);
    }
  }

  /// Gets the icon based on the status type
  IconData _getIcon() {
    switch (type) {
      case StatusType.success:
        return Ionicons.checkmark_circle_outline;
      case StatusType.error:
        return Ionicons.alert_circle_outline;
      case StatusType.warning:
        return Ionicons.warning_outline;
      case StatusType.info:
        return Ionicons.information_circle_outline;
    }
  }
}
