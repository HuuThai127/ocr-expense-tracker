import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/parsed_receipt.dart';
import '../parser/receipt_parser.dart';

class OcrResult {
  final String rawText;
  final int latencyMs;
  final ParsedReceipt parsedReceipt;

  const OcrResult({
    required this.rawText,
    required this.latencyMs,
    required this.parsedReceipt,
  });
}

class ReceiptOcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Processes an image file using on-device ML Kit Text Recognition,
  /// measures real latency, and returns parsed receipt data.
  Future<OcrResult> processReceiptImage(File imageFile) async {
    final stopwatch = Stopwatch()..start();

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
      stopwatch.stop();

      final latencyMs = stopwatch.elapsedMilliseconds;
      final rawText = recognizedText.text;

      final parsed = ReceiptParser.parse(rawText, processingDurationMs: latencyMs);

      debugPrint('ML Kit OCR finished in ${latencyMs}ms. Detected: ${parsed.status.label}');

      return OcrResult(
        rawText: rawText,
        latencyMs: latencyMs,
        parsedReceipt: parsed,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('ML Kit OCR failed: $e');
      throw OcrException('Failed to recognize text on device: $e');
    }
  }

  /// Parses pre-recognized text directly with latency tracking
  OcrResult parseRawText(String rawText, {int latencyMs = 0}) {
    final parsed = ReceiptParser.parse(rawText, processingDurationMs: latencyMs);
    return OcrResult(
      rawText: rawText,
      latencyMs: latencyMs,
      parsedReceipt: parsed,
    );
  }

  /// Cleanly closes the ML Kit native recognizer
  Future<void> dispose() async {
    if (_textRecognizer != null) {
      await _textRecognizer!.close();
      _textRecognizer = null;
    }
  }
}
