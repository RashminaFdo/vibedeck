import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/deck_action.dart';
import '../services/connection_service.dart';

class DeckButtonWidget extends StatefulWidget {
  final DeckButton button;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DeckButtonWidget({
    super.key,
    required this.button,
    required this.isEditMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<DeckButtonWidget> createState() => _DeckButtonWidgetState();
}

class _DeckButtonWidgetState extends State<DeckButtonWidget> {
  bool _isPressed = false;
  final ConnectionService _conn = ConnectionService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _conn,
      builder: (context, _) {
        final isConnected = _conn.state == VibeConnectionState.connected;

        // Reactive Two-Way State Evaluation
        Color effectiveColor = widget.button.color;
        IconData effectiveIcon = widget.button.iconData;
        String effectiveTitle = widget.button.title;
        bool isReactiveActive = false;

        final btnType = widget.button.actionType.toLowerCase();
        final btnTitle = widget.button.title.toLowerCase();
        final payloadKey = (widget.button.payload['key'] ?? '').toString().toLowerCase();

        // 1. Speaker Mute State
        if (btnType == 'mute' || payloadKey == 'volume_mute' || (btnTitle.contains('mute') && !btnTitle.contains('mic'))) {
          if (_conn.isMuted) {
            effectiveColor = const Color(0xFFFF2A6D);
            effectiveIcon = Icons.volume_off_rounded;
            effectiveTitle = "MUTED";
            isReactiveActive = true;
          } else {
            effectiveIcon = Icons.volume_up_rounded;
            effectiveTitle = widget.button.title.isNotEmpty ? widget.button.title : "UNMUTED";
          }
        }
        // 2. Microphone Mute State (Windows OS & Discord)
        else if (btnType == 'mic_mute' || btnTitle.contains('mic')) {
          if (_conn.isMicMuted) {
            effectiveColor = const Color(0xFFFF2A6D);
            effectiveIcon = Icons.mic_off_rounded;
            effectiveTitle = "MIC OFF";
            isReactiveActive = true;
          } else {
            effectiveColor = const Color(0xFF00FF88);
            effectiveIcon = Icons.mic_rounded;
            effectiveTitle = "MIC LIVE";
          }
        }
        // 3. CPU Telemetry
        else if (btnType == 'sys_cpu' || btnTitle.contains('cpu')) {
          effectiveTitle = "CPU ${_conn.cpuPercent}%";
          effectiveIcon = Icons.memory_rounded;
          effectiveColor = _conn.cpuPercent > 80
              ? const Color(0xFFFF2A6D)
              : (_conn.cpuPercent > 50 ? Colors.amberAccent : const Color(0xFF00F2FE));
        }
        // 4. RAM Telemetry
        else if (btnType == 'sys_ram' || btnTitle.contains('ram')) {
          effectiveTitle = "RAM ${_conn.ramPercent}%";
          effectiveIcon = Icons.storage_rounded;
          effectiveColor = _conn.ramPercent > 85
              ? const Color(0xFFFF2A6D)
              : (_conn.ramPercent > 65 ? Colors.amberAccent : const Color(0xFF9D4EDD));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final minDim = math.min(constraints.maxWidth, constraints.maxHeight);
            final iconSize = (minDim * 0.35).clamp(16.0, 44.0);
            final fontSize = (minDim * 0.13).clamp(8.5, 13.0);
            final cornerRadius = (minDim * 0.20).clamp(10.0, 18.0);
            final innerPad = (minDim * 0.07).clamp(4.0, 10.0);

            return GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: AnimatedScale(
                scale: _isPressed ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOutCubic,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        effectiveColor.withOpacity(_isPressed ? 0.95 : (isReactiveActive ? 0.92 : 0.82)),
                        effectiveColor.withOpacity(_isPressed ? 0.70 : (isReactiveActive ? 0.65 : 0.45)),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveColor.withOpacity(_isPressed ? 0.7 : (isReactiveActive ? 0.5 : 0.25)),
                        blurRadius: _isPressed ? 16 : (isReactiveActive ? 14 : 8),
                        spreadRadius: _isPressed ? 2 : (isReactiveActive ? 1 : 0),
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: widget.isEditMode
                          ? Colors.amberAccent
                          : (_isPressed
                              ? Colors.white.withOpacity(0.9)
                              : (isReactiveActive ? Colors.white.withOpacity(0.85) : effectiveColor.withOpacity(0.5))),
                      width: widget.isEditMode ? 2.0 : (_isPressed || isReactiveActive ? 2.0 : 1.2),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle inner gloss shine
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: math.max(14.0, minDim * 0.3),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(cornerRadius - 1)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.20),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Button Content (Responsive Icon + Title)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: innerPad, vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                effectiveIcon,
                                size: iconSize,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              SizedBox(height: (minDim * 0.05).clamp(2.0, 6.0)),
                              Text(
                                effectiveTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Edit indicator badge if in edit mode
                      if (widget.isEditMode)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.amberAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: Colors.black,
                            ),
                          ),
                        ),

                      // Offline dimmer overlay if disconnected
                      if (!isConnected && !widget.isEditMode)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(cornerRadius),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
