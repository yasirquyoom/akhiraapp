import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final bool useGradient;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.useGradient = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final child =
        isLoading
            ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
            : Text(
              label,
              style: TextStyle(
                color: textColor ?? Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            );

    final content = Center(child: child);

    final enabled = onPressed != null && !isLoading;

    if (useGradient && enabled) {
      final gradient = const LinearGradient(
        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
      );
      final button = InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          height: 50,
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            child: content,
          ),
        ),
      );
      return expanded
          ? SizedBox(width: double.infinity, child: button)
          : button;
    } else {
      final button = ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: textColor,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: child,
      );
      return expanded
          ? SizedBox(width: double.infinity, child: button)
          : button;
    }
  }
}
