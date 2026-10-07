import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class ReceiptStorageService {
  Future<Directory> _getStorageDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDir.path, AppConstants.receiptFolder));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      return targetDir;
    } catch (e) {
      throw StorageException('Failed to access receipt storage directory: $e');
    }
  }

  /// Copies an image file into the managed app directory and returns its persisted path
  Future<String> saveReceiptImage(File sourceFile) async {
    try {
      final storageDir = await _getStorageDirectory();
      final ext = p.extension(sourceFile.path).isNotEmpty
          ? p.extension(sourceFile.path)
          : '.jpg';
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destinationPath = p.join(storageDir.path, fileName);

      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      throw StorageException('Failed to save receipt image: $e');
    }
  }

  /// Saves raw image bytes directly (e.g. from cropping) and returns the persisted path
  Future<String> saveReceiptBytes(List<int> bytes, {String extension = '.jpg'}) async {
    try {
      final storageDir = await _getStorageDirectory();
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}$extension';
      final destinationPath = p.join(storageDir.path, fileName);

      final file = File(destinationPath);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      throw StorageException('Failed to save receipt bytes: $e');
    }
  }

  /// Deletes a receipt image file if it exists
  Future<bool> deleteReceiptImage(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // Non-fatal, just log / return false
      return false;
    }
  }
}
