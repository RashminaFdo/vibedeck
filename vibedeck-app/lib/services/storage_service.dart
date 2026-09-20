import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck_action.dart';

class StorageService {
  static const String _keyProfiles = 'vibedeck_profiles';
  static const String _keyLastHost = 'vibedeck_last_host';
  static const String _keySelectedProfile = 'vibedeck_selected_profile';

  static Future<void> saveProfiles(List<DeckProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = profiles.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProfiles, jsonEncode(jsonList));
  }

  static Future<List<DeckProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfiles);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => DeckProfile.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }
    return _getDefaultProfiles();
  }

  static Future<void> saveLastHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastHost, host);
  }

  static Future<String?> getLastHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastHost);
  }

  static Future<void> saveSelectedProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedProfile, id);
  }

  static Future<String?> getSelectedProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedProfile);
  }

  static List<DeckProfile> _getDefaultProfiles() {
    return [
      DeckProfile(
        id: 'stream_deck_15',
        name: 'Stream Deck 15-Key',
        columns: 5,
        rows: 3,
        buttons: [
          DeckButton(
            id: 'btn_play_pause',
            title: 'Play/Pause',
            actionType: 'media',
            payload: {'key': 'media_play_pause'},
            colorHex: '#6C5CE7',
            iconName: 'play_arrow',
          ),
          DeckButton(
            id: 'btn_prev',
            title: 'Prev Track',
            actionType: 'media',
            payload: {'key': 'media_prev'},
            colorHex: '#0984E3',
            iconName: 'skip_previous',
          ),
          DeckButton(
            id: 'btn_next',
            title: 'Next Track',
            actionType: 'media',
            payload: {'key': 'media_next'},
            colorHex: '#00CEC9',
            iconName: 'skip_next',
          ),
          DeckButton(
            id: 'btn_mute_master',
            title: 'Mute Master',
            actionType: 'mute',
            payload: {'key': 'volume_mute'},
            colorHex: '#D63031',
            iconName: 'volume_off',
          ),
          DeckButton(
            id: 'btn_mic_mute',
            title: 'Mic Mute',
            actionType: 'mic_mute',
            payload: {},
            colorHex: '#00FF88',
            iconName: 'mic_off',
          ),
          DeckButton(
            id: 'btn_spotify',
            title: 'Spotify',
            actionType: 'app',
            payload: {'target': 'spotify'},
            colorHex: '#1DB954',
            iconName: 'music_note',
          ),
          DeckButton(
            id: 'btn_discord',
            title: 'Discord',
            actionType: 'app',
            payload: {'target': 'discord'},
            colorHex: '#5865F2',
            iconName: 'forum',
          ),
          DeckButton(
            id: 'btn_chrome',
            title: 'Chrome',
            actionType: 'app',
            payload: {'target': 'chrome'},
            colorHex: '#4285F4',
            iconName: 'language',
          ),
          DeckButton(
            id: 'btn_vscode',
            title: 'VS Code',
            actionType: 'app',
            payload: {'target': 'code'},
            colorHex: '#007ACC',
            iconName: 'code',
          ),
          DeckButton(
            id: 'btn_terminal',
            title: 'Terminal',
            actionType: 'app',
            payload: {'target': 'wt.exe'},
            colorHex: '#2D3436',
            iconName: 'terminal',
          ),
          DeckButton(
            id: 'btn_cpu',
            title: 'CPU Monitor',
            actionType: 'sys_cpu',
            payload: {},
            colorHex: '#00F2FE',
            iconName: 'analytics',
          ),
          DeckButton(
            id: 'btn_ram',
            title: 'RAM Monitor',
            actionType: 'sys_ram',
            payload: {},
            colorHex: '#9D4EDD',
            iconName: 'analytics',
          ),
          DeckButton(
            id: 'btn_screenshot',
            title: 'Snip Tool',
            actionType: 'system',
            payload: {'command': 'screenshot'},
            colorHex: '#FDCB6E',
            iconName: 'crop',
          ),
          DeckButton(
            id: 'btn_screen_off',
            title: 'Screen Off',
            actionType: 'power',
            payload: {'command': 'screen_off'},
            colorHex: '#00F2FE',
            iconName: 'lock',
          ),
          DeckButton(
            id: 'btn_sleep_pc',
            title: 'Sleep PC',
            actionType: 'power',
            payload: {'command': 'sleep'},
            colorHex: '#FF2A6D',
            iconName: 'lock',
          ),
        ],
      ),
      DeckProfile(
        id: 'media_audio',
        name: 'Media & Audio',
        columns: 3,
        rows: 3,
        buttons: [
          DeckButton(
            id: 'btn_play_pause',
            title: 'Play/Pause',
            actionType: 'media',
            payload: {'key': 'media_play_pause'},
            colorHex: '#6C5CE7',
            iconName: 'play_arrow',
          ),
          DeckButton(
            id: 'btn_prev',
            title: 'Prev Track',
            actionType: 'media',
            payload: {'key': 'media_prev'},
            colorHex: '#0984E3',
            iconName: 'skip_previous',
          ),
          DeckButton(
            id: 'btn_next',
            title: 'Next Track',
            actionType: 'media',
            payload: {'key': 'media_next'},
            colorHex: '#00CEC9',
            iconName: 'skip_next',
          ),
          DeckButton(
            id: 'btn_mute',
            title: 'Mute Master',
            actionType: 'media',
            payload: {'key': 'volume_mute'},
            colorHex: '#D63031',
            iconName: 'volume_off',
          ),
          DeckButton(
            id: 'btn_vol_down',
            title: 'Vol -5%',
            actionType: 'media',
            payload: {'key': 'volume_down'},
            colorHex: '#E17055',
            iconName: 'volume_down',
          ),
          DeckButton(
            id: 'btn_vol_up',
            title: 'Vol +5%',
            actionType: 'media',
            payload: {'key': 'volume_up'},
            colorHex: '#00B894',
            iconName: 'volume_up',
          ),
          DeckButton(
            id: 'btn_spotify',
            title: 'Spotify',
            actionType: 'app',
            payload: {'target': 'spotify'},
            colorHex: '#1DB954',
            iconName: 'music_note',
          ),
          DeckButton(
            id: 'btn_youtube',
            title: 'YouTube',
            actionType: 'url',
            payload: {'url': 'https://youtube.com'},
            colorHex: '#FF0000',
            iconName: 'smart_display',
          ),
          DeckButton(
            id: 'btn_soundcloud',
            title: 'SoundCloud',
            actionType: 'url',
            payload: {'url': 'https://soundcloud.com'},
            colorHex: '#FF5500',
            iconName: 'cloud',
          ),
        ],
      ),
      DeckProfile(
        id: 'system_tools',
        name: 'System & Tools',
        columns: 3,
        rows: 3,
        buttons: [
          DeckButton(
            id: 'btn_snip',
            title: 'Snip Tool',
            actionType: 'system',
            payload: {'command': 'screenshot'},
            colorHex: '#FD79A8',
            iconName: 'crop',
          ),
          DeckButton(
            id: 'btn_desktop',
            title: 'Desktop',
            actionType: 'system',
            payload: {'command': 'show_desktop'},
            colorHex: '#A29BFE',
            iconName: 'desktop_windows',
          ),
          DeckButton(
            id: 'btn_taskmgr',
            title: 'Task Manager',
            actionType: 'system',
            payload: {'command': 'task_manager'},
            colorHex: '#E84393',
            iconName: 'analytics',
          ),
          DeckButton(
            id: 'btn_lock',
            title: 'Lock PC',
            actionType: 'system',
            payload: {'command': 'lock'},
            colorHex: '#D63031',
            iconName: 'lock',
          ),
          DeckButton(
            id: 'btn_term',
            title: 'Terminal',
            actionType: 'app',
            payload: {'target': 'terminal'},
            colorHex: '#2D3436',
            iconName: 'terminal',
          ),
          DeckButton(
            id: 'btn_calc',
            title: 'Calculator',
            actionType: 'app',
            payload: {'target': 'calc'},
            colorHex: '#FDCB6E',
            iconName: 'calculate',
          ),
          DeckButton(
            id: 'btn_notepad',
            title: 'Notepad',
            actionType: 'app',
            payload: {'target': 'notepad'},
            colorHex: '#74B9FF',
            iconName: 'edit_note',
          ),
          DeckButton(
            id: 'btn_alttab',
            title: 'Alt + Tab',
            actionType: 'system',
            payload: {'command': 'alt_tab'},
            colorHex: '#6C5CE7',
            iconName: 'swap_horiz',
          ),
          DeckButton(
            id: 'btn_run',
            title: 'Win + R',
            actionType: 'hotkey',
            payload: {'keys': ['win', 'r']},
            colorHex: '#00B894',
            iconName: 'play_circle',
          ),
        ],
      ),
      DeckProfile(
        id: 'dev_discord',
        name: 'Dev & Discord',
        columns: 3,
        rows: 3,
        buttons: [
          DeckButton(
            id: 'btn_vscode',
            title: 'VS Code',
            actionType: 'app',
            payload: {'target': 'vscode'},
            colorHex: '#007ACC',
            iconName: 'code',
          ),
          DeckButton(
            id: 'btn_chrome',
            title: 'Chrome',
            actionType: 'app',
            payload: {'target': 'chrome'},
            colorHex: '#4285F4',
            iconName: 'language',
          ),
          DeckButton(
            id: 'btn_discord',
            title: 'Discord',
            actionType: 'app',
            payload: {'target': 'discord'},
            colorHex: '#5865F2',
            iconName: 'forum',
          ),
          DeckButton(
            id: 'btn_disc_mute',
            title: 'Mic Mute',
            actionType: 'hotkey',
            payload: {'keys': ['ctrl', 'shift', 'm']},
            colorHex: '#ED4245',
            iconName: 'mic_off',
          ),
          DeckButton(
            id: 'btn_disc_deaf',
            title: 'Deafen',
            actionType: 'hotkey',
            payload: {'keys': ['ctrl', 'shift', 'd']},
            colorHex: '#FAA61A',
            iconName: 'headset_off',
          ),
          DeckButton(
            id: 'btn_copy',
            title: 'Copy',
            actionType: 'hotkey',
            payload: {'keys': ['ctrl', 'c']},
            colorHex: '#55EFC4',
            iconName: 'content_copy',
          ),
          DeckButton(
            id: 'btn_paste',
            title: 'Paste',
            actionType: 'hotkey',
            payload: {'keys': ['ctrl', 'v']},
            colorHex: '#81ECEC',
            iconName: 'content_paste',
          ),
          DeckButton(
            id: 'btn_undo',
            title: 'Undo',
            actionType: 'hotkey',
            payload: {'keys': ['ctrl', 'z']},
            colorHex: '#FAB1A0',
            iconName: 'undo',
          ),
          DeckButton(
            id: 'btn_selectall',
            title: 'Select All',
            actionType: 'hotkey',
            payload: {'keys': ['ctrl', 'a']},
            colorHex: '#A29BFE',
            iconName: 'select_all',
          ),
        ],
      ),
    ];
  }
}
