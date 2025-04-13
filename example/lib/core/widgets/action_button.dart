import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

/// A button with an icon and text
class ActionButton extends StatelessWidget {
  /// The text to display on the button
  final String text;

  /// The icon to display on the button
  final IconData icon;

  /// The callback when the button is pressed
  final VoidCallback? onPressed;

  /// Whether the button is loading
  final bool isLoading;

  /// Creates a new [ActionButton] with the given parameters
  const ActionButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMedium,
          vertical: DesignTokens.spacingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Use minimum space needed
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(icon, size: 20),
          const SizedBox(width: DesignTokens.spacingSmall),
          Flexible(
            // Make text flexible to handle overflow
            child: Text(
              text,
              overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
