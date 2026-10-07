import '../../core/utils/date_formatter.dart';
import '../../data/models/parsed_receipt.dart';

class ReceiptParser {
  /// Keywords indicating the grand total line in Vietnamese / English receipts
  static final List<String> _totalKeywords = [
    'grand total',
    'total amount',
    'total',
    'tong cong',
    'tong tien',
    'thanh tien',
    'thanh toan',
    'tien thanh toan',
    'cong tien hang',
    'tam tinh',
    'so tien',
    'amount due',
    'balance due',
  ];

  /// Keywords that identify non-merchant metadata lines (address, tax, cashier, etc.)
  static final List<String> _ignoreMerchantKeywords = [
    'dia chi',
    'address',
    'tel',
    'dt:',
    'd/t',
    'hotline',
    'phone',
    'mst',
    'ma so thue',
    'tax',
    'website',
    'web:',
    'http',
    'www',
    'wifi',
    'hoa don',
    'receipt',
    'invoice',
    'phieu thanh toan',
    'thu ngan',
    'cashier',
    'ngay',
    'date',
    'time',
    'gio',
    'ban:',
    'table',
    'so:',
    'stt',
    'don gia',
    'sl',
    'qty',
    'price',
    'total',
    'tong',
    'thanh tien',
    'cam on',
    'thank you',
    'hen gap lai',
  ];

  /// Parses raw OCR text into structured receipt data
  static ParsedReceipt parse(String rawText, {int processingDurationMs = 0}) {
    if (rawText.trim().isEmpty) {
      return ParsedReceipt(
        rawText: rawText,
        processingDurationMs: processingDurationMs,
      );
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final totalAmount = extractTotal(lines);
    final transactionDate = extractDate(lines);
    final merchantName = extractMerchant(lines);

    return ParsedReceipt(
      merchantName: merchantName,
      totalAmount: totalAmount,
      transactionDate: transactionDate,
      rawText: rawText,
      isAmountFound: totalAmount != null,
      isMerchantFound: merchantName != null && merchantName.isNotEmpty,
      isDateFound: transactionDate != null,
      processingDurationMs: processingDurationMs,
    );
  }

  // ==========================================
  // 1. TOTAL AMOUNT EXTRACTION
  // ==========================================

  static double? extractTotal(List<String> lines) {
    // Priority 1: Check lines explicitly labeled with Total keywords
    for (final line in lines.reversed) {
      final normalized = _normalizeText(line);
      for (final keyword in _totalKeywords) {
        if (normalized.contains(keyword)) {
          final amount = _extractMonetaryValueFromLine(line, keyword);
          if (amount != null && amount > 0) {
            return amount;
          }
        }
      }
    }

    // Priority 2: Look for lines with currency indicators (VND, VNĐ, đ, ₫)
    final candidateAmountsWithCurrency = <double>[];
    for (final line in lines) {
      if (RegExp(r'(?:vnd|vnđ|₫|\bđ\b|\bd\b)', caseSensitive: false).hasMatch(line)) {
        // Exclude lines mentioning unit price "don gia" if possible
        if (_normalizeText(line).contains('don gia')) continue;
        final amounts = _extractAllNumbersFromLine(line);
        candidateAmountsWithCurrency.addAll(amounts);
      }
    }
    if (candidateAmountsWithCurrency.isNotEmpty) {
      candidateAmountsWithCurrency.sort();
      return candidateAmountsWithCurrency.last;
    }

    // Priority 3: Fallback - Scan all lines for plausible monetary amounts
    // (excluding phone numbers, dates, tax numbers) and pick the maximum plausible
    final allPlausibleAmounts = <double>[];
    for (final line in lines) {
      if (_isLikelyPhoneOrTaxLine(line)) continue;
      final amounts = _extractAllNumbersFromLine(line);
      allPlausibleAmounts.addAll(amounts);
    }

    if (allPlausibleAmounts.isNotEmpty) {
      allPlausibleAmounts.sort();
      // Filter out values <= 0 or unreasonably large (> 1 billion)
      final filtered = allPlausibleAmounts
          .where((amt) => amt >= 1000 && amt <= 1000000000)
          .toList();
      if (filtered.isNotEmpty) {
        return filtered.last;
      }
    }

    return null;
  }

  /// Extracts a monetary value from a specific line that contains a keyword
  static double? _extractMonetaryValueFromLine(String line, String keyword) {
    // Try numbers that appear after the keyword first
    final lower = _normalizeText(line);
    final idx = lower.indexOf(keyword);
    String targetPart = line;
    if (idx != -1) {
      targetPart = line.substring(idx + keyword.length);
    }

    final numbersAfter = _extractAllNumbersFromLine(targetPart);
    if (numbersAfter.isNotEmpty) {
      return numbersAfter.last;
    }

    // Otherwise check any number in the entire line
    final allNumbers = _extractAllNumbersFromLine(line);
    if (allNumbers.isNotEmpty) {
      return allNumbers.last;
    }
    return null;
  }

  /// Extracts all plausible monetary values from a text string
  static List<double> _extractAllNumbersFromLine(String text) {
    final List<double> values = [];

    // Regex matches common price patterns:
    // e.g. 150,000, 150.000, 1,250,000, 1.250.000, 150000
    // avoids matching dates (DD/MM/YYYY)
    final matches = RegExp(r'(?<![\d/.])(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|\d{4,9})(?![\d/.])')
        .allMatches(text);

    for (final match in matches) {
      final raw = match.group(1);
      if (raw != null) {
        final parsed = parseMonetaryString(raw);
        if (parsed != null && parsed > 0) {
          values.add(parsed);
        }
      }
    }

    return values;
  }

  /// Parses monetary string such as "150,000", "150.000", "1.250.000", "150000"
  static double? parseMonetaryString(String raw) {
    var cleaned = raw.trim();

    // Check if it has both dot and comma
    if (cleaned.contains('.') && cleaned.contains(',')) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      if (lastDot > lastComma) {
        // Format: 1,250,000.00 (comma is thousand, dot is decimal)
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // Format: 1.250.000,00 (dot is thousand, comma is decimal)
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (cleaned.contains('.')) {
      // Could be thousand separator "150.000" or decimal "150.50"
      final parts = cleaned.split('.');
      if (parts.length > 2) {
        // 1.250.000 -> thousand separator
        cleaned = cleaned.replaceAll('.', '');
      } else if (parts.length == 2 && parts[1].length == 3) {
        // 150.000 -> thousand separator
        cleaned = cleaned.replaceAll('.', '');
      } else {
        // e.g. 150.50
        // keep as is
      }
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length > 2) {
        // 1,250,000 -> thousand separator
        cleaned = cleaned.replaceAll(',', '');
      } else if (parts.length == 2 && parts[1].length == 3) {
        // 150,000 -> thousand separator
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // 150,50 -> decimal separator in VN
        cleaned = cleaned.replaceAll(',', '.');
      }
    }

    return double.tryParse(cleaned);
  }

  // ==========================================
  // 2. TRANSACTION DATE EXTRACTION
  // ==========================================

  static DateTime? extractDate(List<String> lines) {
    // Regex for DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD/MM/YY
    final dateRegex = RegExp(
      r'\b([0-3]?[0-9])[\/\.\-]([0-1]?[0-9])[\/\.\-]((?:20)?\d{2})\b',
    );

    // Look for lines containing "ngay" or "date" first
    for (final line in lines) {
      final normalized = _normalizeText(line);
      if (normalized.contains('ngay') || normalized.contains('date')) {
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          final dt = DateFormatter.tryParseDate(match.group(0)!);
          if (dt != null) return dt;
        }
      }
    }

    // Otherwise, scan all lines for any valid date match
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        final dt = DateFormatter.tryParseDate(match.group(0)!);
        if (dt != null) return dt;
      }
    }

    return null;
  }

  // ==========================================
  // 3. MERCHANT NAME EXTRACTION
  // ==========================================

  static String? extractMerchant(List<String> lines) {
    // Merchant name is usually in the top 1-5 lines of a receipt
    final maxSearchLines = lines.length < 6 ? lines.length : 6;

    for (int i = 0; i < maxSearchLines; i++) {
      final line = lines[i];
      if (_isValidMerchantCandidate(line)) {
        return _cleanMerchantName(line);
      }
    }

    // Fallback: pick the first line that is not empty and not ignored
    for (final line in lines) {
      if (_isValidMerchantCandidate(line)) {
        return _cleanMerchantName(line);
      }
    }

    return null;
  }

  static bool _isValidMerchantCandidate(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 3) return false;

    final normalized = _normalizeText(trimmed);

    // Exclude if contains any ignore keyword
    for (final keyword in _ignoreMerchantKeywords) {
      if (normalized.contains(keyword)) return false;
    }

    // Exclude if it looks like a phone number or tax code
    if (_isLikelyPhoneOrTaxLine(trimmed)) return false;

    // Exclude if mostly digits or punctuation (> 40% non-letters)
    int letters = 0;
    for (final codeUnit in trimmed.codeUnits) {
      if ((codeUnit >= 65 && codeUnit <= 90) ||
          (codeUnit >= 97 && codeUnit <= 122) ||
          codeUnit > 127) {
        letters++;
      }
    }
    if (letters < 3 || letters / trimmed.length < 0.5) return false;

    return true;
  }

  static String _cleanMerchantName(String text) {
    return text
        .replaceAll(RegExp(r'^[#*=\-_~|:;\.\s]+'), '')
        .replaceAll(RegExp(r'[#*=\-_~|:;\.\s]+$'), '')
        .trim();
  }

  // ==========================================
  // HELPERS
  // ==========================================

  static bool _isLikelyPhoneOrTaxLine(String line) {
    // Phone numbers: 090..., 098..., 028..., 024..., 084...
    if (RegExp(r'(?:tel|dt|d/t|hotline|phone|mst)[\s:]*[\d\s.\-]{8,15}', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    if (RegExp(r'\b0[35789]\d{8}\b').hasMatch(line)) return true;
    if (RegExp(r'\b02\d{9}\b').hasMatch(line)) return true;
    return false;
  }

  static String _normalizeText(String input) {
    var str = input.toLowerCase();
    // Normalize Vietnamese diacritics for easier keyword matching
    const withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }
}
