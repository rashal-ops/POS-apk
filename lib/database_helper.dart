import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT UNIQUE,
        name TEXT,
        price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subtotal REAL,
        tax_amount REAL,
        card_fee_amount REAL,
        total_amount REAL,
        cash_paid REAL,
        card_paid REAL,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE store_settings (
        id INTEGER PRIMARY KEY,
        store_name TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        tax_rate REAL,
        card_fee_type TEXT,
        card_fee_value REAL,
        card_fee_label TEXT
      )
    ''');

    await db.insert('store_settings', {
      'id': 1,
      'store_name': 'My POS Store',
      'address': '123 Main Street',
      'phone': '+1 555-0199',
      'email': 'store@example.com',
      'tax_rate': 8.5,
      'card_fee_type': 'percent',
      'card_fee_value': 2.0,
      'card_fee_label': 'Card Service Fee'
    });
  }
}
