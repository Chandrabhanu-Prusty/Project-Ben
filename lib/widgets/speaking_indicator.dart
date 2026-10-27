import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SpeakingIndicator extends StatefulWidget {
  final bool isSpeaking;
  final bool isThinking;
  final double size;

  const SpeakingIndicator({
    super.key,
    this.isSpeaking = false,
    this.isThinking = false,
    this.size = 28,
  });

  @override
  State<SpeakingIndicator> createState() => _SpeakingIndicatorState();
}

class _SpeakingIndicatorState extends State<SpeakingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSpeaking || widget.isThinking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SpeakingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isSpeaking || widget.isThinking) && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && !widget.isThinking && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isSpeaking || widget.isThinking;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        final scale = active ? _scaleAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.deepBlack,
              border: Border.all(
                color: active ? AppColors.neonGreen : AppColors.subtleGreenGrey,
                width: 2,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.neonGreen.withAlpha(90),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.45,
                height: widget.size * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.neonGreen : AppColors.softGreen,
                ),
                child: active
                    ? const Icon(
                        Icons.graphic_eq,
                        size: 14,
                        color: AppColors.deepBlack,
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
