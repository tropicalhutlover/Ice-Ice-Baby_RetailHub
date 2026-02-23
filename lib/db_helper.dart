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

  static const String adminEmail = 'admin@icecream.com';
  static const String adminPassword = 'admin123';

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'icecream_app.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN isAdmin INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE orders ADD COLUMN status TEXT DEFAULT \'pending\'');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE orders ADD COLUMN orderGroupId INTEGER');
      await db.rawUpdate('UPDATE orders SET orderGroupId = id WHERE orderGroupId IS NULL');
    }
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
        password TEXT,
        isAdmin INTEGER DEFAULT 0
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
        orderGroupId INTEGER,
        itemName TEXT,
        qty INTEGER,
        total REAL,
        status TEXT DEFAULT 'pending'
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
    if (email.toLowerCase() == adminEmail) {
      throw Exception('Cannot register admin account');
    }
    final db = await database;
    final result = await db.insert(
      'users',
      {
        'name': name,
        'email': email,
        'password': hashPassword(password),
        'isAdmin': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return result;
  }


  // Login (admin: admin@icecream.com / admin123)
  Future<Map<String, dynamic>?> login(String email, String password) async {
    if (email.toLowerCase() == adminEmail && password == adminPassword) {
      return {
        'id': -1,
        'name': 'Admin',
        'email': adminEmail,
        'isAdmin': 1,
      };
    }
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashPassword(password)],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    if (id < 0) return null;
    final db = await database;
    final r = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return r.isNotEmpty ? r.first : null;
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
  Future addOrder(int userId, int orderGroupId, String item, int qty, double total) async {
    final db = await database;
    await db.insert('orders', {
      'userId': userId,
      'orderGroupId': orderGroupId,
      'itemName': item,
      'qty': qty,
      'total': total,
      'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> getOrders(int userId) async {
    final db = await database;
    return db.query('orders', where: 'userId=?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return db.query('orders', orderBy: 'id DESC');
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> updateOrderGroupStatus(int orderGroupId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': status},
      where: 'orderGroupId = ?',
      whereArgs: [orderGroupId],
    );
  }

  // edit & delete
  Future<void> updateItem(int id, String name, double price) async {
    final db = await database;
    await db.update(
      'items',
      {'name': name, 'price': price},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}
