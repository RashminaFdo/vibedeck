import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/deck_action.dart';
import '../services/connection_service.dart';
import '../services/storage_service.dart';
import '../theme/vibe_theme.dart';
import 'deck_button_widget.dart';
import 'connect_dialog.dart';
import 'edit_button_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    // Keep screen awake while using VibeDeck
    try {
      WakelockPlus.enable();
    } catch (_) {}

    _loadInitialData();

    // Hook profile reception from server
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

    // Auto-discover server on startup
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
                  columns: 3,
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
          title: const Text("Grid Size"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      Text("$cols", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: cols < 6 ? () => setDState(() => cols++) : null,
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
                      Text("$rows", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              child: const Text("Apply"),
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
        body: Center(child: CircularProgressIndicator(color: VibeTheme.cyanNeon)),
      );
    }

    final profile = _currentProfile;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Two-way feedback volume bar
            _buildVolumeFeedbackBar(),

            // Main Deck Grid
            Expanded(
              child: profile == null
                  ? const Center(child: Text("No profiles available"))
                  : _buildGrid(profile),
            ),

            // Bottom Profile Selector Bar
            _buildBottomProfileBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return ListenableBuilder(
      listenable: _conn,
      builder: (context, _) {
        final isConnected = _conn.state == VibeConnectionState.connected;
        final isConnecting = _conn.state == VibeConnectionState.connecting ||
            _conn.state == VibeConnectionState.discovering;

        Color statusColor = Colors.redAccent;
        String statusText = "Offline";
        IconData statusIcon = Icons.cloud_off_rounded;

        if (isConnected) {
          statusColor = VibeTheme.greenNeon;
          statusText = "${_conn.currentServerName} (${_conn.latencyMs}ms)";
          statusIcon = Icons.check_circle_rounded;
        } else if (isConnecting) {
          statusColor = Colors.amber;
          statusText = _conn.state == VibeConnectionState.discovering ? "Searching..." : "Connecting...";
          statusIcon = Icons.sync_rounded;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: const BoxDecoration(
            color: VibeTheme.surface,
            border: Border(bottom: BorderSide(color: VibeTheme.border, width: 1)),
          ),
          child: Row(
            children: [
              // Logo
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dialpad_rounded, color: VibeTheme.primaryNeon, size: 20),
                  SizedBox(width: 5),
                  Text(
                    "VibeDeck",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Status Pill (Flexible with text ellipsis to prevent any overflow)
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    showDialog(context: context, builder: (_) => const ConnectDialog());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Action Buttons with compact sizing
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.grid_view_rounded, size: 19),
                tooltip: "Grid Size",
                onPressed: _adjustGridSize,
              ),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: Icon(
                  _isEditMode ? Icons.done_all_rounded : Icons.edit_note_rounded,
                  color: _isEditMode ? Colors.amberAccent : Colors.white70,
                  size: 21,
                ),
                tooltip: _isEditMode ? "Exit Edit Mode" : "Customize Buttons",
                onPressed: () => setState(() => _isEditMode = !_isEditMode),
              ),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.settings_rounded, size: 19),
                tooltip: "Connection Settings",
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

  Widget _buildVolumeFeedbackBar() {
    return ListenableBuilder(
      listenable: _conn,
      builder: (context, _) {
        final isConnected = _conn.state == VibeConnectionState.connected;
        if (!isConnected) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: VibeTheme.surfaceHighlight.withOpacity(0.4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _conn.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: _conn.isMuted ? Colors.redAccent : VibeTheme.cyanNeon,
                  size: 20,
                ),
                onPressed: () => _conn.toggleMute(),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
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
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(DeckProfile profile) {
    final buttons = profile.buttons;
    final totalSlots = profile.columns * profile.rows;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: profile.columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
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
              onLongPress: () => _editButton(btn, idx),
            );
          } else {
            // Empty placeholder slot in edit mode
            return GestureDetector(
              onTap: () => _editButton(null, idx),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, size: 28, color: Colors.white38),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBottomProfileBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: VibeTheme.surface,
        border: Border(top: BorderSide(color: VibeTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _profiles.length,
              itemBuilder: (context, idx) {
                final p = _profiles[idx];
                final isSelected = idx == _currentProfileIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(p.name),
                    selected: isSelected,
                    selectedColor: VibeTheme.primaryNeon.withOpacity(0.3),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                      color: isSelected ? VibeTheme.primaryNeon : Colors.transparent,
                      width: 1.5,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.white60,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _currentProfileIndex = idx);
                        StorageService.saveSelectedProfileId(p.id);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 20),
            tooltip: "New Profile",
            onPressed: _addNewProfile,
          ),
        ],
      ),
    );
  }
}
