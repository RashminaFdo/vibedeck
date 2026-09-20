import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/connection_service.dart';
import '../services/storage_service.dart';
import '../theme/vibe_theme.dart';

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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hub_rounded, color: VibeTheme.cyanNeon),
                    SizedBox(width: 8),
                    Text(
                      "Connect to Laptop",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: VibeTheme.cyanNeon,
              labelColor: VibeTheme.cyanNeon,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.radar_rounded, size: 20), text: "Auto Wi-Fi"),
                Tab(icon: Icon(Icons.qr_code_scanner_rounded, size: 20), text: "QR Scan"),
                Tab(icon: Icon(Icons.usb_rounded, size: 20), text: "USB Cable"),
                Tab(icon: Icon(Icons.edit_road_rounded, size: 20), text: "Manual IP"),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAutoDiscoverTab(),
                  _buildQrScanTab(),
                  _buildUsbTab(),
                  _buildManualIpTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: Auto Discovery
  Widget _buildAutoDiscoverTab() {
    return ListenableBuilder(
      listenable: _conn,
      builder: (context, _) {
        final isDiscovering = _conn.state == VibeConnectionState.discovering;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VibeTheme.cyanNeon.withOpacity(0.12),
                  border: Border.all(color: VibeTheme.cyanNeon.withOpacity(0.4), width: 2),
                ),
                child: Icon(
                  isDiscovering ? Icons.radar_rounded : Icons.wifi_find_rounded,
                  size: 44,
                  color: VibeTheme.cyanNeon,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isDiscovering ? "Searching for VibeDeck Server..." : "Zero-Config Auto-Discovery",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Make sure your laptop and phone are on the same Wi-Fi network and VibeDeck Server is running.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              if (_conn.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _conn.lastError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VibeTheme.cyanNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: isDiscovering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(
                  isDiscovering ? "Searching Wi-Fi..." : "Find My Laptop",
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
          "Scan the QR code shown in your laptop terminal",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: VibeTheme.cyanNeon, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
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
  Widget _buildUsbTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VibeTheme.greenNeon.withOpacity(0.12),
                border: Border.all(color: VibeTheme.greenNeon.withOpacity(0.4), width: 2),
              ),
              child: const Icon(
                Icons.usb_rounded,
                size: 44,
                color: VibeTheme.greenNeon,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Zero-Lag USB Cable Mode",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "1. Connect phone to laptop with USB cable.\n2. Enable USB debugging in developer options.\n3. Run 'setup_usb_connection.bat' on your laptop.\n4. Tap the button below to connect with ~0ms latency!",
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.grey, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VibeTheme.greenNeon,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.cable_rounded),
              label: const Text(
                "Connect via USB (127.0.0.1)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                _conn.connectUsb();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  // TAB 4: Manual IP
  Widget _buildManualIpTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings_ethernet_rounded, size: 48, color: VibeTheme.primaryNeon),
          const SizedBox(height: 16),
          const Text(
            "Enter Laptop IP Address & Port",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "Check your laptop terminal banner for the exact local IP.",
            style: TextStyle(color: Colors.grey, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: "Host IP (e.g. 192.168.1.5:8765)",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.laptop_chromebook_rounded),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: VibeTheme.primaryNeon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.login_rounded),
            label: const Text(
              "Connect to Host",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _connectWithUrl(_ipController.text),
          ),
        ],
      ),
    );
  }
}
