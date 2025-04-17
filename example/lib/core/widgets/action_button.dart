import 'package:flutter/material.dart';
import '../design/app_spacing.dart';

/// Button types
enum ActionButtonType { primary, secondary, outline, text }

/// Action button widget
class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final ActionButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const ActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.type = ActionButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ActionButtonType.primary:
        return _buildElevatedButton(context);
      case ActionButtonType.secondary:
        return _buildSecondaryButton(context);
      case ActionButtonType.outline:
        return _buildOutlinedButton(context);
      case ActionButtonType.text:
        return _buildTextButton(context);
    }
  }

  Widget _buildElevatedButton(BuildContext context) {
    return SizedBox(
      width: _getWidth(),
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ??
                BorderRadius.circular(AppSpacing.buttonBorderRadius),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withAlpha(153),
          disabledForegroundColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withAlpha(204),
        ),
        child: _buildButtonContent(
          context,
          Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return SizedBox(
      width: _getWidth(),
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ??
                BorderRadius.circular(AppSpacing.buttonBorderRadius),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          disabledBackgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withAlpha(153),
          disabledForegroundColor: Theme.of(
            context,
          ).colorScheme.onSecondary.withAlpha(204),
        ),
        child: _buildButtonContent(
          context,
          Theme.of(context).colorScheme.onSecondary,
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    return SizedBox(
      width: _getWidth(),
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ??
                BorderRadius.circular(AppSpacing.buttonBorderRadius),
          ),
          side: BorderSide(
            color:
                isLoading
                    ? Theme.of(context).colorScheme.primary.withAlpha(128)
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
        child: _buildButtonContent(
          context,
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return SizedBox(
      width: _getWidth(),
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ??
                BorderRadius.circular(AppSpacing.buttonBorderRadius),
          ),
        ),
        child: _buildButtonContent(
          context,
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context, Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  double? _getWidth() {
    if (isFullWidth) {
      return double.infinity;
    }
    return width;
  }
}
