import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import 'date_parser.dart';

class DlcScannerPage extends StatefulWidget {
  const DlcScannerPage({super.key});

  @override
  State<DlcScannerPage> createState() => _DlcScannerPageState();
}

class _DlcScannerPageState extends State<DlcScannerPage> {
  static const _throttle = Duration(milliseconds: 700);

  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _initializing = true;
  bool _isBusy = false;
  bool _confirming = false;
  String? _error;
  String? _statusMessage;
  String _liveRawText = '';
  /// Dates figées dès qu'une détection réussit ; ne sont pas effacées
  /// si les frames suivantes ne voient plus rien.
  List<ParsedDate> _lockedDates = const [];
  String _lockedRawText = '';
  List<ParsedDate> _candidates = const [];
  DateTime? _lastProcessedAt;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _currentZoom = 1.5;

  final List<String> _logLines = [];
  final ScrollController _logScrollController = ScrollController();

  bool get _hasLockedDates => _lockedDates.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'Aucune caméra disponible.';
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = (_minZoom + 0.8).clamp(_minZoom, _maxZoom);
      await controller.setZoomLevel(_currentZoom);

      await controller.startImageStream(_processCameraImage);

      setState(() {
        _cameraController = controller;
        _initializing = false;
        _statusMessage = 'Cadrez la DLC dans le cadre (zoom ${_currentZoom.toStringAsFixed(1)}x).';
      });
      _appendLog('Caméra prête. OCR temps réel démarré (zoom ${_currentZoom.toStringAsFixed(1)}x).');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Impossible d\'ouvrir la caméra.';
      });
    }
  }

  void _appendLog(String line) {
    final stamp = DateFormat('HH:mm:ss').format(DateTime.now());
    setState(() {
      _logLines.add('[$stamp] $line');
      if (_logLines.length > 40) {
        _logLines.removeRange(0, _logLines.length - 40);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_logScrollController.hasClients) return;
      _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _confirming || _cameraController == null) return;

    final now = DateTime.now();
    if (_lastProcessedAt != null &&
        now.difference(_lastProcessedAt!) < _throttle) {
      return;
    }

    _isBusy = true;
    _lastProcessedAt = now;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final recognized = await _textRecognizer.processImage(inputImage);
      final raw = recognized.text.trim();
      final dates = DateParser.extractDates(raw);

      if (!mounted) return;

      final lockedBefore = _lockedDates.isNotEmpty;
      final shouldLock = dates.isNotEmpty;
      final firstLock = shouldLock && _lockedDates.isEmpty;

      setState(() {
        _liveRawText = raw;

        // Ne verrouille / met à jour que lorsqu'une date est vraiment trouvée.
        if (shouldLock) {
          _lockedDates = dates;
          _lockedRawText = raw;
        }

        _statusMessage = _buildStatusMessage(raw: raw, liveDates: dates);
      });

      if (firstLock) {
        _appendLog(
          'Date verrouillée : ${dates.map((d) => DateFormat('dd/MM/yyyy').format(d.date)).join(', ')}',
        );
      }

      if (raw.isNotEmpty) {
        final preview = raw.length > 120 ? '${raw.substring(0, 120)}…' : raw;
        _appendLog('OCR: $preview');
        if (dates.isNotEmpty) {
          final datesText = dates
              .map((d) => DateFormat('dd/MM/yyyy').format(d.date))
              .join(', ');
          _appendLog('Dates: $datesText');
        } else if (lockedBefore) {
          _appendLog('Pas de date sur cette frame (verrouillage conservé).');
        }
      }
    } catch (e) {
      _appendLog('Erreur OCR: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final sensorOrientation = controller.description.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final deviceOrientation = controller.value.deviceOrientation;
      final orientations = <DeviceOrientation, int>{
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      var rotationCompensation = orientations[deviceOrientation];
      if (rotationCompensation == null) return null;

      if (controller.description.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  String _buildStatusMessage({
    required String raw,
    required List<ParsedDate> liveDates,
  }) {
    if (_lockedDates.length == 1) {
      final label = DateFormat('dd/MM/yyyy').format(_lockedDates.first.date);
      if (liveDates.isEmpty) {
        return 'Date verrouillée : $label — prête à valider.';
      }
      return 'Date verrouillée : $label';
    }
    if (_lockedDates.length > 1) {
      return '${_lockedDates.length} dates verrouillées — choisissez ou validez.';
    }
    if (raw.isEmpty) return 'Aucun texte détecté…';
    if (liveDates.isEmpty) return 'Texte détecté, aucune date trouvée.';
    return 'Pointez la DLC — détection en direct.';
  }

  void _clearLockedDates() {
    setState(() {
      _lockedDates = const [];
      _lockedRawText = '';
      _candidates = const [];
      _statusMessage = 'Verrouillage effacé. Pointez à nouveau la DLC.';
    });
    _appendLog('Verrouillage effacé.');
  }

  Future<void> _confirmCurrentDetection() async {
    if (_confirming) return;

    if (_lockedDates.length == 1) {
      Navigator.of(context).pop(_lockedDates.first.date);
      return;
    }

    if (_lockedDates.length > 1) {
      setState(() {
        _candidates = _lockedDates;
        _statusMessage = 'Plusieurs dates — choisissez la DLC.';
      });
      return;
    }

    // Fallback: take a still photo for a higher-res OCR pass
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _confirming = true;
      _statusMessage = 'Capture haute résolution…';
    });
    _appendLog('Capture photo pour confirmation…');

    try {
      await controller.stopImageStream();
      final picture = await controller.takePicture();
      final croppedPath = await _cropCenterFrame(picture.path);
      final ocrPath = croppedPath ?? picture.path;
      final recognized =
          await _textRecognizer.processImage(InputImage.fromFilePath(ocrPath));
      final dates = DateParser.extractDates(recognized.text);

      _appendLog(
        recognized.text.trim().isEmpty
            ? 'Photo crop: aucun texte'
            : 'Photo crop OCR: ${recognized.text.trim()}',
      );

      if (!mounted) return;

      if (dates.isEmpty) {
        setState(() {
          _confirming = false;
          _statusMessage = _hasLockedDates
              ? _buildStatusMessage(raw: '', liveDates: const [])
              : 'Aucune date. Recadrez ou utilisez Manuel.';
        });
        await controller.startImageStream(_processCameraImage);
        return;
      }

      setState(() {
        _lockedDates = dates;
        _lockedRawText = recognized.text.trim();
        _confirming = false;
      });

      if (dates.length == 1) {
        Navigator.of(context).pop(dates.first.date);
        return;
      }

      setState(() {
        _candidates = dates;
        _statusMessage = 'Plusieurs dates — choisissez la DLC.';
      });
      await controller.startImageStream(_processCameraImage);
    } catch (e) {
      _appendLog('Erreur capture: $e');
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _statusMessage = 'Échec de la capture.';
      });
      try {
        await controller.startImageStream(_processCameraImage);
      } catch (_) {}
    }
  }

  Future<String?> _cropCenterFrame(String sourcePath) async {
    try {
      final bytes = await File(sourcePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Approx. the on-screen white frame: ~70% width, ~28% height, centered.
      final cropW = (decoded.width * 0.70).round().clamp(1, decoded.width);
      final cropH = (decoded.height * 0.28).round().clamp(1, decoded.height);
      final left = ((decoded.width - cropW) / 2).round();
      final top = ((decoded.height - cropH) / 2).round();

      final cropped = img.copyCrop(
        decoded,
        x: left,
        y: top,
        width: cropW,
        height: cropH,
      );

      // Mild contrast boost helps stamped dates.
      final enhanced = img.adjustColor(cropped, contrast: 1.15);
      final outPath = '${sourcePath}_crop.jpg';
      await File(outPath).writeAsBytes(img.encodeJpg(enhanced, quality: 95));
      _appendLog('Crop cadre central appliqué (${cropW}x$cropH).');
      return outPath;
    } catch (e) {
      _appendLog('Crop impossible: $e');
      return null;
    }
  }

  Future<void> _setZoom(double value) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final zoom = value.clamp(_minZoom, _maxZoom);
    await controller.setZoomLevel(zoom);
    setState(() => _currentZoom = zoom);
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final next = controller.value.flashMode == FlashMode.torch
        ? FlashMode.off
        : FlashMode.torch;
    await controller.setFlashMode(next);
    setState(() {});
  }

  @override
  void dispose() {
    final controller = _cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    _textRecognizer.close();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner la DLC'),
        actions: [
          IconButton(
            tooltip: 'Torche',
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleTorch,
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                helpText: 'Saisir la DLC',
                cancelText: 'Annuler',
                confirmText: 'Valider',
              );
              if (picked != null && context.mounted) {
                Navigator.of(context).pop(picked);
              }
            },
            child: const Text('Manuel'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final controller = _cameraController!;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 280,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF60D394), width: 3),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF60D394).withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: _buildLiveLogPanel(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusMessage ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (_maxZoom > _minZoom) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.zoom_out, color: Colors.white70, size: 18),
                      Expanded(
                        child: Slider(
                          value: _currentZoom.clamp(_minZoom, _maxZoom),
                          min: _minZoom,
                          max: _maxZoom,
                          onChanged: _setZoom,
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: Colors.white70, size: 18),
                    ],
                  ),
                ],
                if (_hasLockedDates) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ..._lockedDates.map((candidate) {
                        final label =
                            DateFormat('dd/MM/yyyy').format(candidate.date);
                        return ActionChip(
                          avatar: const Icon(Icons.lock, size: 16),
                          label: Text(label),
                          onPressed: () =>
                              Navigator.of(context).pop(candidate.date),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.refresh, size: 16),
                        label: const Text('Effacer'),
                        onPressed: _clearLockedDates,
                      ),
                    ],
                  ),
                ],
                if (_candidates.isNotEmpty &&
                    !listEquals(_candidates, _lockedDates)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _candidates.map((candidate) {
                      final label =
                          DateFormat('dd/MM/yyyy').format(candidate.date);
                      return ActionChip(
                        label: Text('Photo: $label'),
                        onPressed: () =>
                            Navigator.of(context).pop(candidate.date),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _confirming ? null : _confirmCurrentDetection,
                  icon: _confirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _confirming
                        ? 'Analyse…'
                        : (_hasLockedDates
                            ? 'Valider la date verrouillée'
                            : 'Capturer / forcer OCR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveLogPanel() {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'OCR live (vert) vs verrouillé (ambre)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (_hasLockedDates) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amberAccent),
                ),
                child: Text(
                  'VERROUILLÉ : ${_lockedDates.map((d) => DateFormat('dd/MM/yyyy').format(d.date)).join(', ')}'
                  '${_lockedRawText.isNotEmpty ? '\n« ${_lockedRawText.length > 80 ? '${_lockedRawText.substring(0, 80)}…' : _lockedRawText} »' : ''}',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.lightGreenAccent),
              ),
              child: Text(
                _liveRawText.isEmpty
                    ? 'LIVE : en attente de texte…'
                    : 'LIVE : $_liveRawText',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _logLines.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logLines[index],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      height: 1.25,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
