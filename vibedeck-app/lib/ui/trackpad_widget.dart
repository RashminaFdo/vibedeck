import 'package:flutter/material.dart';
import '../services/connection_service.dart';
import '../theme/vibe_theme.dart';

class TrackpadWidget extends StatefulWidget {
  const TrackpadWidget({super.key});

  @override
  State<TrackpadWidget> createState() => _TrackpadWidgetState();
}

class _TrackpadWidgetState extends State<TrackpadWidget> {
  final ConnectionService _conn = ConnectionService();
  double _sensitivity = 1.3;
  bool _isClickPressed = false;
  bool _isRightClickPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick control header (Sensitivity + Status)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: VibeTheme.surfaceHighlight.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: VibeTheme.cyanNeon, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Touchpad Remote",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const Spacer(),
              const Text("Speed:", style: TextStyle(fontSize: 10.5, color: Colors.grey)),
              SizedBox(
                width: 110,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: VibeTheme.cyanNeon,
                    thumbColor: VibeTheme.cyanNeon,
                  ),
                  child: Slider(
                    value: _sensitivity,
                    min: 0.5,
                    max: 2.5,
                    onChanged: (v) => setState(() => _sensitivity = v),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Trackpad Surface + Scroll Strip
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                // 1. Touchpad Main Canvas
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10121B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: VibeTheme.cyanNeon.withOpacity(0.2), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          final dx = details.delta.dx * _sensitivity;
                          final dy = details.delta.dy * _sensitivity;
                          _conn.sendTrackpadMove(dx, dy);
                        },
                        onTap: () {
                          _conn.sendMouseClick('left');
                        },
                        onDoubleTap: () {
                          _conn.sendMouseClick('left', doubleClick: true);
                        },
                        onLongPress: () {
                          _conn.sendMouseClick('right');
                        },
                        child: Stack(
                          children: [
                            // Subtle background grid guide
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mouse_rounded,
                                    size: 40,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Tap = Left Click  •  2-Tap / Long Press = Right Click\nDouble Tap = Double Click",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.22),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Vertical Scroll Strip
                Container(
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121420),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VibeTheme.blueNeon.withOpacity(0.25), width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        // Scroll inverted naturally (dragging down scrolls down on page)
                        final dy = -details.delta.dy * 0.08;
                        _conn.sendMouseScroll(dy);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: const Icon(Icons.arrow_drop_up_rounded, color: VibeTheme.blueNeon, size: 24),
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              "SCROLL",
                              style: TextStyle(
                                color: VibeTheme.blueNeon.withOpacity(0.5),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: const Icon(Icons.arrow_drop_down_rounded, color: VibeTheme.blueNeon, size: 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Left & Right Click Pads
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Row(
            children: [
              // Left Click Pad
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isClickPressed = true),
                  onTapUp: (_) {
                    setState(() => _isClickPressed = false);
                    _conn.sendMouseClick('left');
                  },
                  onTapCancel: () => setState(() => _isClickPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 70),
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: _isClickPressed
                            ? [VibeTheme.cyanNeon.withOpacity(0.5), VibeTheme.cyanNeon.withOpacity(0.3)]
                            : [const Color(0xFF1E2235), const Color(0xFF151824)],
                      ),
                      border: Border.all(
                        color: _isClickPressed ? VibeTheme.cyanNeon : VibeTheme.cyanNeon.withOpacity(0.3),
                        width: _isClickPressed ? 1.8 : 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.crop_square_rounded, size: 16, color: Colors.white70),
                          SizedBox(width: 6),
                          Text("LEFT CLICK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Middle Click Pad
              GestureDetector(
                onTap: () => _conn.sendMouseClick('middle'),
                child: Container(
                  height: 52,
                  width: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF181A26),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: const Center(
                    child: Icon(Icons.circle_outlined, size: 18, color: Colors.white60),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right Click Pad
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isRightClickPressed = true),
                  onTapUp: (_) {
                    setState(() => _isRightClickPressed = false);
                    _conn.sendMouseClick('right');
                  },
                  onTapCancel: () => setState(() => _isRightClickPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 70),
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: _isRightClickPressed
                            ? [VibeTheme.purpleNeon.withOpacity(0.5), VibeTheme.purpleNeon.withOpacity(0.3)]
                            : [const Color(0xFF1E2235), const Color(0xFF151824)],
                      ),
                      border: Border.all(
                        color: _isRightClickPressed ? VibeTheme.purpleNeon : VibeTheme.purpleNeon.withOpacity(0.3),
                        width: _isRightClickPressed ? 1.8 : 1.0,
                      ),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.crop_portrait_rounded, size: 16, color: Colors.white70),
                          SizedBox(width: 6),
                          Text("RIGHT CLICK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
