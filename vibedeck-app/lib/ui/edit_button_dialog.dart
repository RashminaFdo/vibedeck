import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/deck_action.dart';
import '../services/connection_service.dart';
import '../theme/vibe_theme.dart';

class EditButtonDialog extends StatefulWidget {
  final DeckButton? initialButton;
  final Function(DeckButton) onSave;
  final VoidCallback? onDelete;

  const EditButtonDialog({
    super.key,
    this.initialButton,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<EditButtonDialog> createState() => _EditButtonDialogState();
}

class _EditButtonDialogState extends State<EditButtonDialog> {
  late TextEditingController _titleController;
  late String _actionType;
  late String _colorHex;
  late String _iconName;

  // Action payloads
  String _mediaKey = 'media_play_pause';
  String _powerCommand = 'screen_off';
  final List<String> _hotkeyModifiers = [];
  final TextEditingController _hotkeyCharController = TextEditingController();
  final TextEditingController _appTargetController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  String _systemCommand = 'screenshot';
  int _volumeLevel = 50;
  final TextEditingController _typeTextController = TextEditingController();

  final List<String> _presetColors = [
    '#6C5CE7', '#0984E3', '#00CEC9', '#00B894',
    '#FDCB6E', '#E17055', '#D63031', '#FD79A8',
    '#A29BFE', '#74B9FF', '#55EFC4', '#2D3436'
  ];

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'play_arrow', 'icon': Icons.play_arrow_rounded, 'label': 'Play'},
    {'name': 'skip_previous', 'icon': Icons.skip_previous_rounded, 'label': 'Prev'},
    {'name': 'skip_next', 'icon': Icons.skip_next_rounded, 'label': 'Next'},
    {'name': 'volume_up', 'icon': Icons.volume_up_rounded, 'label': 'Vol Up'},
    {'name': 'volume_down', 'icon': Icons.volume_down_rounded, 'label': 'Vol Dn'},
    {'name': 'volume_off', 'icon': Icons.volume_off_rounded, 'label': 'Mute'},
    {'name': 'music_note', 'icon': Icons.music_note_rounded, 'label': 'Music'},
    {'name': 'smart_display', 'icon': Icons.smart_display_rounded, 'label': 'Video'},
    {'name': 'crop', 'icon': Icons.crop_rounded, 'label': 'Snip'},
    {'name': 'desktop_windows', 'icon': Icons.desktop_windows_rounded, 'label': 'Desktop'},
    {'name': 'analytics', 'icon': Icons.analytics_rounded, 'label': 'Stats'},
    {'name': 'lock', 'icon': Icons.lock_rounded, 'label': 'Lock'},
    {'name': 'terminal', 'icon': Icons.terminal_rounded, 'label': 'Terminal'},
    {'name': 'code', 'icon': Icons.code_rounded, 'label': 'Code'},
    {'name': 'language', 'icon': Icons.language_rounded, 'label': 'Browser'},
    {'name': 'forum', 'icon': Icons.forum_rounded, 'label': 'Chat'},
    {'name': 'mic_off', 'icon': Icons.mic_off_rounded, 'label': 'Mic Mute'},
    {'name': 'headset_off', 'icon': Icons.headset_off_rounded, 'label': 'Deafen'},
    {'name': 'content_copy', 'icon': Icons.content_copy_rounded, 'label': 'Copy'},
    {'name': 'content_paste', 'icon': Icons.content_paste_rounded, 'label': 'Paste'},
    {'name': 'undo', 'icon': Icons.undo_rounded, 'label': 'Undo'},
    {'name': 'calculate', 'icon': Icons.calculate_rounded, 'label': 'Calc'},
    {'name': 'edit_note', 'icon': Icons.edit_note_rounded, 'label': 'Note'},
    {'name': 'swap_horiz', 'icon': Icons.swap_horiz_rounded, 'label': 'AltTab'},
    {'name': 'games', 'icon': Icons.videogame_asset_rounded, 'label': 'Game'},
    {'name': 'cloud', 'icon': Icons.cloud_rounded, 'label': 'Cloud'},
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.initialButton;
    _titleController = TextEditingController(text: b?.title ?? 'My Button');
    _actionType = b?.actionType ?? 'media';
    _colorHex = b?.colorHex ?? '#6C5CE7';
    _iconName = b?.iconName ?? 'play_arrow';

    if (b != null) {
      if (_actionType == 'media') {
        _mediaKey = b.payload['key'] ?? 'media_play_pause';
      } else if (_actionType == 'hotkey') {
        final keys = List<String>.from(b.payload['keys'] ?? []);
        for (final k in keys) {
          if (['ctrl', 'shift', 'alt', 'win'].contains(k)) {
            _hotkeyModifiers.add(k);
          } else {
            _hotkeyCharController.text = k;
          }
        }
      } else if (_actionType == 'app') {
        _appTargetController.text = b.payload['target'] ?? '';
      } else if (_actionType == 'url') {
        _urlController.text = b.payload['url'] ?? '';
      } else if (_actionType == 'system') {
        _systemCommand = b.payload['command'] ?? 'screenshot';
      } else if (_actionType == 'volume') {
        _volumeLevel = b.payload['level'] ?? 50;
      } else if (_actionType == 'power') {
        _powerCommand = b.payload['command'] ?? 'screen_off';
      } else if (_actionType == 'type') {
        _typeTextController.text = b.payload['text'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hotkeyCharController.dispose();
    _appTargetController.dispose();
    _urlController.dispose();
    _typeTextController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() {
    switch (_actionType) {
      case 'media':
        return {'key': _mediaKey};
      case 'hotkey':
        final allKeys = [..._hotkeyModifiers];
        final char = _hotkeyCharController.text.trim().toLowerCase();
        if (char.isNotEmpty) allKeys.add(char);
        return {'keys': allKeys};
      case 'app':
        return {'target': _appTargetController.text.trim()};
      case 'url':
        return {'url': _urlController.text.trim()};
      case 'system':
        return {'command': _systemCommand};
      case 'power':
        return {'command': _powerCommand};
      case 'mic_mute':
      case 'sys_cpu':
      case 'sys_ram':
        return {};
      case 'volume':
        return {'level': _volumeLevel};
      case 'type':
        return {'text': _typeTextController.text};
      default:
        return {};
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final btn = DeckButton(
      id: widget.initialButton?.id ?? 'btn_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      actionType: _actionType,
      payload: _buildPayload(),
      colorHex: _colorHex,
      iconName: _iconName,
    );

    widget.onSave(btn);
    Navigator.of(context).pop();
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll("#", "");
      return Color(int.parse("FF$h", radix: 16));
    } catch (_) {
      return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      backgroundColor: const Color(0xFF131622),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 16 : 14,
        vertical: isLandscape ? 6 : 18,
      ),
      child: Container(
        width: isLandscape ? 640 : 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * (isLandscape ? 0.90 : 0.94),
        ),
        padding: EdgeInsets.all(isLandscape ? 10 : 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialButton == null ? "Create Button" : "Edit Button",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    tooltip: "Delete Button",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      widget.onDelete!();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Scrollable Settings Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Presets Row
                    const Text("Quick Presets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetQuickChip("Mic Mute", "mic_mute", {}, "mic_off", "#00FF88"),
                    const SizedBox(width: 6),
                    _buildPresetQuickChip("Screen Off", "power", {"command": "screen_off"}, "lock", "#00F2FE"),
                    const SizedBox(width: 6),
                    _buildPresetQuickChip("Sleep PC", "power", {"command": "sleep"}, "lock", "#FF2A6D"),
                    const SizedBox(width: 6),
                    _buildPresetQuickChip("CPU Stats", "sys_cpu", {}, "analytics", "#00F2FE"),
                    const SizedBox(width: 6),
                    _buildPresetQuickChip("RAM Stats", "sys_ram", {}, "analytics", "#9D4EDD"),
                    const SizedBox(width: 6),
                    _buildPresetQuickChip("Play/Pause", "media", {"key": "media_play_pause"}, "play_arrow", "#0984E3"),
                    const SizedBox(width: 6),
                    _buildPresetQuickChip("Screenshot", "system", {"command": "screenshot"}, "crop", "#FDCB6E"),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Title input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Button Label",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Action Type Selector
              const Text("Action Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip("media", "Media Key", Icons.play_arrow_rounded),
                  _buildTypeChip("mic_mute", "Mic Mute", Icons.mic_off_rounded),
                  _buildTypeChip("power", "Power/Sleep", Icons.nightlight_round),
                  _buildTypeChip("sys_cpu", "CPU Stats", Icons.memory_rounded),
                  _buildTypeChip("sys_ram", "RAM Stats", Icons.storage_rounded),
                  _buildTypeChip("hotkey", "Hotkey", Icons.keyboard_rounded),
                  _buildTypeChip("app", "Launch App", Icons.apps_rounded),
                  _buildTypeChip("url", "Open URL", Icons.link_rounded),
                  _buildTypeChip("system", "System", Icons.computer_rounded),
                  _buildTypeChip("volume", "Volume Set", Icons.volume_up_rounded),
                  _buildTypeChip("type", "Type Text", Icons.text_fields_rounded),
                ],
              ),
              const SizedBox(height: 16),

              // Action Type Dynamic Config
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VibeTheme.surfaceHighlight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VibeTheme.border),
                ),
                child: _buildActionConfig(),
              ),
              const SizedBox(height: 16),

              // Color Preset Picker
              const Text("Button Color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._presetColors.map((hex) {
                    final isSelected = _colorHex.toUpperCase() == hex.toUpperCase();
                    final c = _parseColor(hex);
                    return GestureDetector(
                      onTap: () => setState(() => _colorHex = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                      ),
                    );
                  }),
                  // Custom Color Picker Button
                  GestureDetector(
                    onTap: _openCustomColorPicker,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const SweepGradient(
                          colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38, width: 1.5),
                      ),
                      child: const Icon(Icons.colorize, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Icon Picker
              const Text("Select Icon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const IconGridDelegate(),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, idx) {
                    final item = _availableIcons[idx];
                    final isSelected = _iconName == item['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _iconName = item['name']),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? VibeTheme.primaryNeon.withOpacity(0.35) : VibeTheme.surfaceHighlight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? VibeTheme.primaryNeon : VibeTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'] as IconData, size: 24, color: isSelected ? Colors.white : Colors.white70),
                            const SizedBox(height: 2),
                            Text(
                              item['label'],
                              style: const TextStyle(fontSize: 9.5, color: Colors.white70),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sticky Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VibeTheme.primaryNeon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _save,
                    child: const Text("Save Button", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _actionType == type;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => setState(() => _actionType = type),
      selectedColor: VibeTheme.primaryNeon,
      backgroundColor: VibeTheme.surfaceHighlight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildActionConfig() {
    switch (_actionType) {
      case 'media':
        return DropdownButtonFormField<String>(
          value: _mediaKey,
          decoration: const InputDecoration(labelText: "Media Control Action"),
          items: const [
            DropdownMenuItem(value: 'media_play_pause', child: Text("Play / Pause Toggle")),
            DropdownMenuItem(value: 'media_next', child: Text("Next Track")),
            DropdownMenuItem(value: 'media_prev', child: Text("Previous Track")),
            DropdownMenuItem(value: 'media_stop', child: Text("Stop Playback")),
            DropdownMenuItem(value: 'volume_mute', child: Text("Mute / Unmute")),
            DropdownMenuItem(value: 'volume_up', child: Text("Volume Up (+5%)")),
            DropdownMenuItem(value: 'volume_down', child: Text("Volume Down (-5%)")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _mediaKey = val);
          },
        );

      case 'hotkey':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Modifier Keys (Hold)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: ['ctrl', 'shift', 'alt', 'win'].map((mod) {
                final isChecked = _hotkeyModifiers.contains(mod);
                return FilterChip(
                  label: Text(mod.toUpperCase()),
                  selected: isChecked,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _hotkeyModifiers.add(mod);
                      } else {
                        _hotkeyModifiers.remove(mod);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _hotkeyCharController,
              decoration: const InputDecoration(
                labelText: "Target Key (e.g. m, c, v, tab, esc, f9, space)",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        );

      case 'app':
        final installed = ConnectionService().installedApps;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Button to browse installed apps
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VibeTheme.cyanNeon.withValues(alpha: 0.18),
                foregroundColor: VibeTheme.cyanNeon,
                side: const BorderSide(color: VibeTheme.cyanNeon, width: 1.2),
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.laptop_chromebook_rounded, size: 20),
              label: Text(
                installed.isNotEmpty
                    ? "Browse Laptop Apps (${installed.length} found)"
                    : "Browse Apps on Laptop",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _openInstalledAppPicker,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _appTargetController,
              decoration: const InputDecoration(
                labelText: "App Name, Shortcut, or .exe Path",
                hintText: "e.g. discord, spotify, chrome, code, calc",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Popular Laptop Apps:", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildAppPresetChip("Spotify", "spotify", "music_note", "#1DB954"),
                _buildAppPresetChip("Discord", "discord", "chat", "#5865F2"),
                _buildAppPresetChip("Chrome", "chrome", "language", "#4285F4"),
                _buildAppPresetChip("VS Code", "code", "code", "#007ACC"),
                _buildAppPresetChip("Terminal", "terminal", "terminal", "#2D3436"),
                _buildAppPresetChip("Calculator", "calc", "calculate", "#FDCB6E"),
                _buildAppPresetChip("Notepad", "notepad", "edit_note", "#74B9FF"),
                _buildAppPresetChip("Task Manager", "taskmgr", "analytics", "#E84393"),
                _buildAppPresetChip("Explorer", "explorer", "folder", "#FAB1A0"),
                _buildAppPresetChip("Settings", "settings", "settings", "#6C5CE7"),
              ],
            ),
          ],
        );

      case 'url':
        return TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: "Website URL (e.g. https://youtube.com)",
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );

      case 'system':
        return DropdownButtonFormField<String>(
          value: _systemCommand,
          decoration: const InputDecoration(labelText: "System Command"),
          items: const [
            DropdownMenuItem(value: 'screenshot', child: Text("Snip Tool / Screenshot (Win+Shift+S)")),
            DropdownMenuItem(value: 'show_desktop', child: Text("Show Desktop (Win+D)")),
            DropdownMenuItem(value: 'task_manager', child: Text("Task Manager (Ctrl+Shift+Esc)")),
            DropdownMenuItem(value: 'lock', child: Text("Lock PC (LockWorkStation)")),
            DropdownMenuItem(value: 'alt_tab', child: Text("Alt + Tab Switcher")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _systemCommand = val);
          },
        );

      case 'power':
        return DropdownButtonFormField<String>(
          value: _powerCommand,
          decoration: const InputDecoration(labelText: "Bed Remote Power Command"),
          items: const [
            DropdownMenuItem(value: 'screen_off', child: Text("Turn Off Screen (Monitors Standby)")),
            DropdownMenuItem(value: 'sleep', child: Text("Put PC to Sleep")),
            DropdownMenuItem(value: 'lock', child: Text("Lock Workstation (Win+L)")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _powerCommand = val);
          },
        );

      case 'mic_mute':
        return const Row(
          children: [
            Icon(Icons.mic_off_rounded, color: Color(0xFFFF2A6D), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Toggles microphone mute in Windows & Discord.\nButton glows RED when muted and GREEN when live.",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        );

      case 'sys_cpu':
        return const Row(
          children: [
            Icon(Icons.memory_rounded, color: VibeTheme.cyanNeon, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Displays real-time PC CPU % on the button with active load color (Cyan -> Amber -> Red).",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        );

      case 'sys_ram':
        return Row(
          children: [
            const Icon(Icons.storage_rounded, color: VibeTheme.purpleNeon, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Displays real-time PC RAM % on the button with active load color (Purple -> Amber -> Red).",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        );

      case 'volume':
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Set Volume Level:"),
                Text("$_volumeLevel%", style: const TextStyle(fontWeight: FontWeight.bold, color: VibeTheme.cyanNeon)),
              ],
            ),
            Slider(
              value: _volumeLevel.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (val) => setState(() => _volumeLevel = val.round()),
            ),
          ],
        );

      case 'type':
        return TextField(
          controller: _typeTextController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Text to type on PC automatically",
            border: OutlineInputBorder(),
            isDense: true,
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPresetQuickChip(String label, String type, Map<String, dynamic> payload, String icon, String color) {
    return ActionChip(
      avatar: Icon(
        DeckButton(id: '', title: '', actionType: '', payload: {}, colorHex: color, iconName: icon).iconData,
        size: 14,
        color: Colors.white,
      ),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: const Color(0xFF1F2335),
      onPressed: () {
        setState(() {
          _titleController.text = label;
          _actionType = type;
          _iconName = icon;
          _colorHex = color;
          if (type == 'power') {
            _powerCommand = payload['command'] ?? 'screen_off';
          } else if (type == 'media') {
            _mediaKey = payload['key'] ?? 'media_play_pause';
          } else if (type == 'system') {
            _systemCommand = payload['command'] ?? 'screenshot';
          }
        });
      },
    );
  }

  Widget _buildAppPresetChip(String label, String target, String icon, String color) {
    return ActionChip(
      avatar: Icon(
        DeckButton(id: '', title: '', actionType: '', payload: {}, colorHex: color, iconName: icon).iconData,
        size: 15,
        color: Colors.white,
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: VibeTheme.surfaceHighlight,
      onPressed: () {
        setState(() {
          _appTargetController.text = target;
          _titleController.text = label;
          _iconName = icon;
          _colorHex = color;
        });
      },
    );
  }

  void _openInstalledAppPicker() {
    final conn = ConnectionService();
    if (conn.installedApps.isEmpty) {
      conn.fetchInstalledApps();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: VibeTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        String filter = "";
        return StatefulBuilder(
          builder: (ctx, setMState) {
            final allApps = conn.installedApps;
            final filtered = filter.isEmpty
                ? allApps
                : allApps.where((a) => (a['name'] ?? '').toLowerCase().contains(filter.toLowerCase())).toList();

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.sizeOf(context).height * 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.laptop_windows_rounded, color: VibeTheme.cyanNeon),
                          SizedBox(width: 8),
                          Text("Laptop Applications", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: "Refresh App List",
                        onPressed: () {
                          conn.fetchInstalledApps();
                          setMState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Search apps...",
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => setMState(() => filter = val),
                  ),
                  const SizedBox(height: 12),
                  if (allApps.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "No apps received yet. Make sure your phone is connected to the laptop server.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: VibeTheme.border),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final name = item['name'] ?? '';
                          final target = item['target'] ?? '';
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.play_circle_outline_rounded, color: VibeTheme.cyanNeon),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(target, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            onTap: () {
                              setState(() {
                                _titleController.text = name;
                                _appTargetController.text = target;
                                final ln = name.toLowerCase();
                                if (ln.contains("code") || ln.contains("visual studio")) {
                                  _iconName = "code";
                                  _colorHex = "#007ACC";
                                } else if (ln.contains("discord")) {
                                  _iconName = "chat";
                                  _colorHex = "#5865F2";
                                } else if (ln.contains("spotify")) {
                                  _iconName = "music_note";
                                  _colorHex = "#1DB954";
                                } else if (ln.contains("chrome") || ln.contains("browser") || ln.contains("edge")) {
                                  _iconName = "language";
                                  _colorHex = "#4285F4";
                                } else if (ln.contains("terminal") || ln.contains("cmd") || ln.contains("powershell")) {
                                  _iconName = "terminal";
                                  _colorHex = "#2D3436";
                                } else {
                                  _iconName = "touch_app";
                                }
                              });
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openCustomColorPicker() {
    Color currentColor = _parseColor(_colorHex);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pick Button Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (c) {
              currentColor = c;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _colorHex = '#${currentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              });
              Navigator.of(ctx).pop();
            },
            child: const Text("Select"),
          ),
        ],
      ),
    );
  }
}

class IconGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  const IconGridDelegate()
      : super(
          crossAxisCount: 5,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.1,
        );
}
