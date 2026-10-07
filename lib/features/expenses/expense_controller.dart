import 'package:flutter/foundation.dart';
import '../../data/database/expense_dao.dart';
import '../../data/models/category_enum.dart';
import '../../data/models/expense_model.dart';
import '../../services/storage/receipt_storage_service.dart';
import '../../services/validation/expense_validator.dart';

class ExpenseController extends ChangeNotifier {
  final ExpenseDao _dao;
  final ReceiptStorageService _storageService;

  List<ExpenseModel> _expenses = [];
  double _totalSpending = 0.0;
  Map<ExpenseCategory, double> _categoryAggregates = {
    for (final cat in ExpenseCategory.values) cat: 0.0,
  };
  Map<int, double> _weeklyAggregates = {
    for (int i = 1; i <= 7; i++) i: 0.0,
  };

  bool _isLoading = false;
  String? _errorMessage;

  ExpenseController({
    ExpenseDao? dao,
    ReceiptStorageService? storageService,
  })  : _dao = dao ?? ExpenseDao(),
        _storageService = storageService ?? ReceiptStorageService();

  List<ExpenseModel> get expenses => _expenses;
  double get totalSpending => _totalSpending;
  Map<ExpenseCategory, double> get categoryAggregates => _categoryAggregates;
  Map<int, double> get weeklyAggregates => _weeklyAggregates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _dao.getAllExpenses();
      _totalSpending = await _dao.getTotalSpending();
      _categoryAggregates = await _dao.getCategoryAggregates();
      _weeklyAggregates = await _dao.getWeeklyAggregates();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load expenses: $e';
      notifyListeners();
    }
  }

  Future<bool> addExpense(ExpenseModel expense) async {
    try {
      ExpenseValidator.assertValid(expense);
      await _dao.insertExpense(expense);
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id, {String? imagePath}) async {
    try {
      await _dao.deleteExpense(id);
      if (imagePath != null) {
        await _storageService.deleteReceiptImage(imagePath);
      }
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    try {
      ExpenseValidator.assertValid(expense);
      await _dao.updateExpense(expense);
      await loadExpenses();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update expense: $e';
      notifyListeners();
      return false;
    }
  }

  /// Seeds realistic mock expenses on first launch if database is empty
  Future<void> seedSampleDataIfEmpty() async {
    try {
      final existing = await _dao.getAllExpenses();
      if (existing.isEmpty) {
        final now = DateTime.now();
        final sampleItems = [
          ExpenseModel(
            merchantName: 'CO.OPMART CONG HOA',
            totalAmount: 185000,
            transactionDate: now.subtract(const Duration(days: 1)),
            category: ExpenseCategory.food,
            createdAt: now.subtract(const Duration(days: 1)),
            rawOcrText: 'CO.OPMART CONG HOA\nNgay: 07/10/2026\nTONG CONG: 185.000 VND',
          ),
          ExpenseModel(
            merchantName: 'FAHASA BOOKSTORE',
            totalAmount: 245000,
            transactionDate: now.subtract(const Duration(days: 2)),
            category: ExpenseCategory.study,
            createdAt: now.subtract(const Duration(days: 2)),
            rawOcrText: 'FAHASA BOOKSTORE\nNgay: 06/10/2026\nTHANH TIEN: 245.000 VND',
          ),
          ExpenseModel(
            merchantName: 'GRAB VIETNAM',
            totalAmount: 68000,
            transactionDate: now.subtract(const Duration(days: 3)),
            category: ExpenseCategory.travel,
            createdAt: now.subtract(const Duration(days: 3)),
            rawOcrText: 'GRAB VIETNAM\nDate: 05/10/2026\nTOTAL: 68,000 VND',
          ),
          ExpenseModel(
            merchantName: 'PHONG VU COMPUTER',
            totalAmount: 520000,
            transactionDate: now.subtract(const Duration(days: 4)),
            category: ExpenseCategory.gear,
            createdAt: now.subtract(const Duration(days: 4)),
            rawOcrText: 'PHONG VU COMPUTER\nNgay: 04/10/2026\nTONG TIEN: 520.000 VND',
          ),
          ExpenseModel(
            merchantName: 'CGV CINEMAS',
            totalAmount: 210000,
            transactionDate: now.subtract(const Duration(days: 5)),
            category: ExpenseCategory.entertainment,
            createdAt: now.subtract(const Duration(days: 5)),
            rawOcrText: 'CGV CINEMAS\nNgay: 03/10/2026\nTONG CONG: 210.000 VND',
          ),
        ];

        for (final item in sampleItems) {
          await _dao.insertExpense(item);
        }
        await loadExpenses();
      }
    } catch (e) {
      debugPrint('Error seeding sample data: $e');
    }
  }
}
