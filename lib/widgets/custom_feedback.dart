import 'package:flutter/material.dart';

enum FeedbackType { success, error, warning, info }

class CustomFeedback extends StatefulWidget {
  final String message;
  final FeedbackType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const CustomFeedback({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<CustomFeedback> createState() => _CustomFeedbackState();
}

class _CustomFeedbackState extends State<CustomFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case FeedbackType.success:
        return const Color(0xFF10B981); // Green
      case FeedbackType.error:
        return const Color(0xFFEF4444); // Red
      case FeedbackType.warning:
        return const Color(0xFFF59E0B); // Orange
      case FeedbackType.info:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  Color _getIconColor() {
    return Colors.white;
  }

  IconData _getIcon() {
    switch (widget.type) {
      case FeedbackType.success:
        return Icons.check_circle_rounded;
      case FeedbackType.error:
        return Icons.error_rounded;
      case FeedbackType.warning:
        return Icons.warning_rounded;
      case FeedbackType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
  color: _getBackgroundColor().withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _dismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIcon(),
                            color: _getIconColor(),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Message
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Close button
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FeedbackOverlay extends StatefulWidget {
  final Widget child;

  const FeedbackOverlay({super.key, required this.child});

  @override
  State<FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<FeedbackOverlay> {
  final List<CustomFeedback> _feedbacks = [];

  void showFeedback({
    required String message,
    required FeedbackType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomFeedback? feedbackWidget;

    feedbackWidget = CustomFeedback(
      message: message,
      type: type,
      duration: duration,
      onDismiss: () {
        setState(() {
          _feedbacks.removeWhere((f) => f == feedbackWidget);
        });
      },
    );

    setState(() {
      _feedbacks.add(feedbackWidget!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_feedbacks.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Column(children: _feedbacks),
          ),
      ],
    );
  }
}

// Extension to easily show feedback
extension FeedbackExtension on BuildContext {
  void showSuccessFeedback(String message) {
    _showFeedback(message: message, type: FeedbackType.success);
  }

  void showErrorFeedback(String message) {
    _showFeedback(message: message, type: FeedbackType.error);
  }

  void showWarningFeedback(String message) {
    _showFeedback(message: message, type: FeedbackType.warning);
  }

  void showInfoFeedback(String message) {
    _showFeedback(message: message, type: FeedbackType.info);
  }

  void _showFeedback({required String message, required FeedbackType type}) {
    final overlay = Overlay.of(this);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: CustomFeedback(
              message: message,
              type: type,
              onDismiss: () {
                overlayEntry.remove();
              },
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after duration
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
