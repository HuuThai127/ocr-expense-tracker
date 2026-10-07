import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/utils/currency_formatter.dart';
import 'package:ocr_expense_tracker/data/models/category_enum.dart';
import 'package:ocr_expense_tracker/data/models/expense_model.dart';
import 'package:ocr_expense_tracker/painters/category_donut_painter.dart';

void main() {
  group('Aggregation and Chart Utilities Tests', () {
    test('computes category percentage distribution for Donut Chart', () {
      final expenses = [
        ExpenseModel(
          merchantName: 'Store 1',
          totalAmount: 200000.0,
          transactionDate: DateTime(2026, 10, 1),
          category: ExpenseCategory.food,
          createdAt: DateTime.now(),
        ),
        ExpenseModel(
          merchantName: 'Store 2',
          totalAmount: 300000.0,
          transactionDate: DateTime(2026, 10, 2),
          category: ExpenseCategory.study,
          createdAt: DateTime.now(),
        ),
        ExpenseModel(
          merchantName: 'Store 3',
          totalAmount: 500000.0,
          transactionDate: DateTime(2026, 10, 3),
          category: ExpenseCategory.gear,
          createdAt: DateTime.now(),
        ),
      ];

      final total = expenses.map((e) => e.totalAmount).reduce((a, b) => a + b);
      expect(total, equals(1000000.0));

      final donutData = [
        CategoryDonutData(
          category: ExpenseCategory.food,
          amount: 200000.0,
          percentage: (200000.0 / total) * 100.0,
        ),
        CategoryDonutData(
          category: ExpenseCategory.study,
          amount: 300000.0,
          percentage: (300000.0 / total) * 100.0,
        ),
        CategoryDonutData(
          category: ExpenseCategory.gear,
          amount: 500000.0,
          percentage: (500000.0 / total) * 100.0,
        ),
      ];

      expect(donutData[0].percentage, equals(20.0));
      expect(donutData[1].percentage, equals(30.0));
      expect(donutData[2].percentage, equals(50.0));
    });

    test('CurrencyFormatter formats standard and compact representations', () {
      expect(CurrencyFormatter.formatVnd(150000), contains('150.000'));
      expect(CurrencyFormatter.formatCompact(1500000), equals('1.5M'));
      expect(CurrencyFormatter.formatCompact(250000), equals('250K'));
      expect(CurrencyFormatter.formatCompact(500), equals('500'));
    });
  });
}
