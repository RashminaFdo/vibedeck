import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/deck_action.dart';

enum VibeConnectionState { disconnected, discovering, connecting, connected }

class ConnectionService extends ChangeNotifier {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  VibeConnectionState state = VibeConnectionState.disconnected;
  String currentHost = "";
  String currentServerName = "";
  int latencyMs = 0;
  int masterVolume = 50;
  bool isMuted = false;
  bool isMicMuted = false;
  int cpuPercent = 0;
  int ramPercent = 0;
  String? lastError;
  List<Map<String, String>> installedApps = [];

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  RawDatagramSocket? _udpSocket;
  Function(List<DeckProfile>)? onProfilesReceived;

  String? _lastConnectedUrl;
  bool _shouldAutoReconnect = true;

  Future<void> connect(String url) async {
    _shouldAutoReconnect = true;
    _lastConnectedUrl = url;
    
    _disconnectInternal(silent: true);

    state = VibeConnectionState.connecting;
    lastError = null;
    notifyListeners();

    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith("ws://") && !formattedUrl.startsWith("wss://")) {
      formattedUrl = "ws://$formattedUrl";
    }

    try {
      final uri = Uri.parse(formattedUrl);
      currentHost = uri.host;
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          _handleMessage(data.toString());
        },
        onError: (error) {
          _onConnectionLost("Connection error: $error");
        },
        onDone: () {
          _onConnectionLost("Connection closed by host");
        },
        cancelOnError: true,
      );

      // Send initial handshake
      _sendJson({
        "type": "HELLO",
        "client_name": "VibeDeck Android Mobile"
      });

      state = VibeConnectionState.connected;
      _startPingLoop();
      notifyListeners();
    } catch (e) {
      _onConnectionLost("Failed to connect: $e");
    }
  }

  void connectUsb() {
    connect("ws://127.0.0.1:8765");
  }

  Future<void> startAutoDiscovery({Duration timeout = const Duration(seconds: 10)}) async {
    state = VibeConnectionState.discovering;
    lastError = null;
    notifyListeners();

    try {
      _udpSocket?.close();
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8766);
      _udpSocket!.broadcastEnabled = true;

      Timer(timeout, () {
        if (state == VibeConnectionState.discovering) {
          _udpSocket?.close();
          state = VibeConnectionState.disconnected;
          lastError = "Host laptop not found. Ensure both are on the same Wi-Fi.";
          notifyListeners();
        }
      });

      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket?.receive();
          if (datagram != null) {
            final text = utf8.decode(datagram.data);
            try {
              final json = jsonDecode(text) as Map<String, dynamic>;
              if (json['type'] == 'VIBEDECK_DISCOVERY') {
                final host = datagram.address.address;
                final port = json['port'] ?? 8765;
                _udpSocket?.close();
                connect("ws://$host:$port");
              }
            } catch (_) {}
          }
        }
      });
    } catch (e) {
      state = VibeConnectionState.disconnected;
      lastError = "UDP discovery failed: $e";
      notifyListeners();
    }
  }

  void disconnect() {
    _shouldAutoReconnect = false;
    _disconnectInternal(silent: false);
  }

  void _disconnectInternal({bool silent = false}) {
    _pingTimer?.cancel();
    _pingTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    if (!silent) {
      state = VibeConnectionState.disconnected;
      notifyListeners();
    }
  }

  void _onConnectionLost(String reason) {
    _pingTimer?.cancel();
    _channel = null;
    state = VibeConnectionState.disconnected;
    lastError = reason;
    notifyListeners();

    if (_shouldAutoReconnect && _lastConnectedUrl != null) {
      Timer(const Duration(seconds: 3), () {
        if (state == VibeConnectionState.disconnected && _shouldAutoReconnect) {
          debugPrint("Attempting auto-reconnect to $_lastConnectedUrl...");
          connect(_lastConnectedUrl!);
        }
      });
    }
  }

  void _startPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state == VibeConnectionState.connected) {
        _sendJson({
          "type": "PING",
          "time": DateTime.now().millisecondsSinceEpoch
        });
      }
    });
  }

  void sendAction(DeckButton button) {
    if (state != VibeConnectionState.connected) return;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    _sendJson({
      "type": "ACTION",
      "action_id": DateTime.now().millisecondsSinceEpoch.toString(),
      "action_kind": button.actionType,
      "payload": button.payload,
    });
  }

  void setVolume(int level) {
    masterVolume = level.clamp(0, 100);
    notifyListeners();
    _sendJson({
      "type": "ACTION",
      "action_kind": "volume",
      "payload": {"level": masterVolume}
    });
  }

  void toggleMute() {
    _sendJson({
      "type": "ACTION",
      "action_kind": "mute",
      "payload": {}
    });
  }

  void toggleMicMute() {
    _sendJson({
      "type": "MIC_MUTE",
      "payload": {}
    });
  }

  // Trackpad / Bed Remote commands
  void sendTrackpadMove(double dx, double dy) {
    if (state != VibeConnectionState.connected) return;
    _sendJson({
      "type": "TRACKPAD_MOVE",
      "dx": dx,
      "dy": dy,
    });
  }

  void sendMouseClick(String button, {bool doubleClick = false}) {
    if (state != VibeConnectionState.connected) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    _sendJson({
      "type": "MOUSE_CLICK",
      "button": button,
      "double": doubleClick,
    });
  }

  void sendMouseScroll(double dy) {
    if (state != VibeConnectionState.connected) return;
    _sendJson({
      "type": "MOUSE_SCROLL",
      "dy": dy,
    });
  }

  void sendKeyType(String text) {
    if (state != VibeConnectionState.connected || text.isEmpty) return;
    _sendJson({
      "type": "KEY_TYPE",
      "text": text,
    });
  }

  void sendKeyPress(String key) {
    if (state != VibeConnectionState.connected) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    _sendJson({
      "type": "KEY_PRESS",
      "key": key,
    });
  }

  void sendPowerAction(String action) {
    if (state != VibeConnectionState.connected) return;
    _sendJson({
      "type": "POWER_ACTION",
      "action": action,
    });
  }

  void requestProfiles() {
    _sendJson({"type": "GET_PROFILES"});
  }

  void saveProfilesToServer(List<DeckProfile> profiles) {
    _sendJson({
      "type": "SAVE_PROFILES",
      "profiles": profiles.map((p) => p.toJson()).toList(),
    });
  }

  void fetchInstalledApps() {
    _sendJson({"type": "GET_APPS"});
  }

  void _sendJson(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint("WebSocket send error: $e");
    }
  }

  void _handleMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'];

      if (type == 'HELLO_ACK') {
        currentServerName = data['hostname'] ?? 'Windows Laptop';
        if (data.containsKey('volume')) masterVolume = (data['volume'] as num).toInt();
        if (data.containsKey('muted')) isMuted = data['muted'] as bool;
        if (data.containsKey('is_mic_muted')) isMicMuted = data['is_mic_muted'] as bool;
        if (data.containsKey('cpu')) cpuPercent = (data['cpu'] as num).toInt();
        if (data.containsKey('ram')) ramPercent = (data['ram'] as num).toInt();
        
        if (data.containsKey('profiles') && onProfilesReceived != null) {
          final list = (data['profiles'] as List<dynamic>)
              .map((p) => DeckProfile.fromJson(Map<String, dynamic>.from(p)))
              .toList();
          onProfilesReceived!(list);
        }
        if (data.containsKey('apps')) {
          final rawApps = (data['apps'] as List<dynamic>?) ?? [];
          installedApps = rawApps.map((a) => {
            'name': (a['name'] ?? '').toString(),
            'target': (a['target'] ?? '').toString(),
          }).toList();
        }
        notifyListeners();
      } else if (type == 'TELEMETRY' || type == 'STATE_UPDATE') {
        if (data.containsKey('volume')) masterVolume = (data['volume'] as num).toInt();
        if (data.containsKey('is_muted')) isMuted = data['is_muted'] as bool;
        if (data.containsKey('muted')) isMuted = data['muted'] as bool;
        if (data.containsKey('is_mic_muted')) isMicMuted = data['is_mic_muted'] as bool;
        if (data.containsKey('cpu')) cpuPercent = (data['cpu'] as num).toInt();
        if (data.containsKey('ram')) ramPercent = (data['ram'] as num).toInt();
        notifyListeners();
      } else if (type == 'PONG') {
        final sendTime = data['time'] as num?;
        if (sendTime != null) {
          final rtt = DateTime.now().millisecondsSinceEpoch - sendTime.toInt();
          latencyMs = rtt;
          notifyListeners();
        }
      } else if (type == 'ACTION_ACK') {
        if (data.containsKey('volume')) masterVolume = (data['volume'] as num).toInt();
        if (data.containsKey('muted')) isMuted = data['muted'] as bool;
        if (data.containsKey('is_mic_muted')) isMicMuted = data['is_mic_muted'] as bool;
        if (data.containsKey('cpu')) cpuPercent = (data['cpu'] as num).toInt();
        if (data.containsKey('ram')) ramPercent = (data['ram'] as num).toInt();
        notifyListeners();
      } else if (type == 'PROFILES_DATA') {
        if (data.containsKey('profiles') && onProfilesReceived != null) {
          final list = (data['profiles'] as List<dynamic>)
              .map((p) => DeckProfile.fromJson(Map<String, dynamic>.from(p)))
              .toList();
          onProfilesReceived!(list);
        }
      } else if (type == 'APPS_DATA') {
        if (data.containsKey('apps')) {
          final rawApps = (data['apps'] as List<dynamic>?) ?? [];
          installedApps = rawApps.map((a) => {
            'name': (a['name'] ?? '').toString(),
            'target': (a['target'] ?? '').toString(),
          }).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error handling message: $e");
    }
  }
}
