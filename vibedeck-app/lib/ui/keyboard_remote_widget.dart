import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/connection_service.dart';
import '../theme/vibe_theme.dart';

class KeyboardRemoteWidget extends StatefulWidget {
  const KeyboardRemoteWidget({super.key});

  @override
  State<KeyboardRemoteWidget> createState() => _KeyboardRemoteWidgetState();
}

class _KeyboardRemoteWidgetState extends State<KeyboardRemoteWidget> {
  final ConnectionService _conn = ConnectionService();
  final TextEditingController _dictationCtrl = TextEditingController();

  bool _isShifted = false;
  bool _isCapsLock = false;
  bool _isCtrlActive = false;
  bool _isAltActive = false;
  bool _isWinActive = false;
  bool _showFnRow = true;
  bool _showTextBar = false;

  @override
  void dispose() {
    _dictationCtrl.dispose();
    super.dispose();
  }

  void _onKeyTapped(String key, {String? shiftKey, bool isLetter = false}) {
    HapticFeedback.lightImpact();

    String charToSend;
    if (_isShifted) {
      charToSend = shiftKey ?? (isLetter ? key.toUpperCase() : key);
    } else if (_isCapsLock && isLetter) {
      charToSend = key.toUpperCase();
    } else {
      charToSend = key.toLowerCase();
    }

    // Check active modifiers
    final modifiers = <String>[];
    if (_isCtrlActive) modifiers.add("ctrl");
    if (_isAltActive) modifiers.add("alt");
    if (_isWinActive) modifiers.add("win");

    if (modifiers.isNotEmpty) {
      for (final m in modifiers) {
        _conn.sendKeyDown(m);
      }
      _conn.sendKeyPress(charToSend);
      for (final m in modifiers) {
        _conn.sendKeyUp(m);
      }
      setState(() {
        _isCtrlActive = false;
        _isAltActive = false;
        _isWinActive = false;
      });
    } else {
      _conn.sendKeyPress(charToSend);
    }

    // Single-use shift reset
    if (_isShifted) {
      setState(() => _isShifted = false);
    }
  }

  void _sendDictatedText() {
    final text = _dictationCtrl.text;
    if (text.isNotEmpty) {
      _conn.sendKeyType(text);
      _dictationCtrl.clear();
      HapticFeedback.mediumImpact();
    }
  }

  Widget _buildKey({
    required String label,
    String? subLabel,
    String? keyName,
    String? shiftKey,
    bool isLetter = false,
    int flex = 10,
    Color? bgColor,
    Color? textColor,
    Color? borderColor,
    IconData? icon,
    VoidCallback? customTap,
    bool isActive = false,
  }) {
    final displayLabel = _isShifted
        ? (subLabel ?? (isLetter ? label.toUpperCase() : label))
        : (_isCapsLock && isLetter ? label.toUpperCase() : label);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              if (customTap != null) {
                customTap();
              } else {
                _onKeyTapped(
                  keyName ?? label,
                  shiftKey: shiftKey ?? subLabel,
                  isLetter: isLetter,
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isActive
                    ? VibeTheme.cyanNeon.withOpacity(0.3)
                    : (bgColor ?? const Color(0xFF161926)),
                border: Border.all(
                  color: isActive
                      ? VibeTheme.cyanNeon
                      : (borderColor ?? Colors.white.withOpacity(0.12)),
                  width: isActive ? 1.5 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: VibeTheme.cyanNeon.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 2,
                          offset: const Offset(0, 1.5),
                        )
                      ],
              ),
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        size: 16,
                        color: textColor ?? Colors.white,
                      )
                    : subLabel != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                subLabel,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  color: _isShifted
                                      ? VibeTheme.cyanNeon
                                      : Colors.grey.shade500,
                                  fontWeight: _isShifted
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: !_isShifted
                                      ? (textColor ?? Colors.white)
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            displayLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isLetter ? 13 : 11,
                              fontWeight: FontWeight.bold,
                              color: textColor ?? Colors.white,
                            ),
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final rowHeight = isLandscape ? 38.0 : 42.0;

    return Column(
      children: [
        // Top Toolbar Ribbon: Quick Actions + Dictation Toggle + Status
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: const Color(0xFF0F111A),
          child: Row(
            children: [
              // F-Keys Strip Toggle
              InkWell(
                onTap: () => setState(() => _showFnRow = !_showFnRow),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _showFnRow ? VibeTheme.purpleNeon.withOpacity(0.25) : Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _showFnRow ? VibeTheme.purpleNeon : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showFnRow ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: _showFnRow ? VibeTheme.purpleNeon : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "F1-F12",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _showFnRow ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Dictation / Fast Paste Toggle
              InkWell(
                onTap: () => setState(() => _showTextBar = !_showTextBar),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _showTextBar ? VibeTheme.cyanNeon.withOpacity(0.25) : Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _showTextBar ? VibeTheme.cyanNeon : Colors.white24,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.text_fields_rounded, size: 13, color: VibeTheme.cyanNeon),
                      SizedBox(width: 4),
                      Text("Paste / Dictate", style: TextStyle(fontSize: 10.5, color: Colors.white)),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Quick Hotkey Shortcuts: Copy, Paste, Undo
              _buildTopQuickAction("COPY", () {
                _conn.sendKeyPress("c"); // or combo
                _conn.sendKeyDown("ctrl");
                _conn.sendKeyPress("c");
                _conn.sendKeyUp("ctrl");
              }),
              const SizedBox(width: 4),
              _buildTopQuickAction("PASTE", () {
                _conn.sendKeyDown("ctrl");
                _conn.sendKeyPress("v");
                _conn.sendKeyUp("ctrl");
              }),
              const SizedBox(width: 4),
              _buildTopQuickAction("UNDO", () {
                _conn.sendKeyDown("ctrl");
                _conn.sendKeyPress("z");
                _conn.sendKeyUp("ctrl");
              }),
            ],
          ),
        ),

        // Optional Collapsible Dictation / Long Text Input Bar
        if (_showTextBar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF131622),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dictationCtrl,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Dictate or paste text here to send all at once...",
                      hintStyle: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.35)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      filled: true,
                      fillColor: const Color(0xFF1C2030),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: VibeTheme.cyanNeon.withOpacity(0.4)),
                      ),
                    ),
                    onSubmitted: (_) => _sendDictatedText(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.send_rounded, color: VibeTheme.cyanNeon, size: 18),
                  tooltip: "Send Text to PC",
                  onPressed: _sendDictatedText,
                ),
              ],
            ),
          ),

        // Keyboard Surface
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            color: const Color(0xFF0C0E14),
            child: Column(
              children: [
                // Optional Function Row: ESC, F1-F12, PRTSC, DEL
                if (_showFnRow)
                  SizedBox(
                    height: rowHeight * 0.85,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFnKey("ESC", "esc", color: Colors.redAccent.shade200),
                          const SizedBox(width: 4),
                          ...List.generate(12, (idx) {
                            final fn = "F${idx + 1}";
                            return Padding(
                              padding: const EdgeInsets.only(right: 2.5),
                              child: _buildFnKey(fn, fn.toLowerCase()),
                            );
                          }),
                          const SizedBox(width: 4),
                          _buildFnKey("PRTSC", "prtsc", color: Colors.amberAccent),
                          const SizedBox(width: 2.5),
                          _buildFnKey("DEL", "del", color: Colors.redAccent.shade100),
                        ],
                      ),
                    ),
                  ),

                // Row 1: ` 1 2 3 4 5 6 7 8 9 0 - = Backspace
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      _buildKey(label: "`", subLabel: "~", shiftKey: "~", flex: 9),
                      _buildKey(label: "1", subLabel: "!", shiftKey: "!", flex: 10),
                      _buildKey(label: "2", subLabel: "@", shiftKey: "@", flex: 10),
                      _buildKey(label: "3", subLabel: "#", shiftKey: "#", flex: 10),
                      _buildKey(label: "4", subLabel: "\$", shiftKey: "\$", flex: 10),
                      _buildKey(label: "5", subLabel: "%", shiftKey: "%", flex: 10),
                      _buildKey(label: "6", subLabel: "^", shiftKey: "^", flex: 10),
                      _buildKey(label: "7", subLabel: "&", shiftKey: "&", flex: 10),
                      _buildKey(label: "8", subLabel: "*", shiftKey: "*", flex: 10),
                      _buildKey(label: "9", subLabel: "(", shiftKey: "(", flex: 10),
                      _buildKey(label: "0", subLabel: ")", shiftKey: ")", flex: 10),
                      _buildKey(label: "-", subLabel: "_", shiftKey: "_", flex: 10),
                      _buildKey(label: "=", subLabel: "+", shiftKey: "+", flex: 10),
                      _buildKey(
                        label: "⌫",
                        keyName: "backspace",
                        flex: 15,
                        bgColor: const Color(0xFF222638),
                        icon: Icons.backspace_outlined,
                      ),
                    ],
                  ),
                ),

                // Row 2: Tab, Q W E R T Y U I O P [ ] \
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      _buildKey(label: "Tab", keyName: "tab", flex: 13, bgColor: const Color(0xFF1D2132)),
                      _buildKey(label: "q", isLetter: true, flex: 10),
                      _buildKey(label: "w", isLetter: true, flex: 10),
                      _buildKey(label: "e", isLetter: true, flex: 10),
                      _buildKey(label: "r", isLetter: true, flex: 10),
                      _buildKey(label: "t", isLetter: true, flex: 10),
                      _buildKey(label: "y", isLetter: true, flex: 10),
                      _buildKey(label: "u", isLetter: true, flex: 10),
                      _buildKey(label: "i", isLetter: true, flex: 10),
                      _buildKey(label: "o", isLetter: true, flex: 10),
                      _buildKey(label: "p", isLetter: true, flex: 10),
                      _buildKey(label: "[", subLabel: "{", shiftKey: "{", flex: 9),
                      _buildKey(label: "]", subLabel: "}", shiftKey: "}", flex: 9),
                      _buildKey(label: "\\", subLabel: "|", shiftKey: "|", flex: 11),
                    ],
                  ),
                ),

                // Row 3: Caps, A S D F G H J K L ; ' Enter
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      _buildKey(
                        label: "Caps",
                        flex: 15,
                        bgColor: _isCapsLock ? VibeTheme.cyanNeon.withOpacity(0.3) : const Color(0xFF1D2132),
                        isActive: _isCapsLock,
                        customTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isCapsLock = !_isCapsLock);
                        },
                      ),
                      _buildKey(label: "a", isLetter: true, flex: 10),
                      _buildKey(label: "s", isLetter: true, flex: 10),
                      _buildKey(label: "d", isLetter: true, flex: 10),
                      _buildKey(label: "f", isLetter: true, flex: 10),
                      _buildKey(label: "g", isLetter: true, flex: 10),
                      _buildKey(label: "h", isLetter: true, flex: 10),
                      _buildKey(label: "j", isLetter: true, flex: 10),
                      _buildKey(label: "k", isLetter: true, flex: 10),
                      _buildKey(label: "l", isLetter: true, flex: 10),
                      _buildKey(label: ";", subLabel: ":", shiftKey: ":", flex: 9),
                      _buildKey(label: "'", subLabel: "\"", shiftKey: "\"", flex: 9),
                      _buildKey(
                        label: "Enter ↵",
                        keyName: "enter",
                        flex: 18,
                        bgColor: VibeTheme.cyanNeon.withOpacity(0.22),
                        borderColor: VibeTheme.cyanNeon.withOpacity(0.6),
                        textColor: VibeTheme.cyanNeon,
                      ),
                    ],
                  ),
                ),

                // Row 4: Shift, Z X C V B N M , . / Shift
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      _buildKey(
                        label: "⇧ Shift",
                        flex: 17,
                        bgColor: _isShifted ? VibeTheme.purpleNeon.withOpacity(0.35) : const Color(0xFF1D2132),
                        isActive: _isShifted,
                        customTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isShifted = !_isShifted);
                        },
                      ),
                      _buildKey(label: "z", isLetter: true, flex: 10),
                      _buildKey(label: "x", isLetter: true, flex: 10),
                      _buildKey(label: "c", isLetter: true, flex: 10),
                      _buildKey(label: "v", isLetter: true, flex: 10),
                      _buildKey(label: "b", isLetter: true, flex: 10),
                      _buildKey(label: "n", isLetter: true, flex: 10),
                      _buildKey(label: "m", isLetter: true, flex: 10),
                      _buildKey(label: ",", subLabel: "<", shiftKey: "<", flex: 10),
                      _buildKey(label: ".", subLabel: ">", shiftKey: ">", flex: 10),
                      _buildKey(label: "/", subLabel: "?", shiftKey: "?", flex: 10),
                      _buildKey(
                        label: "⇧",
                        flex: 15,
                        bgColor: _isShifted ? VibeTheme.purpleNeon.withOpacity(0.35) : const Color(0xFF1D2132),
                        isActive: _isShifted,
                        customTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isShifted = !_isShifted);
                        },
                      ),
                    ],
                  ),
                ),

                // Row 5: Ctrl, Win, Alt, Space, Alt, Nav Arrows (◀ ▲ ▼ ▶)
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      _buildKey(
                        label: "Ctrl",
                        flex: 12,
                        isActive: _isCtrlActive,
                        customTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isCtrlActive = !_isCtrlActive);
                        },
                      ),
                      _buildKey(
                        label: "Win ⊞",
                        flex: 10,
                        isActive: _isWinActive,
                        customTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isWinActive = !_isWinActive);
                        },
                      ),
                      _buildKey(
                        label: "Alt",
                        flex: 10,
                        isActive: _isAltActive,
                        customTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isAltActive = !_isAltActive);
                        },
                      ),
                      // Spacebar
                      _buildKey(
                        label: "— Space —",
                        keyName: "space",
                        flex: 40,
                        bgColor: const Color(0xFF141724),
                      ),
                      _buildKey(
                        label: "Alt",
                        flex: 10,
                        isActive: _isAltActive,
                        customTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isAltActive = !_isAltActive);
                        },
                      ),
                      // Directional arrows
                      _buildKey(
                        label: "◀",
                        keyName: "left",
                        icon: Icons.arrow_left_rounded,
                        flex: 10,
                        bgColor: const Color(0xFF1A1E2E),
                      ),
                      Expanded(
                        flex: 10,
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildMiniArrow("up", Icons.arrow_drop_up_rounded),
                            ),
                            Expanded(
                              child: _buildMiniArrow("down", Icons.arrow_drop_down_rounded),
                            ),
                          ],
                        ),
                      ),
                      _buildKey(
                        label: "▶",
                        keyName: "right",
                        icon: Icons.arrow_right_rounded,
                        flex: 10,
                        bgColor: const Color(0xFF1A1E2E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFnKey(String label, String keyName, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          _conn.sendKeyPress(keyName);
          HapticFeedback.lightImpact();
        },
        child: Container(
          width: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF191C28),
            border: Border.all(color: (color ?? Colors.white).withOpacity(0.18)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniArrow(String keyName, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 0.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            _conn.sendKeyPress(keyName);
            HapticFeedback.lightImpact();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF1A1E2E),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
              child: Icon(icon, size: 14, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopQuickAction(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
