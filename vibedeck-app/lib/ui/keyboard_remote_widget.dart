import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/connection_service.dart';
import '../theme/vibe_theme.dart';

enum KeyboardViewMode {
  pcKeys,
  dictate,
}

class KeyboardRemoteWidget extends StatefulWidget {
  const KeyboardRemoteWidget({super.key});

  @override
  State<KeyboardRemoteWidget> createState() => _KeyboardRemoteWidgetState();
}

class _KeyboardRemoteWidgetState extends State<KeyboardRemoteWidget> {
  final ConnectionService _conn = ConnectionService();
  final TextEditingController _dictationCtrl = TextEditingController();

  KeyboardViewMode _viewMode = KeyboardViewMode.pcKeys;
  bool _isShifted = false;
  bool _isCapsLock = false;
  bool _isCtrlActive = false;
  bool _isAltActive = false;
  bool _isWinActive = false;
  bool _showFnRow = true;
  bool _sendOnSubmit = false;

  // Mini trackpad state for portrait top console
  Offset? _lastPanPos;

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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final displayLabel = _isShifted
        ? (subLabel ?? (isLetter ? label.toUpperCase() : label))
        : (_isCapsLock && isLetter ? label.toUpperCase() : label);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 1.0 : 1.5,
          vertical: isLandscape ? 1.0 : 2.0,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isLandscape ? 4 : 6),
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
                borderRadius: BorderRadius.circular(isLandscape ? 4 : 6),
                color: isActive
                    ? VibeTheme.cyanNeon.withValues(alpha: 0.3)
                    : (bgColor ?? const Color(0xFF161926)),
                border: Border.all(
                  color: isActive
                      ? VibeTheme.cyanNeon
                      : (borderColor ?? Colors.white.withValues(alpha: 0.12)),
                  width: isActive ? 1.5 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: VibeTheme.cyanNeon.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: icon != null
                        ? Icon(
                            icon,
                            size: isLandscape ? 14 : 16,
                            color: textColor ?? Colors.white,
                          )
                        : (subLabel != null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    subLabel,
                                    style: TextStyle(
                                      fontSize: isLandscape ? 8.0 : 9.0,
                                      fontWeight: FontWeight.bold,
                                      color: _isShifted ? VibeTheme.cyanNeon : Colors.white38,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: isLandscape ? 11.0 : 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: textColor ?? Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                displayLabel,
                                style: TextStyle(
                                  fontSize: isLetter
                                      ? (isLandscape ? 12.0 : 13.0)
                                      : (isLandscape ? 10.0 : 11.0),
                                  fontWeight: FontWeight.bold,
                                  color: textColor ?? Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              )),
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

    return Column(
      children: [
        // Top Toolbar Ribbon: Mode Switcher + Hotkeys + Fn Toggle
        _buildTopToolbar(isLandscape),

        // Body: either Dictate Mode or Full PC Keyboard
        Expanded(
          child: _viewMode == KeyboardViewMode.dictate
              ? _buildDictateModeView(isLandscape)
              : _buildPcKeyboardModeView(isLandscape),
        ),
      ],
    );
  }

  Widget _buildTopToolbar(bool isLandscape) {
    return Container(
      height: isLandscape ? 30 : 38,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: isLandscape ? 2 : 4),
      color: const Color(0xFF0F111A),
      child: Row(
        children: [
          // Segmented Mode Switcher: [ ⌨️ Keys ] [ 🎙️ Dictate ]
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF161926),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModePill(
                  label: "Keyboard",
                  icon: Icons.keyboard_rounded,
                  isSelected: _viewMode == KeyboardViewMode.pcKeys,
                  activeColor: VibeTheme.cyanNeon,
                  onTap: () => setState(() => _viewMode = KeyboardViewMode.pcKeys),
                  isLandscape: isLandscape,
                ),
                _buildModePill(
                  label: "Dictate",
                  icon: Icons.mic_rounded,
                  isSelected: _viewMode == KeyboardViewMode.dictate,
                  activeColor: VibeTheme.purpleNeon,
                  onTap: () => setState(() => _viewMode = KeyboardViewMode.dictate),
                  isLandscape: isLandscape,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // F-Keys Toggle (in PC Keys mode)
          if (_viewMode == KeyboardViewMode.pcKeys)
            InkWell(
              onTap: () => setState(() => _showFnRow = !_showFnRow),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isLandscape ? 6 : 8, vertical: isLandscape ? 2 : 4),
                decoration: BoxDecoration(
                  color: _showFnRow ? VibeTheme.purpleNeon.withValues(alpha: 0.25) : Colors.white10,
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
                      size: isLandscape ? 12 : 14,
                      color: _showFnRow ? VibeTheme.purpleNeon : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "F1-F12",
                      style: TextStyle(
                        fontSize: isLandscape ? 9.5 : 10.5,
                        fontWeight: FontWeight.bold,
                        color: _showFnRow ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Quick Hotkey Shortcuts: Copy, Paste, Undo
          _buildTopQuickAction("COPY", () {
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
    );
  }

  Widget _buildModePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isLandscape,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isLandscape ? 8 : 10, vertical: isLandscape ? 2 : 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isLandscape ? 12 : 14, color: isSelected ? activeColor : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isLandscape ? 10.0 : 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DICTATE MODE (Phone Native Keyboard + PC Keys)
  // ==========================================
  Widget _buildDictateModeView(bool isLandscape) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isLandscape ? 12 : 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text Input Box (Uses Phone Keyboard with Dictation Mic)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131622),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VibeTheme.purpleNeon.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: VibeTheme.purpleNeon.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.keyboard_voice_rounded, color: VibeTheme.purpleNeon, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      "Native Phone Typing & Voice Dictation",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const Spacer(),
                    if (_dictationCtrl.text.isNotEmpty)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.grey),
                        tooltip: "Clear Text",
                        onPressed: () => setState(() => _dictationCtrl.clear()),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dictationCtrl,
                  maxLines: isLandscape ? 2 : 4,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Tap here to use phone keyboard & speech-to-text mic...",
                    hintStyle: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: const Color(0xFF1C2030),
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_sendOnSubmit) _sendDictatedText();
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _sendOnSubmit,
                      activeColor: VibeTheme.purpleNeon,
                      onChanged: (val) => setState(() => _sendOnSubmit = val ?? false),
                    ),
                    const Text("Send on Enter", style: TextStyle(fontSize: 11, color: Colors.white70)),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VibeTheme.cyanNeon,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text("SEND TO PC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _sendDictatedText,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Companion PC Keys (Keys missing on phone keyboard)
          const Text(
            "PC Companion Keys (Not on Phone Keyboard)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          // Primary PC navigation row
          Row(
            children: [
              _buildCompanionKey("ESC", () => _conn.sendKeyPress("esc"), color: Colors.redAccent.shade100),
              const SizedBox(width: 6),
              _buildCompanionKey("TAB", () => _conn.sendKeyPress("tab")),
              const SizedBox(width: 6),
              _buildCompanionKey("CTRL", () => _conn.sendKeyPress("ctrl")),
              const SizedBox(width: 6),
              _buildCompanionKey("ALT", () => _conn.sendKeyPress("alt")),
              const SizedBox(width: 6),
              _buildCompanionKey("WIN ⊞", () => _conn.sendKeyPress("win")),
              const SizedBox(width: 6),
              _buildCompanionKey("DEL", () => _conn.sendKeyPress("del"), color: Colors.redAccent.shade100),
            ],
          ),

          const SizedBox(height: 8),

          // Arrows & Navigation row
          Row(
            children: [
              _buildCompanionKey("HOME", () => _conn.sendKeyPress("home")),
              const SizedBox(width: 6),
              _buildCompanionKey("END", () => _conn.sendKeyPress("end")),
              const SizedBox(width: 6),
              _buildCompanionKey("◀", () => _conn.sendKeyPress("left"), flex: 2),
              const SizedBox(width: 6),
              _buildCompanionKey("▲", () => _conn.sendKeyPress("up"), flex: 2),
              const SizedBox(width: 6),
              _buildCompanionKey("▼", () => _conn.sendKeyPress("down"), flex: 2),
              const SizedBox(width: 6),
              _buildCompanionKey("▶", () => _conn.sendKeyPress("right"), flex: 2),
              const SizedBox(width: 6),
              _buildCompanionKey("ENTER ↵", () => _conn.sendKeyPress("enter"), color: VibeTheme.cyanNeon, flex: 3),
            ],
          ),

          const SizedBox(height: 10),

          // Function Keys Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF131622),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...List.generate(12, (i) {
                    final fn = "F${i + 1}";
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(fn, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFF222638),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _conn.sendKeyPress(fn.toLowerCase());
                        },
                      ),
                    );
                  }),
                  ActionChip(
                    label: const Text("PRTSC", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                    backgroundColor: const Color(0xFF222638),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _conn.sendKeyPress("prtsc");
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionKey(String label, VoidCallback onTap, {Color? color, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E2E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: (color ?? Colors.white).withValues(alpha: 0.18)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FULL PC KEYBOARD MODE
  // ==========================================
  Widget _buildPcKeyboardModeView(bool isLandscape) {
    if (isLandscape) {
      // Landscape: Full screen height responsive flexible rows
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        color: const Color(0xFF0C0E14),
        child: Column(
          children: _buildKeyboardRows(isExpanded: true),
        ),
      );
    } else {
      // Portrait: Keyboard placed at the bottom with natural fixed row heights!
      // Top area features mini trackpad, active modifiers, and macro shortcuts!
      return Column(
        children: [
          // Top Console Area (Utilizes vertical space productively)
          Expanded(
            child: _buildPortraitTopConsole(),
          ),

          // Proportional Bottom Keyboard (Natural height, NOT stretched!)
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            color: const Color(0xFF0C0E14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildKeyboardRows(isExpanded: false, rowHeight: 38.0),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPortraitTopConsole() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF131622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // Quick Status & Modifiers Row
          Row(
            children: [
              _buildModifierIndicator("CTRL", _isCtrlActive),
              const SizedBox(width: 6),
              _buildModifierIndicator("ALT", _isAltActive),
              const SizedBox(width: 6),
              _buildModifierIndicator("WIN", _isWinActive),
              const SizedBox(width: 6),
              _buildModifierIndicator("CAPS", _isCapsLock),
              const Spacer(),
              _buildTopQuickAction("ALT+TAB", () {
                _conn.sendKeyDown("alt");
                _conn.sendKeyPress("tab");
                _conn.sendKeyUp("alt");
              }),
              const SizedBox(width: 4),
              _buildTopQuickAction("WIN+D", () {
                _conn.sendKeyDown("win");
                _conn.sendKeyPress("d");
                _conn.sendKeyUp("win");
              }),
            ],
          ),

          const SizedBox(height: 6),

          // Mini Trackpad Touch Area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => _lastPanPos = details.localPosition,
              onPanUpdate: (details) {
                if (_lastPanPos != null) {
                  final dx = (details.localPosition.dx - _lastPanPos!.dx) * 1.5;
                  final dy = (details.localPosition.dy - _lastPanPos!.dy) * 1.5;
                  _conn.sendTrackpadMove(dx, dy);
                }
                _lastPanPos = details.localPosition;
              },
              onPanEnd: (_) => _lastPanPos = null,
              onTap: () {
                HapticFeedback.lightImpact();
                _conn.sendMouseClick("left");
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 18, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(width: 8),
                      Text(
                        "Touch to Move Mouse Cursor",
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Mini Left / Right Click Buttons
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _conn.sendMouseClick("left");
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2235),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Center(
                        child: Text("LEFT CLICK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _conn.sendMouseClick("right");
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2235),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Center(
                        child: Text("RIGHT CLICK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierIndicator(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? VibeTheme.cyanNeon.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? VibeTheme.cyanNeon : Colors.white12,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: isActive ? VibeTheme.cyanNeon : Colors.white38,
        ),
      ),
    );
  }

  List<Widget> _buildKeyboardRows({required bool isExpanded, double rowHeight = 38.0}) {
    Widget wrapRow(Widget row, int flex) {
      if (isExpanded) {
        return Expanded(flex: flex, child: row);
      } else {
        return SizedBox(height: rowHeight, child: row);
      }
    }

    return [
      // Optional Function Row: ESC, F1-F12, PRTSC, DEL
      if (_showFnRow)
        wrapRow(
          SingleChildScrollView(
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
          8,
        ),

      // Row 1: ` 1 2 3 4 5 6 7 8 9 0 - = Backspace
      wrapRow(
        Row(
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
        10,
      ),

      // Row 2: Tab, Q W E R T Y U I O P [ ] \
      wrapRow(
        Row(
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
        10,
      ),

      // Row 3: Caps, A S D F G H J K L ; ' Enter
      wrapRow(
        Row(
          children: [
            _buildKey(
              label: "Caps",
              flex: 15,
              bgColor: _isCapsLock ? VibeTheme.cyanNeon.withValues(alpha: 0.3) : const Color(0xFF1D2132),
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
              bgColor: VibeTheme.cyanNeon.withValues(alpha: 0.22),
              borderColor: VibeTheme.cyanNeon.withValues(alpha: 0.6),
              textColor: VibeTheme.cyanNeon,
            ),
          ],
        ),
        10,
      ),

      // Row 4: Shift, Z X C V B N M , . / Shift
      wrapRow(
        Row(
          children: [
            _buildKey(
              label: "⇧ Shift",
              flex: 17,
              bgColor: _isShifted ? VibeTheme.purpleNeon.withValues(alpha: 0.35) : const Color(0xFF1D2132),
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
              bgColor: _isShifted ? VibeTheme.purpleNeon.withValues(alpha: 0.35) : const Color(0xFF1D2132),
              isActive: _isShifted,
              customTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isShifted = !_isShifted);
              },
            ),
          ],
        ),
        10,
      ),

      // Row 5: Ctrl, Win, Alt, Space, Alt, Nav Arrows (◀ ▲ ▼ ▶)
      wrapRow(
        Row(
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
        10,
      ),
    ];
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
            border: Border.all(color: (color ?? Colors.white).withValues(alpha: 0.18)),
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
          color: Colors.white.withValues(alpha: 0.08),
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
