import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/deck_action.dart';
import '../services/connection_service.dart';
import '../services/storage_service.dart';
import '../theme/vibe_theme.dart';
import 'deck_button_widget.dart';
import 'connect_dialog.dart';
import 'edit_button_dialog.dart';
import 'trackpad_widget.dart';
import 'keyboard_remote_widget.dart';
import 'vibe_cyber_loader.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  final ConnectionService _conn = ConnectionService();
  List<DeckProfile> _profiles = [];
  int _currentProfileIndex = 0;
  bool _isEditMode = false;
  bool _isLoading = true;
  int _activeMode = 0; // 0: Deck, 1: Trackpad, 2: Keyboard

  @override
  void initState() {
    super.initState();
    try {
      WakelockPlus.enable();
    } catch (_) {}

    _loadInitialData();

    _conn.onProfilesReceived = (serverProfiles) {
      if (serverProfiles.isNotEmpty && mounted) {
        setState(() {
          _profiles = serverProfiles;
          if (_currentProfileIndex >= _profiles.length) {
            _currentProfileIndex = 0;
          }
        });
        StorageService.saveProfiles(_profiles);
      }
    };
  }

  Future<void> _loadInitialData() async {
    final profiles = await StorageService.loadProfiles();
    final lastProfileId = await StorageService.getSelectedProfileId();

    int idx = 0;
    if (lastProfileId != null) {
      final found = profiles.indexWhere((p) => p.id == lastProfileId);
      if (found != -1) idx = found;
    }

    if (mounted) {
      setState(() {
        _profiles = profiles;
        _currentProfileIndex = idx;
        _isLoading = false;
      });
    }

    _conn.startAutoDiscovery();
  }

  DeckProfile? get _currentProfile {
    if (_profiles.isEmpty) return null;
    if (_currentProfileIndex < 0 || _currentProfileIndex >= _profiles.length) {
      return _profiles[0];
    }
    return _profiles[_currentProfileIndex];
  }

  void _saveProfiles() {
    setState(() {});
    StorageService.saveProfiles(_profiles);
    if (_conn.state == VibeConnectionState.connected) {
      _conn.saveProfilesToServer(_profiles);
    }
  }

  void _addNewProfile() {
    final nameCtrl = TextEditingController(text: "Profile ${_profiles.length + 1}");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Deck Profile"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Profile Name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final newP = DeckProfile(
                  id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  columns: 5,
                  rows: 3,
                  buttons: [],
                );
                setState(() {
                  _profiles.add(newP);
                  _currentProfileIndex = _profiles.length - 1;
                });
                _saveProfiles();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _editButton(DeckButton? btn, int? index) {
    showDialog(
      context: context,
      builder: (ctx) => EditButtonDialog(
        initialButton: btn,
        onSave: (savedBtn) {
          final profile = _currentProfile;
          if (profile == null) return;

          setState(() {
            if (index != null && index >= 0 && index < profile.buttons.length) {
              profile.buttons[index] = savedBtn;
            } else {
              profile.buttons.add(savedBtn);
            }
          });
          _saveProfiles();
        },
        onDelete: (index != null && index >= 0)
            ? () {
                final profile = _currentProfile;
                if (profile == null) return;
                setState(() {
                  profile.buttons.removeAt(index);
                });
                _saveProfiles();
              }
            : null,
      ),
    );
  }

  void _adjustGridSize() {
    final profile = _currentProfile;
    if (profile == null) return;

    int cols = profile.columns;
    int rows = profile.rows;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: const Color(0xFF161824),
          title: const Text("Stream Deck Grid Presets", style: TextStyle(color: VibeTheme.cyanNeon)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick hardware presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      backgroundColor: (cols == 5 && rows == 3) ? VibeTheme.cyanNeon.withOpacity(0.3) : const Color(0xFF222638),
                      label: const Text("15 Keys (5x3) Standard", style: TextStyle(fontSize: 11, color: Colors.white)),
                      onPressed: () {
                        setDState(() {
                          cols = 5;
                          rows = 3;
                        });
                      },
                    ),
                    ActionChip(
                      backgroundColor: (cols == 8 && rows == 4) ? VibeTheme.purpleNeon.withOpacity(0.3) : const Color(0xFF222638),
                      label: const Text("32 Keys (8x4) XL", style: TextStyle(fontSize: 11, color: Colors.white)),
                      onPressed: () {
                        setDState(() {
                          cols = 8;
                          rows = 4;
                        });
                      },
                    ),
                    ActionChip(
                      backgroundColor: (cols == 3 && rows == 2) ? Colors.amberAccent.withOpacity(0.3) : const Color(0xFF222638),
                      label: const Text("6 Keys (3x2) Mini", style: TextStyle(fontSize: 11, color: Colors.white)),
                      onPressed: () {
                        setDState(() {
                          cols = 3;
                          rows = 2;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Columns:"),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: cols > 2 ? () => setDState(() => cols--) : null,
                        ),
                        Text("$cols", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: cols < 8 ? () => setDState(() => cols++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Rows:"),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: rows > 2 ? () => setDState(() => rows--) : null,
                        ),
                        Text("$rows", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: rows < 6 ? () => setDState(() => rows++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  profile.columns = cols;
                  profile.rows = rows;
                });
                _saveProfiles();
                Navigator.of(ctx).pop();
              },
              child: const Text("Apply Grid"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: VibeTheme.background,
        body: Center(
          child: VibeCyberLoader(statusText: "SYNCHRONIZING VIBEDECK MATRIX..."),
        ),
      );
    }

    final profile = _currentProfile;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: VibeTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Responsive Top Header Bar
                _buildTopBar(isLandscape),

                // Live Volume, Mic Mute & Telemetry Bar
                _buildTelemetryBar(isLandscape),

                // Horizontal Preset Chips (1-tap deck switching)
                if (_activeMode == 0) _buildProfileStrip(isLandscape),

                // Body based on active mode with bottom padding for dock
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLandscape ? 54 : 62),
                    child: _activeMode == 0
                        ? (profile == null ? _buildEmptyState() : _buildGrid(profile, isLandscape))
                        : (_activeMode == 1 ? const TrackpadWidget() : const KeyboardRemoteWidget()),
                  ),
                ),
              ],
            ),

            // Ergonomic Floating Cyber-Dock (Deck / Mouse / Keyboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: isLandscape ? 6 : 12,
              child: Center(
                child: _buildFloatingCyberDock(isLandscape),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isLandscape) {
    return ListenableBuilder(
      listenable: _conn,
      builder: (context, _) {
        final isConnected = _conn.state == VibeConnectionState.connected;
        final isConnecting = _conn.state == VibeConnectionState.connecting;
        final isNarrow = MediaQuery.of(context).size.width < 460;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: isLandscape ? 10 : 14, vertical: isLandscape ? 2 : 4),
          decoration: BoxDecoration(
            color: VibeTheme.surfaceHighlight.withOpacity(0.6),
            border: const Border(bottom: BorderSide(color: Colors.white12, width: 1)),
          ),
          child: Row(
            children: [
              // Logo & App Title & Connection Status
              InkWell(
                onTap: () {
                  showDialog(context: context, builder: (_) => const ConnectDialog());
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) => const Icon(Icons.stream_rounded, color: VibeTheme.cyanNeon, size: 22),
                        ),
                      ),
                      if (!isNarrow && !isLandscape) ...[
                        const SizedBox(width: 8),
                        const Text(
                          "VibeDeck",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Animated pulse status dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? const Color(0xFF00FF88)
                              : (isConnecting ? Colors.amberAccent : Colors.redAccent),
                          boxShadow: isConnected
                              ? [const BoxShadow(color: Color(0xFF00FF88), blurRadius: 6, spreadRadius: 1.5)]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Quick Action Buttons in Top Bar
              if (_activeMode == 0) ...[
                // Grid Density button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.aspect_ratio_rounded, size: 19, color: Colors.white70),
                  tooltip: "Grid Density (Rows x Cols)",
                  onPressed: _adjustGridSize,
                ),
                const SizedBox(width: 4),

                // Edit Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    _isEditMode ? Icons.done_all_rounded : Icons.edit_note_rounded,
                    color: _isEditMode ? Colors.amberAccent : Colors.white70,
                    size: 21,
                  ),
                  tooltip: _isEditMode ? "Exit Edit" : "Customize Buttons",
                  onPressed: () => setState(() => _isEditMode = !_isEditMode),
                ),
                const SizedBox(width: 4),
              ],

              // Connect / Pair Settings Dialog
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.settings_rounded, size: 19, color: Colors.white70),
                tooltip: "Pair / Connect Settings",
                onPressed: () {
                  showDialog(context: context, builder: (_) => const ConnectDialog());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Horizontal Scrollable Deck Preset Ribbon (1-Tap Switching)
  Widget _buildProfileStrip(bool isLandscape) {
    return Container(
      height: isLandscape ? 36 : 40,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _profiles.length + 1,
        itemBuilder: (context, idx) {
          if (idx == _profiles.length) {
            // "+ New Deck" Chip
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: ActionChip(
                backgroundColor: const Color(0xFF161824),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                avatar: const Icon(Icons.add_rounded, size: 16, color: VibeTheme.cyanNeon),
                label: const Text(
                  "New Deck",
                  style: TextStyle(fontSize: 11, color: VibeTheme.cyanNeon, fontWeight: FontWeight.bold),
                ),
                onPressed: _addNewProfile,
              ),
            );
          }

          final isSelected = idx == _currentProfileIndex;
          final p = _profiles[idx];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: ChoiceChip(
              selected: isSelected,
              selectedColor: VibeTheme.cyanNeon.withOpacity(0.22),
              backgroundColor: const Color(0xFF141724),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? VibeTheme.cyanNeon : Colors.white12,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              avatar: Icon(
                _getProfileIcon(p.name),
                size: 15,
                color: isSelected ? VibeTheme.cyanNeon : Colors.white60,
              ),
              label: Text(
                p.name,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _currentProfileIndex = idx);
                StorageService.saveSelectedProfileId(p.id);
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getProfileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('game') || lower.contains('play') || lower.contains('steam')) {
      return Icons.videogame_asset_rounded;
    } else if (lower.contains('media') || lower.contains('music') || lower.contains('spotify')) {
      return Icons.music_note_rounded;
    } else if (lower.contains('stream') || lower.contains('obs') || lower.contains('twitch')) {
      return Icons.smart_display_rounded;
    } else if (lower.contains('dev') || lower.contains('code') || lower.contains('work')) {
      return Icons.terminal_rounded;
    } else if (lower.contains('chat') || lower.contains('discord')) {
      return Icons.forum_rounded;
    }
    return Icons.grid_view_rounded;
  }

  // Ergonomic Floating Cyber-Dock (Deck | Mouse | Keyboard)
  Widget _buildFloatingCyberDock(bool isLandscape) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xE60D0F18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VibeTheme.cyanNeon.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: VibeTheme.cyanNeon.withOpacity(0.12),
            blurRadius: 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDockTab(0, Icons.grid_view_rounded, "Deck"),
          _buildDockTab(1, Icons.mouse_rounded, "Mouse"),
          _buildDockTab(2, Icons.keyboard_rounded, "Keys"),
        ],
      ),
    );
  }

  Widget _buildDockTab(int index, IconData icon, String label) {
    final isSelected = _activeMode == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _activeMode = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: VibeTheme.cyanNeon.withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black : Colors.white70,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryBar(bool isLandscape) {
    return ListenableBuilder(
      listenable: _conn,
      builder: (context, _) {
        final isConnected = _conn.state == VibeConnectionState.connected;
        if (!isConnected) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: isLandscape ? 8 : 12, vertical: 2),
          color: const Color(0xFF10121B),
          child: Row(
            children: [
              // Speaker Mute button with dynamic icon & color
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: Icon(
                  _conn.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: _conn.isMuted ? const Color(0xFFFF2A6D) : VibeTheme.cyanNeon,
                  size: 18,
                ),
                tooltip: _conn.isMuted ? "Unmute Speakers" : "Mute Speakers",
                onPressed: () => _conn.toggleMute(),
              ),

              // Volume Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: VibeTheme.cyanNeon,
                    thumbColor: VibeTheme.cyanNeon,
                  ),
                  child: Slider(
                    value: _conn.masterVolume.toDouble(),
                    min: 0,
                    max: 100,
                    onChanged: (val) => _conn.setVolume(val.round()),
                  ),
                ),
              ),
              Text(
                "${_conn.masterVolume}%",
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
              ),

              const SizedBox(width: 12),

              // Mic Mute Button with Real-time Windows / Discord State
              InkWell(
                onTap: () => _conn.toggleMicMute(),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _conn.isMicMuted ? const Color(0xFFFF2A6D).withOpacity(0.2) : const Color(0xFF00FF88).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _conn.isMicMuted ? const Color(0xFFFF2A6D) : const Color(0xFF00FF88),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _conn.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        size: 13,
                        color: _conn.isMicMuted ? const Color(0xFFFF2A6D) : const Color(0xFF00FF88),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _conn.isMicMuted ? "MIC OFF" : "MIC ON",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: _conn.isMicMuted ? const Color(0xFFFF2A6D) : const Color(0xFF00FF88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Live CPU & RAM Badges
              Text(
                "CPU ${_conn.cpuPercent}%",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _conn.cpuPercent > 80 ? const Color(0xFFFF2A6D) : Colors.white60,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "RAM ${_conn.ramPercent}%",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _conn.ramPercent > 85 ? const Color(0xFFFF2A6D) : Colors.white60,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          const Text("No profile found", style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _addNewProfile, child: const Text("Create Profile")),
        ],
      ),
    );
  }

  Widget _buildGrid(DeckProfile profile, bool isLandscape) {
    final buttons = profile.buttons;
    final totalSlots = profile.columns * profile.rows;
    final padding = isLandscape ? 6.0 : 10.0;
    final spacing = isLandscape ? 6.0 : 8.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;
          final cols = profile.columns;
          final rows = profile.rows;

          // Dynamically compute cell aspect ratio so ALL buttons fit in landscape without scrolling!
          double childAspectRatio = 1.0;
          if (isLandscape && rows > 0 && cols > 0) {
            final cellW = (availableWidth - (spacing * (cols - 1))) / cols;
            final cellH = (availableHeight - (spacing * (rows - 1))) / rows;
            if (cellW > 0 && cellH > 0) {
              childAspectRatio = cellW / cellH;
            }
          }

          return GridView.builder(
            physics: isLandscape ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _isEditMode ? totalSlots : buttons.length,
            itemBuilder: (context, idx) {
              if (idx < buttons.length) {
                final btn = buttons[idx];
                return DeckButtonWidget(
                  button: btn,
                  isEditMode: _isEditMode,
                  onTap: () {
                    if (_isEditMode) {
                      _editButton(btn, idx);
                    } else {
                      _conn.sendAction(btn);
                    }
                  },
                  onLongPress: () {
                    _editButton(btn, idx);
                  },
                );
              } else {
                // Empty placeholder slot in edit mode
                return InkWell(
                  onTap: () => _editButton(null, idx),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, style: BorderStyle.solid, width: 1),
                      color: Colors.white.withOpacity(0.03),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: isLandscape ? 20 : 28, color: Colors.white38),
                          if (!isLandscape) ...[
                            const SizedBox(height: 4),
                            Text("Slot ${idx + 1}", style: const TextStyle(color: Colors.white30, fontSize: 11)),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
