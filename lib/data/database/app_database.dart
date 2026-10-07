import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  /// Optional setter to inject in-memory or mock database during unit testing
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
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

    // Index on transaction_date for fast ordering and date-range queries
    await db.execute('''
      CREATE INDEX idx_expenses_date ON ${AppConstants.tableNameExpenses} (transaction_date DESC)
    ''');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
