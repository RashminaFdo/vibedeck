import 'package:flutter/material.dart';
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
        horizontal: isLandscape ? 24 : 16,
        vertical: isLandscape ? 12 : 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 620 : 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 14 : 18),
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
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(Icons.hub_rounded, color: VibeTheme.cyanNeon),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Connect to Laptop",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Tabs
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

              // Tab Views
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
                  width: isLandscape ? 60 : 72,
                  height: isLandscape ? 60 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VibeTheme.cyanNeon.withOpacity(0.12),
                    border: Border.all(color: VibeTheme.cyanNeon.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(
                    Icons.wifi_find_rounded,
                    size: isLandscape ? 32 : 38,
                    color: VibeTheme.cyanNeon,
                  ),
                ),
              SizedBox(height: isLandscape ? 10 : 16),
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
              SizedBox(height: isLandscape ? 12 : 18),
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
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
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
                    width: 160,
                    height: 160,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_ethernet_rounded, size: isLandscape ? 36 : 44, color: VibeTheme.primaryNeon),
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Enter your laptop's local IP address and port:",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
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
      ),
    );
  }
}
