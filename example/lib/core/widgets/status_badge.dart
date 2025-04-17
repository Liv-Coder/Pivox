import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';

/// Status badge types
enum StatusType { success, warning, error, info, neutral }

/// Status badge widget
class StatusBadge extends StatelessWidget {
  final StatusType type;
  final String text;
  final IconData? icon;
  final bool animated;

  const StatusBadge({
    super.key,
    required this.type,
    required this.text,
    this.icon,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            if (animated && type == StatusType.warning)
              _buildPulsingIcon()
            else if (animated && type == StatusType.error)
              _buildShakingIcon()
            else
              Icon(icon, size: 14, color: _getIconColor()),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Icon(icon, size: 14, color: _getIconColor()),
    );
  }

  Widget _buildShakingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(value * 2, 0), child: child);
      },
      child: Icon(icon, size: 14, color: _getIconColor()),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
      case StatusType.success:
        return AppColors.success.withAlpha(25);
      case StatusType.warning:
        return AppColors.warning.withAlpha(25);
      case StatusType.error:
        return AppColors.error.withAlpha(25);
      case StatusType.info:
        return AppColors.info.withAlpha(25);
      case StatusType.neutral:
        return AppColors.textTertiary.withAlpha(25);
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case StatusType.success:
        return AppColors.success.withAlpha(77);
      case StatusType.warning:
        return AppColors.warning.withAlpha(77);
      case StatusType.error:
        return AppColors.error.withAlpha(77);
      case StatusType.info:
        return AppColors.info.withAlpha(77);
      case StatusType.neutral:
        return AppColors.textTertiary.withAlpha(77);
    }
  }

  Color _getIconColor() {
    switch (type) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
      case StatusType.info:
        return AppColors.info;
      case StatusType.neutral:
        return AppColors.textSecondary;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case StatusType.success:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
      case StatusType.info:
        return AppColors.info;
      case StatusType.neutral:
        return AppColors.textSecondary;
    }
  }
}
