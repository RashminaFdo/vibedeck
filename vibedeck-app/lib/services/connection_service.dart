import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
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
    
    // Clean up previous connection
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

      // Listen to incoming messages
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
    // Standard ADB reverse forwarded endpoint
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
          lastError = "No VibeDeck host found on Wi-Fi. Try QR scan or manual IP.";
          notifyListeners();
        }
      });

      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = _udpSocket?.receive();
          if (dg != null) {
            try {
              final message = utf8.decode(dg.data);
              final json = jsonDecode(message);
              if (json['service'] == 'vibedeck') {
                final ip = json['ip'] ?? dg.address.address;
                final port = json['port'] ?? 8765;
                _udpSocket?.close();
                connect("ws://$ip:$port");
              }
            } catch (_) {}
          }
        }
      });
    } catch (e) {
      state = VibeConnectionState.disconnected;
      lastError = "Auto-discovery error: $e";
      notifyListeners();
    }
  }

  void disconnect() {
    _shouldAutoReconnect = false;
    _disconnectInternal();
  }

  void _disconnectInternal({bool silent = false}) {
    _pingTimer?.cancel();
    _pingTimer = null;
    _udpSocket?.close();
    _udpSocket = null;
    try {
      _channel?.sink.close(status.goingAway);
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

    // Auto-reconnect after 3 seconds if not intentionally disconnected
    if (_shouldAutoReconnect && _lastConnectedUrl != null) {
      Timer(const Duration(seconds: 3), () {
        if (state == VibeConnectionState.disconnected && _shouldAutoReconnect) {
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

    // Haptic feedback
    try {
      HapticFeedback.heavyImpact();
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
      "action_kind": "media",
      "payload": {"key": "volume_mute"}
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
        if (data.containsKey('volume')) {
          masterVolume = (data['volume'] as num).toInt();
        }
        if (data.containsKey('muted')) {
          isMuted = data['muted'] as bool;
        }
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
      } else if (type == 'PONG') {
        final sendTime = data['time'] as num?;
        if (sendTime != null) {
          final rtt = DateTime.now().millisecondsSinceEpoch - sendTime.toInt();
          latencyMs = rtt;
          notifyListeners();
        }
      } else if (type == 'ACTION_ACK') {
        if (data.containsKey('volume')) {
          masterVolume = (data['volume'] as num).toInt();
        }
        if (data.containsKey('muted')) {
          isMuted = data['muted'] as bool;
        }
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
