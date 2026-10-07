import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/app/theme.dart';
import 'package:ocr_expense_tracker/data/database/expense_dao.dart';
import 'package:ocr_expense_tracker/data/models/category_enum.dart';
import 'package:ocr_expense_tracker/data/models/expense_model.dart';
import 'package:ocr_expense_tracker/features/expenses/expense_controller.dart';
import 'package:ocr_expense_tracker/features/home/home_screen.dart';
import 'package:provider/provider.dart';

class FakeExpenseDao extends ExpenseDao {
  final List<ExpenseModel> items;
  FakeExpenseDao(this.items);

  @override
  Future<List<ExpenseModel>> getAllExpenses() async => items;

  @override
  Future<double> getTotalSpending() async =>
      items.fold<double>(0.0, (double sum, e) => sum + e.totalAmount);

  @override
  Future<Map<ExpenseCategory, double>> getCategoryAggregates() async {
    final map = {for (final c in ExpenseCategory.values) c: 0.0};
    for (final e in items) {
      map[e.category] = (map[e.category] ?? 0.0) + e.totalAmount;
    }
    return map;
  }

  @override
  Future<Map<int, double>> getWeeklyAggregates({DateTime? referenceDate}) async => {
    for (int i = 1; i <= 7; i++) i: 0.0,
  };
}

void main() {
  testWidgets('Dashboard renders spending banner and Scan Receipt button', (WidgetTester tester) async {
    final fakeExpenses = [
      ExpenseModel(
        id: 1,
        merchantName: 'CO.OPMART CONG HOA',
        totalAmount: 185000.0,
        transactionDate: DateTime(2026, 10, 7),
        category: ExpenseCategory.food,
        createdAt: DateTime(2026, 10, 7),
      ),
    ];

    final controller = ExpenseController(dao: FakeExpenseDao(fakeExpenses));
    await controller.loadExpenses();

    await tester.pumpWidget(
      ChangeNotifierProvider<ExpenseController>.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('OCR Expense Tracker'), findsOneWidget);
    expect(find.text('Scan Receipt'), findsOneWidget);
    expect(find.text('Category Summary'), findsOneWidget);
    expect(find.text('CO.OPMART CONG HOA'), findsOneWidget);
  });
}
