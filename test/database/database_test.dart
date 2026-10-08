import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/constants/app_constants.dart';
import 'package:ocr_expense_tracker/data/database/app_database.dart';
import 'package:ocr_expense_tracker/data/database/expense_dao.dart';
import 'package:ocr_expense_tracker/data/database/web_database.dart';
import 'package:ocr_expense_tracker/data/models/category_enum.dart';
import 'package:ocr_expense_tracker/data/models/expense_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late ExpenseDao dao;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNameExpenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant_name TEXT NOT NULL,
        total_amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'VND',
        transaction_date TEXT NOT NULL,
        category TEXT NOT NULL,
        receipt_image_path TEXT,
        created_at TEXT NOT NULL,
        raw_ocr_text TEXT
      )
    ''');

    final appDb = AppDatabase();
    appDb.setDatabaseForTesting(db);
    dao = ExpenseDao(appDatabase: appDb);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseDao SQLite CRUD and Aggregations', () {
    test('inserts and retrieves expenses from database', () async {
      final expense = ExpenseModel(
        merchantName: 'CO.OPMART',
        totalAmount: 185000.0,
        transactionDate: DateTime(2026, 10, 5),
        category: ExpenseCategory.food,
        createdAt: DateTime(2026, 10, 5),
        rawOcrText: 'COOPMART\nTOTAL 185,000 VND',
      );

      final id = await dao.insertExpense(expense);
      expect(id, isPositive);

      final all = await dao.getAllExpenses();
      expect(all.length, equals(1));
      expect(all.first.merchantName, equals('CO.OPMART'));
      expect(all.first.totalAmount, equals(185000.0));
      expect(all.first.category, equals(ExpenseCategory.food));
    });

    test('updates expense correctly', () async {
      final expense = ExpenseModel(
        merchantName: 'STORE A',
        totalAmount: 100000.0,
        transactionDate: DateTime(2026, 10, 1),
        category: ExpenseCategory.study,
        createdAt: DateTime.now(),
      );

      final id = await dao.insertExpense(expense);
      final inserted = await dao.getExpenseById(id);
      expect(inserted, isNotNull);

      final updated = inserted!.copyWith(
        merchantName: 'STORE A UPDATED',
        totalAmount: 120000.0,
      );
      final rows = await dao.updateExpense(updated);
      expect(rows, equals(1));

      final fetched = await dao.getExpenseById(id);
      expect(fetched!.merchantName, equals('STORE A UPDATED'));
      expect(fetched.totalAmount, equals(120000.0));
    });

    test('deletes expense correctly', () async {
      final expense = ExpenseModel(
        merchantName: 'STORE B',
        totalAmount: 50000.0,
        transactionDate: DateTime(2026, 10, 1),
        category: ExpenseCategory.travel,
        createdAt: DateTime.now(),
      );

      final id = await dao.insertExpense(expense);
      expect((await dao.getAllExpenses()).length, equals(1));

      await dao.deleteExpense(id);
      expect((await dao.getAllExpenses()).isEmpty, isTrue);
    });

    test('calculates total spending and category aggregates', () async {
      await dao.insertExpense(ExpenseModel(
        merchantName: 'Food Shop',
        totalAmount: 100000.0,
        transactionDate: DateTime(2026, 10, 1),
        category: ExpenseCategory.food,
        createdAt: DateTime.now(),
      ));
      await dao.insertExpense(ExpenseModel(
        merchantName: 'Bookstore',
        totalAmount: 150000.0,
        transactionDate: DateTime(2026, 10, 2),
        category: ExpenseCategory.study,
        createdAt: DateTime.now(),
      ));

      final total = await dao.getTotalSpending();
      expect(total, equals(250000.0));

      final categories = await dao.getCategoryAggregates();
      expect(categories[ExpenseCategory.food], equals(100000.0));
      expect(categories[ExpenseCategory.study], equals(150000.0));
      expect(categories[ExpenseCategory.travel], equals(0.0));
    });

    test('initWebDatabase executes safely across platform environments', () {
      expect(() => initWebDatabase(), returnsNormally);
    });
  });
}
