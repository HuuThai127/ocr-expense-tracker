class AppConstants {
  static const String appName = 'OCR Expense Tracker';
  static const String appSubtitle = 'Smart On-Device Receipt Scanner';

  // Database
  static const String dbName = 'ocr_expenses.db';
  static const int dbVersion = 1;
  static const String tableNameExpenses = 'expenses';

  // Currency
  static const String defaultCurrency = 'VND';

  // Supported Categories according to rubric
  static const List<String> categories = [
    'Food',
    'Study',
    'Travel',
    'Gear',
    'Entertainment',
  ];

  // Storage
  static const String receiptFolder = 'receipt_images';
}
