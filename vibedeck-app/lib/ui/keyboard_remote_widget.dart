import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/deck_action.dart';
import '../services/connection_service.dart';
import '../theme/vibe_theme.dart';

class KeyboardRemoteWidget extends StatefulWidget {
  const KeyboardRemoteWidget({super.key});

  @override
  State<KeyboardRemoteWidget> createState() => _KeyboardRemoteWidgetState();
}

class _KeyboardRemoteWidgetState extends State<KeyboardRemoteWidget> {
  final ConnectionService _conn = ConnectionService();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendCurrentText() {
    final text = _textCtrl.text;
    if (text.isNotEmpty) {
      _conn.sendKeyType(text);
      _textCtrl.clear();
      HapticFeedback.lightImpact();
    }
  }

  Widget _buildKey(String label, String keyName, {IconData? icon, Color? color, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            _conn.sendKeyPress(keyName);
            HapticFeedback.selectionClick();
          },
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color ?? const Color(0xFF191C28),
              border: Border.all(color: (color ?? Colors.white).withOpacity(0.2), width: 1),
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 18, color: Colors.white)
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHotkey(String label, List<String> keys, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            _conn.sendAction(
              // Dummy DeckButton for sending hotkey
              DeckButton(
                id: 'hk_${label.toLowerCase()}',
                title: label,
                iconName: 'code',
                colorHex: '#6C5CE7',
                actionType: 'hotkey',
                payload: {'keys': keys},
              ),
            );
            HapticFeedback.lightImpact();
          },
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color ?? const Color(0xFF161A29),
              border: Border.all(color: (color ?? VibeTheme.cyanNeon).withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: color ?? VibeTheme.cyanNeon,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Typing Input Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10121B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VibeTheme.cyanNeon.withOpacity(0.3), width: 1.2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Type text or dictate here...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onSubmitted: (_) {
                      _sendCurrentText();
                      _conn.sendKeyPress("enter");
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: VibeTheme.cyanNeon, size: 20),
                  onPressed: _sendCurrentText,
                  tooltip: "Send to PC",
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_return_rounded, color: Colors.amberAccent, size: 20),
                  onPressed: () {
                    _sendCurrentText();
                    _conn.sendKeyPress("enter");
                  },
                  tooltip: "Send & Enter",
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Row 1: Modifiers & Esc
          Row(
            children: [
              _buildKey("ESC", "esc", color: const Color(0xFF2C1E26)),
              _buildKey("TAB", "tab"),
              _buildKey("WIN", "win", icon: Icons.window_rounded, color: const Color(0xFF1E283D)),
              _buildKey("CTRL", "ctrl"),
              _buildKey("ALT", "alt"),
              _buildKey("SHIFT", "shift"),
            ],
          ),

          // Row 2: Standard Actions
          Row(
            children: [
              _buildKey("BACKSPACE", "backspace", icon: Icons.backspace_rounded, flex: 2, color: const Color(0xFF2C1E22)),
              _buildKey("SPACE", "space", icon: Icons.space_bar_rounded, flex: 2),
              _buildKey("ENTER", "enter", icon: Icons.keyboard_return_rounded, flex: 2, color: const Color(0xFF153326)),
            ],
          ),

          // Row 3: Arrows & Navigation
          Row(
            children: [
              _buildKey("DEL", "delete"),
              _buildKey("LEFT", "left", icon: Icons.arrow_left_rounded),
              _buildKey("UP", "up", icon: Icons.arrow_drop_up_rounded),
              _buildKey("DOWN", "down", icon: Icons.arrow_drop_down_rounded),
              _buildKey("RIGHT", "right", icon: Icons.arrow_right_rounded),
              _buildKey("PRTSC", "printscreen"),
            ],
          ),

          const SizedBox(height: 6),

          // Quick PC Hotkeys row
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text("QUICK SHORTCUTS", style: TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Row(
            children: [
              _buildHotkey("Ctrl+C", ["ctrl", "c"]),
              _buildHotkey("Ctrl+V", ["ctrl", "v"]),
              _buildHotkey("Ctrl+Z", ["ctrl", "z"]),
              _buildHotkey("Alt+Tab", ["alt", "tab"], color: Colors.amberAccent),
              _buildHotkey("Win+D", ["win", "d"], color: VibeTheme.purpleNeon),
            ],
          ),

          const SizedBox(height: 10),

          // Bed Power Remote Actions
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 4),
            child: Text("BED REMOTE POWER CONTROLS", style: TextStyle(color: Colors.grey, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.screen_lock_portrait_rounded, size: 16),
                  label: const Text("Screen Off", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1D2B),
                    foregroundColor: VibeTheme.cyanNeon,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _conn.sendPowerAction("screen_off");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Monitors powered off (wake with mouse touch)"), duration: Duration(seconds: 2)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_rounded, size: 16),
                  label: const Text("Lock PC", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1D2B),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _conn.sendPowerAction("lock"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.nightlight_round, size: 16),
                  label: const Text("Sleep PC", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C1925),
                    foregroundColor: const Color(0xFFFF2A6D),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _conn.sendPowerAction("sleep"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
