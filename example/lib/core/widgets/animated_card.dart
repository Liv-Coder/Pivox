import 'package:flutter/material.dart';
import '../design/app_spacing.dart';

/// Animated card widget with hover and tap effects
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;
  final double hoverElevation;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableHover;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevation = 1,
    this.hoverElevation = 3,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.enableHover = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHover ? (_) => _updateHoverState(true) : null,
      onExit: widget.enableHover ? (_) => _updateHoverState(false) : null,
      child: AnimatedContainer(
        duration: AppSpacing.shortAnimation,
        curve: Curves.easeInOut,
        margin: widget.margin ?? const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: widget.color ?? Theme.of(context).cardTheme.color,
          borderRadius:
              widget.borderRadius ??
              BorderRadius.circular(AppSpacing.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(_isHovered ? 38 : 25),
              blurRadius:
                  _isHovered ? widget.hoverElevation * 2 : widget.elevation * 2,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        transform:
            _isHovered
                ? Matrix4.translationValues(0, -2, 0)
                : Matrix4.translationValues(0, 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius:
                widget.borderRadius ??
                BorderRadius.circular(AppSpacing.cardBorderRadius),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  void _updateHoverState(bool isHovered) {
    if (mounted && widget.onTap != null) {
      setState(() {
        _isHovered = isHovered;
      });
    }
  }
}
