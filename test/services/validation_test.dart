import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/errors/app_exception.dart';
import 'package:ocr_expense_tracker/data/models/category_enum.dart';
import 'package:ocr_expense_tracker/data/models/expense_model.dart';
import 'package:ocr_expense_tracker/services/validation/expense_validator.dart';

void main() {
  group('ExpenseValidator Unit Tests', () {
    test('accepts valid expense attributes', () {
      final result = ExpenseValidator.validate(
        merchantName: 'CO.OPMART',
        totalAmount: 150000.0,
        transactionDate: DateTime(2026, 10, 1),
        category: ExpenseCategory.food,
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('rejects empty merchant name', () {
      final result = ExpenseValidator.validate(
        merchantName: '   ',
        totalAmount: 150000.0,
        transactionDate: DateTime(2026, 10, 1),
        category: ExpenseCategory.food,
      );
      expect(result.isValid, isFalse);
      expect(result.field, equals('merchantName'));
    });

    test('rejects amount <= 0', () {
      final resultZero = ExpenseValidator.validate(
        merchantName: 'Store',
        totalAmount: 0.0,
        transactionDate: DateTime(2026, 10, 1),
        category: ExpenseCategory.food,
      );
      expect(resultZero.isValid, isFalse);
      expect(resultZero.field, equals('totalAmount'));

      final resultNeg = ExpenseValidator.validate(
        merchantName: 'Store',
        totalAmount: -50000.0,
        transactionDate: DateTime(2026, 10, 1),
        category: ExpenseCategory.food,
      );
      expect(resultNeg.isValid, isFalse);
      expect(resultNeg.field, equals('totalAmount'));
    });

    test('rejects future transaction date beyond tolerance', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final result = ExpenseValidator.validate(
        merchantName: 'Store',
        totalAmount: 100000.0,
        transactionDate: futureDate,
        category: ExpenseCategory.food,
      );
      expect(result.isValid, isFalse);
      expect(result.field, equals('transactionDate'));
    });

    test('assertValid throws ValidationException on invalid expense', () {
      final invalidExpense = ExpenseModel(
        merchantName: '',
        totalAmount: -10,
        transactionDate: DateTime(2026, 1, 1),
        category: ExpenseCategory.food,
        createdAt: DateTime.now(),
      );

      expect(
        () => ExpenseValidator.assertValid(invalidExpense),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
