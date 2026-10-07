import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat('#,###', 'vi_VN');

  /// Formats amount into readable Vietnamese currency format: "150,000 ₫" or "150,000 VND"
  static String formatVnd(double amount, {bool showSymbol = true}) {
    final formatted = _vndFormat.format(amount.round());
    return showSymbol ? '$formatted ₫' : formatted;
  }

  /// Formats with explicit currency string
  static String format(double amount, {String currency = 'VND'}) {
    final formatted = _vndFormat.format(amount.round());
    return '$formatted $currency';
  }

  /// Compact representation for charts or small widgets: e.g. "1.5M" or "250K"
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}
