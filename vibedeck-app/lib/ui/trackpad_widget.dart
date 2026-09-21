import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      children: [
        // Quick control header (Sensitivity + Status)
        Container(
          height: isLandscape ? 26 : 38,
          padding: EdgeInsets.symmetric(horizontal: isLandscape ? 10 : 16, vertical: isLandscape ? 1 : 6),
          color: VibeTheme.surfaceHighlight.withOpacity(0.3),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, color: VibeTheme.cyanNeon, size: isLandscape ? 15 : 18),
              const SizedBox(width: 6),
              Text(
                "Touchpad Remote",
                style: TextStyle(fontSize: isLandscape ? 10.5 : 12, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const Spacer(),
              Text("Speed:", style: TextStyle(fontSize: isLandscape ? 9.5 : 10.5, color: Colors.grey)),
              SizedBox(
                width: isLandscape ? 85 : 110,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: isLandscape ? 4 : 5),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: isLandscape ? 8 : 10),
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

        // Main Trackpad Surface + Scroll Strip (Expands to fill full available space)
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, isLandscape ? 4 : 8, 8, isLandscape ? 4 : 8),
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
                          HapticFeedback.lightImpact();
                          _conn.sendMouseClick('left');
                        },
                        onDoubleTap: () {
                          HapticFeedback.mediumImpact();
                          _conn.sendMouseClick('left', doubleClick: true);
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          _conn.sendMouseClick('right');
                        },
                        child: Stack(
                          children: [
                            // Subtle background guide
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mouse_rounded,
                                    size: isLandscape ? 28 : 40,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isLandscape
                                        ? "Tap = Left Click  •  2-Tap = Right Click  •  Double Tap = Double Click"
                                        : "Tap = Left Click  •  2-Tap / Long Press = Right Click\nDouble Tap = Double Click",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.22),
                                      fontSize: isLandscape ? 9.5 : 10.5,
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

                // 2. Vertical Scroll Strip (FittedBox & Overflow-Proof)
                Container(
                  width: isLandscape ? 38 : 44,
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
                        final dy = -details.delta.dy * 0.08;
                        _conn.sendMouseScroll(dy);
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final stripH = constraints.maxHeight;
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              height: stripH,
                              width: isLandscape ? 38 : 44,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Icon(Icons.arrow_drop_up_rounded, color: VibeTheme.blueNeon, size: isLandscape ? 20 : 24),
                                  ),
                                  if (stripH > 130)
                                    RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        "SCROLL",
                                        style: TextStyle(
                                          color: VibeTheme.blueNeon.withOpacity(0.5),
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(Icons.unfold_more_rounded, color: VibeTheme.blueNeon.withOpacity(0.4), size: 16),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.arrow_drop_down_rounded, color: VibeTheme.blueNeon, size: isLandscape ? 20 : 24),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Mouse Buttons (Left, Middle, Right Click)
        Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, isLandscape ? 4 : 8),
          child: Row(
            children: [
              // Left Click Pad
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTapDown: (_) {
                    HapticFeedback.lightImpact();
                    setState(() => _isClickPressed = true);
                  },
                  onTapUp: (_) {
                    setState(() => _isClickPressed = false);
                    _conn.sendMouseClick('left');
                  },
                  onTapCancel: () => setState(() => _isClickPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 70),
                    height: isLandscape ? 34 : 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.crop_square_rounded, size: isLandscape ? 13 : 15, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text("LEFT CLICK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isLandscape ? 10.5 : 11.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Middle Click Pad
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _conn.sendMouseClick('middle');
                },
                child: Container(
                  height: isLandscape ? 34 : 50,
                  width: isLandscape ? 38 : 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFF181A26),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Center(
                    child: Icon(Icons.circle_outlined, size: isLandscape ? 14 : 16, color: Colors.white60),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Right Click Pad
              Expanded(
                flex: 3,
                child: GestureDetector(
                  onTapDown: (_) {
                    HapticFeedback.lightImpact();
                    setState(() => _isRightClickPressed = true);
                  },
                  onTapUp: (_) {
                    setState(() => _isRightClickPressed = false);
                    _conn.sendMouseClick('right');
                  },
                  onTapCancel: () => setState(() => _isRightClickPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 70),
                    height: isLandscape ? 34 : 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.crop_portrait_rounded, size: isLandscape ? 13 : 15, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text("RIGHT CLICK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isLandscape ? 10.5 : 11.5)),
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
