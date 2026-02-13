import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'icecream_app.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
    );
  }

  Future<bool> userExists(String email) async {
    final db = await database;
    final result =
    await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty;
  }

  // Tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        itemName TEXT,
        qty INTEGER,
        total REAL
      )
    ''');
  }

  // Password
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> updatePassword(String email, String newPassword) async {
    final db = await database;
    final hashedPassword = hashPassword(newPassword);
    return await db.update(
      'users',
      {'password': hashedPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }


  // Register User
  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;

    print("REGISTER ATTEMPT: $email");

    final result = await db.insert(
      'users',
      {
        'name': name,
        'email': email,
        'password': hashPassword(password),
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );

    print("REGISTER SUCCESS: rowId=$result");
    return result;
  }


  // Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashPassword(password)],
    );

    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Item List
  Future insertItem(String name, double price) async {
    final db = await database;
    await db.insert('items', {'name': name, 'price': price});
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return db.query('items');
  }

  // Order List
  Future addOrder(int userId, String item, int qty, double total) async {
    final db = await database;

    await db.insert('orders', {
      'userId': userId,
      'itemName': item,
      'qty': qty,
      'total': total
    });
  }

  Future<List<Map<String, dynamic>>> getOrders(int userId) async {
    final db = await database;

    return db.query('orders', where: 'userId=?', whereArgs: [userId]);
  }
}
