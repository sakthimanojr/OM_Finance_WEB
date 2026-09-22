import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated Premium Button with scale-down press effect, gradient fill, and shimmer sweep
class AnimatedGradientButton extends StatefulWidget {
  const AnimatedGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.height = 52,
    this.borderRadius = 14,
    this.isLoading = false,
    this.icon,
    this.showShimmer = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final IconData? icon;
  final bool showShimmer;

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    if (widget.showShimmer) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _shimmerController.repeat(period: const Duration(seconds: 3));
        }
      });
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = widget.gradient ?? AppTheme.darkGradient;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  )
                : effectiveGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.buttonBlack.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // Shimmer sweep overlay
                if (widget.showShimmer && !isDisabled)
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, _) {
                      return Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(
                            _shimmerAnimation.value *
                                MediaQuery.of(context).size.width,
                            0,
                          ),
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                // Button content
                Material(
                  color: Colors.transparent,
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                              ],
                              DefaultTextStyle(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                                child: widget.child,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Glassmorphic Card Container with subtle border glow and drop shadow
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.grey.shade100,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
