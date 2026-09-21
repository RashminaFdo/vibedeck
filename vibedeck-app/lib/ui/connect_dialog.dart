import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/connection_service.dart';
import '../services/storage_service.dart';
import '../theme/vibe_theme.dart';
import 'vibe_cyber_loader.dart';

class ConnectDialog extends StatefulWidget {
  const ConnectDialog({super.key});

  @override
  State<ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<ConnectDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();
  final ConnectionService _conn = ConnectionService();
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    StorageService.getLastHost().then((saved) {
      if (saved != null && mounted) {
        _ipController.text = saved;
      } else {
        _ipController.text = "192.168.1.100:8765";
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _connectWithUrl(String url) {
    String clean = url.trim();
    if (clean.startsWith("vibedeck://")) {
      clean = clean.replaceFirst("vibedeck://", "ws://");
    }
    if (!clean.startsWith("ws://") && !clean.startsWith("wss://")) {
      clean = "ws://$clean";
    }

    StorageService.saveLastHost(clean);
    _conn.connect(clean);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      backgroundColor: const Color(0xFF131622),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 20 : 16,
        vertical: isLandscape ? 10 : 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 640 : 460,
          maxHeight: isLandscape ? 330 : MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 12 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (_, __, ___) => const Icon(Icons.hub_rounded, color: VibeTheme.cyanNeon),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Connect to Laptop",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // LANDSCAPE: 2-Column Split (Left: Navigation Rail, Right: Tab View)
              if (isLandscape)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Column: Vertical Navigation Rail
                      Container(
                        width: 140,
                        decoration: const BoxDecoration(
                          border: Border(right: BorderSide(color: Colors.white12, width: 1)),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            _buildLandscapeNavTile(0, Icons.radar_rounded, "Auto Wi-Fi"),
                            _buildLandscapeNavTile(1, Icons.qr_code_scanner_rounded, "QR Scan"),
                            _buildLandscapeNavTile(2, Icons.usb_rounded, "USB Cable"),
                            _buildLandscapeNavTile(3, Icons.edit_road_rounded, "Manual IP"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Right Column: Active Tab Content
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            switch (_tabController.index) {
                              case 0:
                                return _buildAutoDiscoverTab(isLandscape);
                              case 1:
                                return _buildQrScanTab();
                              case 2:
                                return _buildUsbTab(isLandscape);
                              case 3:
                                return _buildManualIpTab(isLandscape);
                              default:
                                return _buildAutoDiscoverTab(isLandscape);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // PORTRAIT: Traditional TabBar + TabBarView
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: VibeTheme.cyanNeon,
                  labelColor: VibeTheme.cyanNeon,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(icon: Icon(Icons.radar_rounded, size: 18), text: "Auto Wi-Fi"),
                    Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 18), text: "QR Scan"),
                    Tab(icon: Icon(Icons.usb_rounded, size: 18), text: "USB Cable"),
                    Tab(icon: Icon(Icons.edit_road_rounded, size: 18), text: "Manual IP"),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAutoDiscoverTab(isLandscape),
                      _buildQrScanTab(),
                      _buildUsbTab(isLandscape),
                      _buildManualIpTab(isLandscape),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeNavTile(int index, IconData icon, String title) {
    final isSelected = _tabController.index == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.selectionClick();
            _tabController.animateTo(index);
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? VibeTheme.cyanNeon.withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? VibeTheme.cyanNeon.withOpacity(0.6) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: isSelected ? VibeTheme.cyanNeon : Colors.white60),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: Auto Discovery
  Widget _buildAutoDiscoverTab(bool isLandscape) {
    return ListenableBuilder(
      listenable: _conn,
      builder: (context, _) {
        final isDiscovering = _conn.state == VibeConnectionState.discovering;

        if (isLandscape) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Beacon Radar
                  if (isDiscovering)
                    const VibeCyberLoader(statusText: "SCANNING...", size: 54)
                  else
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VibeTheme.cyanNeon.withOpacity(0.12),
                        border: Border.all(color: VibeTheme.cyanNeon.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.wifi_find_rounded, size: 30, color: VibeTheme.cyanNeon),
                    ),
                  const SizedBox(width: 16),

                  // Content & Action Button (Never Clipped!)
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDiscovering ? "Searching for VibeDeck Server..." : "Zero-Config Auto-Discovery",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Ensure laptop and phone are on the same Wi-Fi with VibeDeck Server running.",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        if (_conn.lastError != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            _conn.lastError!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VibeTheme.cyanNeon,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: isDiscovering
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.search_rounded, size: 16),
                          label: Text(
                            isDiscovering ? "Searching Wi-Fi..." : "Find My Laptop",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: isDiscovering ? null : () => _conn.startAutoDiscovery(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Portrait layout
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDiscovering)
                const VibeCyberLoader(
                  statusText: "SCANNING WI-FI BEACON...",
                  size: 80,
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VibeTheme.cyanNeon.withOpacity(0.12),
                    border: Border.all(color: VibeTheme.cyanNeon.withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(
                    Icons.wifi_find_rounded,
                    size: 38,
                    color: VibeTheme.cyanNeon,
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                isDiscovering ? "Searching for VibeDeck Server..." : "Zero-Config Auto-Discovery",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Ensure your laptop and phone are on the same Wi-Fi network with VibeDeck Server running.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              if (_conn.lastError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _conn.lastError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VibeTheme.cyanNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isDiscovering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  isDiscovering ? "Searching Wi-Fi..." : "Find My Laptop",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: isDiscovering ? null : () => _conn.startAutoDiscovery(),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 2: QR Scanner
  Widget _buildQrScanTab() {
    return Column(
      children: [
        const Text(
          "Scan the QR code shown in your laptop terminal or tray app",
          style: TextStyle(fontSize: 11.5, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController ??= MobileScannerController(),
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        final raw = barcode.rawValue!;
                        if (raw.contains("vibedeck") || raw.contains(":")) {
                          _scannerController?.stop();
                          _connectWithUrl(raw);
                          break;
                        }
                      }
                    }
                  },
                ),
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: VibeTheme.cyanNeon, width: 2.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 3: USB Cable Support
  Widget _buildUsbTab(bool isLandscape) {
    if (isLandscape) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.settings_ethernet_rounded, size: 38, color: VibeTheme.primaryNeon),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Ultra-Low Latency USB Mode",
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "1. Connect USB with USB Debugging enabled.\n"
                      "2. Run setup_usb_connection.bat on PC.\n"
                      "3. Tap Connect USB below.",
                      style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VibeTheme.primaryNeon,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.cable_rounded, size: 16),
                      label: const Text("Connect USB (127.0.0.1)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () => _connectWithUrl("ws://127.0.0.1:8765"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_ethernet_rounded, size: 44, color: VibeTheme.primaryNeon),
          const SizedBox(height: 8),
          const Text(
            "Ultra-Low Latency USB Mode",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "1. Connect phone via USB with USB Debugging enabled.\n"
            "2. Run setup_usb_connection.bat on your PC.\n"
            "3. Tap Connect USB below.",
            textAlign: TextAlign.left,
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: VibeTheme.primaryNeon,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.cable_rounded, size: 18),
            label: const Text("Connect via USB (127.0.0.1)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => _connectWithUrl("ws://127.0.0.1:8765"),
          ),
        ],
      ),
    );
  }

  // TAB 4: Manual IP
  Widget _buildManualIpTab(bool isLandscape) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLandscape ? 8.0 : 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: isLandscape ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const Text(
            "Enter your laptop's local IP address and port:",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (isLandscape)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: "Host IP & Port",
                      hintText: "192.168.1.100:8765",
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.wifi_rounded, size: 18),
                    ),
                    onSubmitted: (val) => _connectWithUrl(val),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VibeTheme.cyanNeon,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: const Text("Connect", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () {
                    if (_ipController.text.isNotEmpty) {
                      _connectWithUrl(_ipController.text);
                    }
                  },
                ),
              ],
            )
          else ...[
            TextField(
              controller: _ipController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: "Host IP & Port",
                hintText: "192.168.1.100:8765",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.wifi_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VibeTheme.cyanNeon,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text("Connect Manually", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                if (_ipController.text.isNotEmpty) {
                  _connectWithUrl(_ipController.text);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
