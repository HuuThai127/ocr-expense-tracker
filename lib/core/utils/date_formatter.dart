import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _ddmmyyyy = DateFormat('dd/MM/yyyy');
  static final DateFormat _readable = DateFormat('MMM dd, yyyy');
  static final DateFormat _full = DateFormat('EEEE, dd/MM/yyyy');

  static String toDdMmYyyy(DateTime date) {
    return _ddmmyyyy.format(date);
  }

  static String toReadable(DateTime date) {
    return _readable.format(date);
  }

  static String toFull(DateTime date) {
    return _full.format(date);
  }

  /// Parses string in formats DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD/MM/YY
  /// Returns null if format is invalid or values are out of calendar range
  static DateTime? tryParseDate(String input) {
    final cleaned = input.trim();
    final parts = cleaned.split(RegExp(r'[/.\-]'));
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    // Handle 2-digit year (e.g. 26 -> 2026)
    if (year < 100) {
      year += 2000;
    }

    if (year < 2000 || year > 2100) return null;
    if (month < 1 || month > 12) return null;

    final daysInMonth = _daysInMonth(year, month);
    if (day < 1 || day > daysInMonth) return null;

    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }
}
