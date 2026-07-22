import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Auf welchen Plattformen die Kamera zum Scannen zur Verfügung steht.
///
/// Auf dem Desktop gibt es keinen Kamera-Scanner; dort wird der Code über ein
/// Eingabefeld erfasst, was auch USB-Handscanner unterstützt, weil diese sich
/// wie eine Tastatur verhalten.
bool get isCameraScanSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Erfasst einen Barcode und gibt ihn zurück, oder `null` bei Abbruch.
Future<String?> scanBarcode(BuildContext context) {
  if (isCameraScanSupported) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _CameraScanScreen()),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (_) => const _ManualBarcodeDialog(),
  );
}

class _CameraScanScreen extends StatefulWidget {
  const _CameraScanScreen();

  @override
  State<_CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<_CameraScanScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.qrCode,
    ],
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode scannen'),
        actions: [
          IconButton(
            tooltip: 'Blitz',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: 'Kamera wechseln',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ScanFrame(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final code = await showDialog<String>(
                    context: context,
                    builder: (_) => const _ManualBarcodeDialog(),
                  );
                  if (code != null && context.mounted) {
                    Navigator.of(context).pop(code);
                  }
                },
                icon: const Icon(Icons.keyboard_alt_outlined),
                label: const Text('Code eintippen'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ManualBarcodeDialog extends StatefulWidget {
  const _ManualBarcodeDialog();

  @override
  State<_ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<_ManualBarcodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Barcode eingeben'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Barcode',
              hintText: 'z.B. 4001234567890',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Text(
            'Ein USB-Handscanner tippt den Code direkt in dieses Feld.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Übernehmen')),
      ],
    );
  }
}
