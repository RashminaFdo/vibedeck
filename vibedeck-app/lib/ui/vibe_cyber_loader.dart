import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/vibe_theme.dart';

class VibeCyberLoader extends StatefulWidget {
  final String statusText;
  final double size;

  const VibeCyberLoader({
    super.key,
    this.statusText = "INITIALIZING VIBEDECK...",
    this.size = 110,
  });

  @override
  State<VibeCyberLoader> createState() => _VibeCyberLoaderState();
}

class _VibeCyberLoaderState extends State<VibeCyberLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _CyberRingsPainter(progress: _controller.value),
                child: Center(
                  child: Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          VibeTheme.cyanNeon.withOpacity(0.5 + 0.3 * math.sin(_controller.value * 2 * math.pi)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/logo.png',
                          width: widget.size * 0.28,
                          height: widget.size * 0.28,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.bolt_rounded,
                            color: VibeTheme.cyanNeon,
                            size: widget.size * 0.28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        // Neon pulse status text
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity = 0.6 + 0.4 * math.sin(_controller.value * 2 * math.pi).abs();
            return Text(
              widget.statusText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w800,
                color: VibeTheme.cyanNeon.withOpacity(opacity),
                shadows: [
                  Shadow(
                    color: VibeTheme.cyanNeon.withOpacity(0.6),
                    blurRadius: 10,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CyberRingsPainter extends CustomPainter {
  final double progress;

  _CyberRingsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Neon Ring (Rotating Clockwise)
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          VibeTheme.cyanNeon,
          Colors.transparent,
          VibeTheme.purpleNeon,
          Colors.transparent,
          VibeTheme.cyanNeon,
        ],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius - 4));

    canvas.drawCircle(center, radius - 4, outerPaint);

    // Segmented Inner Ring (Rotating Counter-Clockwise)
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF2A6D).withOpacity(0.85);

    final innerRadius = radius - 14;
    final int segments = 6;
    final double sweep = (2 * math.pi / segments) * 0.55;
    final double baseAngle = -progress * 2 * math.pi;

    for (int i = 0; i < segments; i++) {
      final double startAngle = baseAngle + (i * 2 * math.pi / segments);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweep,
        false,
        innerPaint,
      );
    }

    // 4 Corner Accent Dots
    final dotPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + (progress * math.pi);
      final dx = center.dx + (radius - 8) * math.cos(angle);
      final dy = center.dy + (radius - 8) * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
