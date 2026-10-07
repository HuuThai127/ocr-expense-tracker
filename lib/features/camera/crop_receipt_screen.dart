import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../core/errors/app_exception.dart';
import '../../services/ocr/receipt_ocr_service.dart';
import '../../services/storage/receipt_storage_service.dart';
import '../review/review_expense_screen.dart';

class CropReceiptScreen extends StatefulWidget {
  final File imageFile;

  const CropReceiptScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<CropReceiptScreen> createState() => _CropReceiptScreenState();
}

class _CropReceiptScreenState extends State<CropReceiptScreen> {
  final ReceiptOcrService _ocrService = ReceiptOcrService();
  final ReceiptStorageService _storageService = ReceiptStorageService();

  bool _isProcessing = false;
  String _statusMessage = 'Adjust receipt crop area';

  // Crop rectangle ratios (0.0 to 1.0)
  Rect _cropRectFraction = const Rect.fromLTWH(0.08, 0.12, 0.84, 0.76);

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _processAndProceed({bool crop = true}) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Recognizing receipt with on-device ML Kit...';
    });

    try {
      File fileToOcr = widget.imageFile;

      if (crop) {
        setState(() {
          _statusMessage = 'Cropping image...';
        });

        final bytes = await widget.imageFile.readAsBytes();
        final decoded = img.decodeImage(bytes);

        if (decoded != null) {
          final x = (_cropRectFraction.left * decoded.width).round().clamp(0, decoded.width - 1);
          final y = (_cropRectFraction.top * decoded.height).round().clamp(0, decoded.height - 1);
          final w = (_cropRectFraction.width * decoded.width).round().clamp(10, decoded.width - x);
          final h = (_cropRectFraction.height * decoded.height).round().clamp(10, decoded.height - y);

          final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
          final croppedBytes = img.encodeJpg(cropped, quality: 90);

          final savedPath = await _storageService.saveReceiptBytes(croppedBytes);
          fileToOcr = File(savedPath);
        }
      }

      setState(() {
        _statusMessage = 'Running on-device text recognition...';
      });

      final ocrResult = await _ocrService.processReceiptImage(fileToOcr);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewExpenseScreen(
            imageFile: fileToOcr,
            parsedReceipt: ocrResult.parsedReceipt,
            rawOcrText: ocrResult.rawText,
            latencyMs: ocrResult.latencyMs,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OCR Error: ${e is AppException ? e.message : e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _processAndProceed(crop: crop),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop Receipt', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => _processAndProceed(crop: false),
            child: const Text('Skip Crop', style: TextStyle(color: Color(0xFF818CF8))),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Receipt Image with Crop Overlay
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Draggable Crop Box Overlay
                  if (!_isProcessing)
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _CropOverlayPainter(cropRectFraction: _cropRectFraction),
                    ),

                  // Interactive Drag Handles
                  if (!_isProcessing)
                    GestureDetector(
                      onPanUpdate: (details) {
                        final dx = details.delta.dx / constraints.maxWidth;
                        final dy = details.delta.dy / constraints.maxHeight;

                        setState(() {
                          final newLeft = (_cropRectFraction.left + dx).clamp(0.0, 0.6);
                          final newTop = (_cropRectFraction.top + dy).clamp(0.0, 0.6);
                          final newRight = (_cropRectFraction.right + dx).clamp(newLeft + 0.2, 1.0);
                          final newBottom = (_cropRectFraction.bottom + dy).clamp(newTop + 0.2, 1.0);

                          _cropRectFraction = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
                        });
                      },
                    ),
                ],
              );
            },
          ),

          // Processing Loading Indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Action Bar
          if (!_isProcessing)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: () => _processAndProceed(crop: false),
                        child: const Text('Use Full Image'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                        ),
                        onPressed: () => _processAndProceed(crop: true),
                        icon: const Icon(Icons.crop_rounded, size: 18),
                        label: const Text('Crop & Parse'),
                      ),
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

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRectFraction;

  _CropOverlayPainter({required this.cropRectFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final cropRect = Rect.fromLTRB(
      cropRectFraction.left * size.width,
      cropRectFraction.top * size.height,
      cropRectFraction.right * size.width,
      cropRectFraction.bottom * size.height,
    );

    // Dark semi-transparent mask outside crop area
    final maskPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, maskPaint);

    // Crop border
    final borderPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(cropRect, borderPaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top-left
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRectFraction != cropRectFraction;
  }
}
