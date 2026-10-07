import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../models/category_enum.dart';
import '../models/expense_model.dart';
import 'app_database.dart';

class ExpenseDao {
  final AppDatabase _appDatabase;

  ExpenseDao({AppDatabase? appDatabase}) : _appDatabase = appDatabase ?? AppDatabase();

  Future<Database> get _db async => await _appDatabase.database;

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await _db;
    return await db.insert(
      AppConstants.tableNameExpenses,
      expense.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableNameExpenses,
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  Future<ExpenseModel?> getExpenseById(int id) async {
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableNameExpenses,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExpenseModel.fromMap(maps.first);
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) return 0;
    final db = await _db;
    return await db.update(
      AppConstants.tableNameExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _db;
    return await db.delete(
      AppConstants.tableNameExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalSpending() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(total_amount) as total FROM ${AppConstants.tableNameExpenses}',
    );
    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<ExpenseCategory, double>> getCategoryAggregates() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT category, SUM(total_amount) as total
      FROM ${AppConstants.tableNameExpenses}
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> aggregates = {
      for (final cat in ExpenseCategory.values) cat: 0.0,
    };

    for (final row in result) {
      final catStr = row['category'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      final category = ExpenseCategory.fromString(catStr);
      aggregates[category] = (aggregates[category] ?? 0.0) + total;
    }

    return aggregates;
  }

  /// Returns spending aggregated by day of week (1 = Monday, ..., 7 = Sunday)
  /// for the 7-day week containing the given reference date (default: now)
  Future<Map<int, double>> getWeeklyAggregates({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    // Monday of current week:
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final db = await _db;
    final result = await db.query(
      AppConstants.tableNameExpenses,
      where: 'transaction_date >= ? AND transaction_date < ?',
      whereArgs: [startOfWeek.toIso8601String(), endOfWeek.toIso8601String()],
    );

    // Initialize Monday (1) through Sunday (7)
    final Map<int, double> weekly = {
      for (int i = 1; i <= 7; i++) i: 0.0,
    };

    for (final row in result) {
      final dateStr = row['transaction_date'] as String;
      final date = DateTime.parse(dateStr);
      final amount = (row['total_amount'] as num).toDouble();
      weekly[date.weekday] = (weekly[date.weekday] ?? 0.0) + amount;
    }

    return weekly;
  }
}
