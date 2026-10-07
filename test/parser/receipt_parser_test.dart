import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/utils/date_formatter.dart';
import 'package:ocr_expense_tracker/data/models/parsed_receipt.dart';
import 'package:ocr_expense_tracker/services/parser/receipt_parser.dart';

void main() {
  group('ReceiptParser - Money Parsing Heuristics', () {
    test('parses comma-separated VND format: 150,000 VND', () {
      final text = 'SUPERMARKET ABC\nTOTAL: 150,000 VND';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.totalAmount, equals(150000.0));
    });

    test('parses dot-separated Vietnamese format: 150.000 đ', () {
      final text = 'HIGHLANDS COFFEE\nTONG CONG: 150.000 đ';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.totalAmount, equals(150000.0));
    });

    test('parses million format with multiple dots: 1.250.000 VND', () {
      final text = 'PHONG VU COMPUTER\nTHANH TIEN: 1.250.000 VND';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.totalAmount, equals(1250000.0));
    });

    test('parses plain numeric without separators: 150000', () {
      final text = 'STORE XYZ\nTOTAL 150000';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.totalAmount, equals(150000.0));
    });

    test('rejects phone numbers and tax codes as monetary totals', () {
      const text = '''
COOPMART
Tel: 0908123456
MST: 0312456789
Date: 15/09/2026
Water 15,000
TONG TIEN: 45,000 VND
''';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.totalAmount, equals(45000.0));
      expect(receipt.totalAmount, isNot(equals(908123456.0)));
    });

    test('handles malformed numbers and non-numeric garbage gracefully', () {
      final parsed = ReceiptParser.parseMonetaryString('abc#%');
      expect(parsed, isNull);
    });
  });

  group('ReceiptParser - Date Parsing Heuristics', () {
    test('parses valid DD/MM/YYYY format', () {
      final text = 'STORE A\nNgay: 15/09/2026\nTOTAL 50,000';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.transactionDate, isNotNull);
      expect(receipt.transactionDate!.day, equals(15));
      expect(receipt.transactionDate!.month, equals(9));
      expect(receipt.transactionDate!.year, equals(2026));
    });

    test('parses valid DD-MM-YYYY format', () {
      final text = 'STORE B\nDate: 04-10-2026\nTOTAL 80,000';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.transactionDate, isNotNull);
      expect(receipt.transactionDate!.day, equals(4));
      expect(receipt.transactionDate!.month, equals(10));
      expect(receipt.transactionDate!.year, equals(2026));
    });

    test('parses valid DD.MM.YYYY format', () {
      final text = 'STORE C\nNgay: 28.02.2024\nTOTAL 90,000';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.transactionDate, isNotNull);
      expect(receipt.transactionDate!.day, equals(28));
      expect(receipt.transactionDate!.month, equals(2));
      expect(receipt.transactionDate!.year, equals(2024));
    });

    test('strictly rejects invalid dates such as 32/15/2025', () {
      final invalidDate = DateFormatter.tryParseDate('32/15/2025');
      expect(invalidDate, isNull);
    });

    test('strictly rejects invalid leap day on non-leap year (29/02/2025)', () {
      final nonLeapDay = DateFormatter.tryParseDate('29/02/2025');
      expect(nonLeapDay, isNull);
    });
  });

  group('ReceiptParser - Merchant Extraction Heuristics', () {
    test('extracts merchant from top lines of receipt', () {
      const text = '''
WINMART CONG HOA
Dia chi: 123 Cong Hoa, Tan Binh
Ngay: 05/10/2026
TOTAL: 215,000 VND
''';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.merchantName, equals('WINMART CONG HOA'));
    });

    test('discards address, phone, and metadata lines', () {
      const text = '''
Dia chi: 10 Le Loi, Q1
Hotline: 19001234
HIGHLANDS COFFEE
Ngay: 01/10/2026
THANH TIEN: 65,000
''';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.merchantName, equals('HIGHLANDS COFFEE'));
    });

    test('ignores numeric-heavy lines when selecting merchant', () {
      const text = '''
1234567890
*** 987654321 ***
FAHASA NGUYEN HUE
40 Nguyen Hue, Q.1
TONG CONG: 120,000 VND
''';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.merchantName, equals('FAHASA NGUYEN HUE'));
    });
  });

  group('ReceiptParser - Full Receipt Scenarios & Confidence', () {
    test('returns DetectionStatus.detected when all fields are recognized', () {
      const text = '''
LOTTE MART TAN BINH
Ngay: 12/08/2026
Banh snack 15,000
Nuoc ngot 20,000
TONG CONG: 35,000 VND
''';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.status, equals(DetectionStatus.detected));
      expect(receipt.isAmountFound, isTrue);
      expect(receipt.isMerchantFound, isTrue);
      expect(receipt.isDateFound, isTrue);
      expect(receipt.merchantName, equals('LOTTE MART TAN BINH'));
      expect(receipt.totalAmount, equals(35000.0));
      expect(receipt.transactionDate!.day, equals(12));
    });

    test('returns DetectionStatus.partiallyDetected when some fields are missing', () {
      const text = '''
LOTTE MART
Banh snack 15,000
''';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.status, equals(DetectionStatus.partiallyDetected));
      expect(receipt.isDateFound, isFalse);
    });

    test('returns DetectionStatus.notDetected for empty or gibberish input', () {
      const text = '   \n\n   ';
      final receipt = ReceiptParser.parse(text);
      expect(receipt.status, equals(DetectionStatus.notDetected));
      expect(receipt.isAmountFound, isFalse);
      expect(receipt.isMerchantFound, isFalse);
      expect(receipt.isDateFound, isFalse);
    });
  });
}
