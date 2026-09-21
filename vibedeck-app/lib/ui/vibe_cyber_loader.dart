import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/vibe_theme.dart';

class VibeCyberLoader extends StatefulWidget {
  final String statusText;
  final double size;

  const VibeCyberLoader({
    super.key,
    this.statusText = "SYNCHRONIZING VIBEDECK MATRIX...",
    this.size = 180,
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
        // Concentric Glowing Cyber Ring + Branded Logo
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi)).clamp(0.0, 1.0);
              return CustomPaint(
                painter: _CyberRingsPainter(progress: _controller.value),
                child: Center(
                  child: Container(
                    width: widget.size * 0.56,
                    height: widget.size * 0.56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: VibeTheme.cyanNeon.withValues(alpha: 0.35 * pulse),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: VibeTheme.purpleNeon.withValues(alpha: 0.25 * (1.0 - pulse)),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/logo.png',
                          width: widget.size * 0.46,
                          height: widget.size * 0.46,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.bolt_rounded,
                            color: VibeTheme.cyanNeon,
                            size: widget.size * 0.40,
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

        const SizedBox(height: 24),

        // Cyber Branded Title
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: VibeTheme.cyanNeon,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "V I B E D E C K",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                letterSpacing: 4.0,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: VibeTheme.cyanNeon, blurRadius: 12),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF2A6D),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        const Text(
          "NATIVE STUDIO CONTROLLER",
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.bold,
            color: Colors.white38,
          ),
        ),

        const SizedBox(height: 18),

        // Neon Pulse Status Text
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity = (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi).abs()).clamp(0.4, 1.0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VibeTheme.cyanNeon.withValues(alpha: 0.25)),
              ),
              child: Text(
                widget.statusText,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: VibeTheme.cyanNeon.withValues(alpha: opacity),
                  shadows: [
                    Shadow(
                      color: VibeTheme.cyanNeon.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
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
      ..color = const Color(0xFFFF2A6D).withValues(alpha: 0.85);

    final innerRadius = radius - 14;
    const int segments = 6;
    const double sweep = (2 * math.pi / segments) * 0.55;
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

    // 4 Corner Accent Orbiting Dots
    final dotPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + (progress * math.pi);
      final dx = center.dx + (radius - 8) * math.cos(angle);
      final dy = center.dy + (radius - 8) * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
