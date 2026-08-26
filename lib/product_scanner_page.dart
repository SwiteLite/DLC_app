import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'open_food_facts_service.dart';

class ProductScannerPage extends StatefulWidget {
  const ProductScannerPage({super.key});

  @override
  State<ProductScannerPage> createState() => _ProductScannerPageState();
}

class _ProductScannerPageState extends State<ProductScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.dataMatrix,
    ],
  );
  final OpenFoodFactsService _openFoodFacts = OpenFoodFactsService();

  bool _handlingScan = false;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingScan) return;

    final barcodes = capture.barcodes;
    String? raw;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        raw = value;
        break;
      }
    }

    if (raw == null) return;

    final barcode = OpenFoodFactsService.extractBarcode(raw);
    if (barcode == null) {
      setState(() {
        _statusMessage = 'Code reconnu, mais aucun code produit exploitable.';
      });
      return;
    }

    setState(() {
      _handlingScan = true;
      _statusMessage = 'Produit trouvé ($barcode), recherche…';
    });

    await _controller.stop();

    try {
      final product = await _openFoodFacts.fetchProduct(barcode);
      if (!mounted) return;

      if (!product.found) {
        setState(() {
          _statusMessage =
              'Produit $barcode introuvable sur Open Food Facts. Saisie manuelle possible.';
          _handlingScan = false;
        });
        await _controller.start();
        return;
      }

      Navigator.of(context).pop(product);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Erreur réseau. Vérifiez votre connexion.';
        _handlingScan = false;
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un produit'),
        actions: [
          IconButton(
            tooltip: 'Torche',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_handlingScan) ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _statusMessage ??
                        'Cadrez le code-barres ou le QR code du produit.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
