import 'package:flutter/material.dart';

class DeckButton {
  String id;
  String title;
  String actionType; // "media", "hotkey", "app", "url", "system", "volume", "type"
  Map<String, dynamic> payload;
  String colorHex;
  String iconName;

  DeckButton({
    required this.id,
    required this.title,
    required this.actionType,
    required this.payload,
    required this.colorHex,
    required this.iconName,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll("#", "");
      if (hex.length == 6) {
        return Color(int.parse("FF$hex", radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF6C5CE7);
  }

  IconData get iconData {
    switch (iconName) {
      case 'play_arrow':
      case 'play_pause':
        return Icons.play_arrow_rounded;
      case 'skip_previous':
        return Icons.skip_previous_rounded;
      case 'skip_next':
        return Icons.skip_next_rounded;
      case 'volume_up':
        return Icons.volume_up_rounded;
      case 'volume_down':
        return Icons.volume_down_rounded;
      case 'volume_off':
      case 'volume_mute':
        return Icons.volume_off_rounded;
      case 'music_note':
        return Icons.music_note_rounded;
      case 'smart_display':
      case 'video_library':
        return Icons.smart_display_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'crop':
      case 'screenshot':
        return Icons.crop_rounded;
      case 'desktop_windows':
        return Icons.desktop_windows_rounded;
      case 'analytics':
      case 'assessment':
        return Icons.analytics_rounded;
      case 'lock':
        return Icons.lock_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'calculate':
        return Icons.calculate_rounded;
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'play_circle':
        return Icons.play_circle_fill_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'forum':
      case 'chat':
        return Icons.forum_rounded;
      case 'mic_off':
        return Icons.mic_off_rounded;
      case 'headset_off':
        return Icons.headset_off_rounded;
      case 'content_copy':
        return Icons.content_copy_rounded;
      case 'content_paste':
        return Icons.content_paste_rounded;
      case 'undo':
        return Icons.undo_rounded;
      case 'select_all':
        return Icons.select_all_rounded;
      case 'power_settings_new':
        return Icons.power_settings_new_rounded;
      case 'brightness_medium':
        return Icons.brightness_medium_rounded;
      case 'folder':
        return Icons.folder_rounded;
      case 'web':
        return Icons.web_rounded;
      case 'keyboard':
        return Icons.keyboard_rounded;
      case 'games':
        return Icons.videogame_asset_rounded;
      default:
        return Icons.touch_app_rounded;
    }
  }

  factory DeckButton.fromJson(Map<String, dynamic> json) {
    return DeckButton(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Button',
      actionType: json['action_type'] ?? 'media',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      colorHex: json['color'] ?? json['colorHex'] ?? '#6C5CE7',
      iconName: json['icon'] ?? json['iconName'] ?? 'touch_app',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'action_type': actionType,
      'payload': payload,
      'color': colorHex,
      'icon': iconName,
    };
  }

  DeckButton copyWith({
    String? id,
    String? title,
    String? actionType,
    Map<String, dynamic>? payload,
    String? colorHex,
    String? iconName,
  }) {
    return DeckButton(
      id: id ?? this.id,
      title: title ?? this.title,
      actionType: actionType ?? this.actionType,
      payload: payload ?? Map<String, dynamic>.from(this.payload),
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
    );
  }
}

class DeckProfile {
  String id;
  String name;
  int columns;
  int rows;
  List<DeckButton> buttons;

  DeckProfile({
    required this.id,
    required this.name,
    this.columns = 3,
    this.rows = 3,
    required this.buttons,
  });

  factory DeckProfile.fromJson(Map<String, dynamic> json) {
    final btnsList = (json['buttons'] as List<dynamic>?) ?? [];
    return DeckProfile(
      id: json['id'] ?? 'default_profile',
      name: json['name'] ?? 'Main Deck',
      columns: json['columns'] ?? 3,
      rows: json['rows'] ?? 3,
      buttons: btnsList.map((b) => DeckButton.fromJson(Map<String, dynamic>.from(b))).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'columns': columns,
      'rows': rows,
      'buttons': buttons.map((b) => b.toJson()).toList(),
    };
  }

  DeckProfile copyWith({
    String? id,
    String? name,
    int? columns,
    int? rows,
    List<DeckButton>? buttons,
  }) {
    return DeckProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      buttons: buttons ?? List<DeckButton>.from(this.buttons),
    );
  }
}
