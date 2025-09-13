import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
            ? const _StaggeredDotsLoader()
            : Text(
              label,
              style: TextStyle(
                color: textColor ?? Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            );

    final content = Center(child: child);

    if (useGradient) {
      final gradient = const LinearGradient(
        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
      );
      final button = InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          height: 50,
          child: Center(
            child:
                isLoading
                    ? content
                    : DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      child: content,
                    ),
          ),
        ),
      );
      return expanded
          ? SizedBox(width: double.infinity, child: button)
          : button;
    } else {
      final button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
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

class _StaggeredDotsLoader extends StatelessWidget {
  const _StaggeredDotsLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.staggeredDotsWave(
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
