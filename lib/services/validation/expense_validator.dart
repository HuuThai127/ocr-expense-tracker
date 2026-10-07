import '../../core/errors/app_exception.dart';
import '../../data/models/category_enum.dart';
import '../../data/models/expense_model.dart';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? field;

  const ValidationResult.success()
      : isValid = true,
        errorMessage = null,
        field = null;

  const ValidationResult.failure(this.errorMessage, {this.field})
      : isValid = false;
}

class ExpenseValidator {
  static ValidationResult validate({
    required String merchantName,
    required double? totalAmount,
    required DateTime? transactionDate,
    required ExpenseCategory? category,
  }) {
    if (merchantName.trim().isEmpty) {
      return const ValidationResult.failure(
        'Merchant name cannot be empty',
        field: 'merchantName',
      );
    }

    if (totalAmount == null || totalAmount <= 0) {
      return const ValidationResult.failure(
        'Total amount must be greater than 0',
        field: 'totalAmount',
      );
    }

    if (totalAmount > 1000000000) {
      return const ValidationResult.failure(
        'Total amount is unrealistically high',
        field: 'totalAmount',
      );
    }

    if (transactionDate == null) {
      return const ValidationResult.failure(
        'Transaction date is required',
        field: 'transactionDate',
      );
    }

    final now = DateTime.now();
    // Allow small forward tolerance (e.g. 1 day for timezone differences)
    final maxFutureDate = now.add(const Duration(days: 1));
    if (transactionDate.isAfter(maxFutureDate)) {
      return const ValidationResult.failure(
        'Transaction date cannot be in the future',
        field: 'transactionDate',
      );
    }

    if (transactionDate.year < 2000) {
      return const ValidationResult.failure(
        'Transaction date is too old',
        field: 'transactionDate',
      );
    }

    if (category == null) {
      return const ValidationResult.failure(
        'Category is required',
        field: 'category',
      );
    }

    return const ValidationResult.success();
  }

  /// Validates an ExpenseModel instance and throws ValidationException if invalid
  static void assertValid(ExpenseModel expense) {
    final result = validate(
      merchantName: expense.merchantName,
      totalAmount: expense.totalAmount,
      transactionDate: expense.transactionDate,
      category: expense.category,
    );

    if (!result.isValid) {
      throw ValidationException(
        result.errorMessage ?? 'Expense data is invalid',
        code: result.field,
      );
    }
  }
}
