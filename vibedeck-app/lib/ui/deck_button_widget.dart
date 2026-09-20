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

  @override
  Widget build(BuildContext context) {
    final color = widget.button.color;
    final isConnected = ConnectionService().state == VibeConnectionState.connected;

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
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(_isPressed ? 0.95 : 0.82),
                color.withOpacity(_isPressed ? 0.70 : 0.45),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(_isPressed ? 0.6 : 0.25),
                blurRadius: _isPressed ? 16 : 8,
                spreadRadius: _isPressed ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: widget.isEditMode
                  ? Colors.amberAccent
                  : (_isPressed ? Colors.white.withOpacity(0.9) : color.withOpacity(0.5)),
              width: widget.isEditMode ? 2.0 : (_isPressed ? 2.0 : 1.2),
            ),
          ),
          child: Stack(
            children: [
              // Subtle inner shine
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Button Content (Icon + Title)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.button.iconData,
                        size: 34,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.button.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          shadows: [
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
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.amberAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 13,
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
