import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated multi-layered wave background that provides a flowing financial aesthetic
class AnimatedWaveBackground extends StatefulWidget {
  const AnimatedWaveBackground({
    super.key,
    required this.child,
    this.waveColor = Colors.white,
    this.waveOpacity1 = 0.08,
    this.waveOpacity2 = 0.05,
    this.height,
  });

  final Widget child;
  final Color waveColor;
  final double waveOpacity1;
  final double waveOpacity2;
  final double? height;

  @override
  State<AnimatedWaveBackground> createState() => _AnimatedWaveBackgroundState();
}

class _AnimatedWaveBackgroundState extends State<AnimatedWaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Animated wave painter positioned in bottom half
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MultiWavePainter(
                    progress: _controller.value,
                    waveColor: widget.waveColor,
                    opacity1: widget.waveOpacity1,
                    opacity2: widget.waveOpacity2,
                  ),
                );
              },
            ),
          ),
          // Content layered on top
          widget.child,
        ],
      ),
    );
  }
}

class _MultiWavePainter extends CustomPainter {
  _MultiWavePainter({
    required this.progress,
    required this.waveColor,
    required this.opacity1,
    required this.opacity2,
  });

  final double progress;
  final Color waveColor;
  final double opacity1;
  final double opacity2;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Primary gentle wave
    final paint1 = Paint()
      ..color = waveColor.withValues(alpha: opacity1)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, h);

    final shift1 = progress * 2 * math.pi;
    for (double x = 0; x <= w; x += 3) {
      final y = math.sin((x / w * 2 * math.pi) + shift1) * 14 + (h * 0.70);
      path1.lineTo(x, y);
    }
    path1.lineTo(w, h);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Layer 2: Secondary offset faster wave
    final paint2 = Paint()
      ..color = waveColor.withValues(alpha: opacity2)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, h);

    final shift2 = -progress * 2 * math.pi * 1.3;
    for (double x = 0; x <= w; x += 3) {
      final y = math.cos((x / w * 2.5 * math.pi) + shift2) * 10 + (h * 0.76);
      path2.lineTo(x, y);
    }
    path2.lineTo(w, h);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _MultiWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
