import 'dart:async';
import 'package:fatora_pro/models/invoice.dart';
import 'package:fatora_pro/models/payment.dart';
import 'package:fatora_pro/models/product.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  // استخدام نفس اسم قاعدة البيانات من JS
  static const _databaseName = "InvoiceAppDB_Flutter.db";
  // استخدام نفس رقم الإصدار 2
  static const _databaseVersion = 2;

  // أسماء الجداول
  static const tableInvoices = 'invoices';
  static const tableProducts = 'products';
  static const tablePayments = 'payments'; // الجدول الجديد

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // للتعامل مع الترقية من v1 إلى v2
    );
  }

  // إنشاء الجداول
  Future _onCreate(Database db, int version) async {
    // جدول المنتجات (مع name فريد كما في &name في Dexie)
    await db.execute('''
      CREATE TABLE $tableProducts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        price REAL NOT NULL
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE $tableInvoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer TEXT NOT NULL,
        date TEXT NOT NULL,
        items TEXT NOT NULL,
        total REAL NOT NULL,
        previousBalance REAL NOT NULL,
        payment REAL NOT NULL,
        printHistory TEXT
      )
    ''');
    
    // جدول الدفعات (تمت إضافته في v2)
    await db.execute('''
      CREATE TABLE $tablePayments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer TEXT NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');
  }

  // منطق الترقية
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إذا كان المستخدم على نسخة 1، قم بإضافة جدول الدفعات
      await db.execute('''
        CREATE TABLE $tablePayments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer TEXT NOT NULL,
          date TEXT NOT NULL,
          amount REAL NOT NULL
        )
      ''');
    }
  }

  // === دوال المنتجات (Products) ===

  Future<int> insertProduct(Product product) async {
    Database db = await instance.database;
    return await db.insert(tableProducts, product.toMap());
  }

  Future<Product> getProductByName(String name) async {
    Database db = await instance.database;
    final maps = await db.query(tableProducts, where: 'name = ?', whereArgs: [name]);
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    throw Exception('Product not found');
  }

  Future<int> updateProduct(Product product) async {
    Database db = await instance.database;
    return await db.update(tableProducts, product.toMap(), where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    Database db = await instance.database;
    return await db.delete(tableProducts, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAllProducts() async {
    Database db = await instance.database;
    final maps = await db.query(tableProducts, orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }
  
  Future<int> clearAllProducts() async {
    Database db = await instance.database;
    return await db.delete(tableProducts);
  }
  
  Future<void> bulkInsertProducts(List<Product> products) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var product in products) {
      batch.insert(tableProducts, product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // === دوال الفواتير (Invoices) ===

  Future<int> insertInvoice(Invoice invoice) async {
    Database db = await instance.database;
    return await db.insert(tableInvoices, invoice.toMap());
  }

  Future<int> updateInvoice(Invoice invoice) async {
    Database db = await instance.database;
    return await db.update(tableInvoices, invoice.toMap(), where: 'id = ?', whereArgs: [invoice.id]);
  }
  
  Future<Invoice> getInvoice(int id) async {
     Database db = await instance.database;
    final maps = await db.query(tableInvoices, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Invoice.fromMap(maps.first);
    }
    throw Exception('Invoice not found');
  }

  Future<int> deleteInvoice(int id) async {
    Database db = await instance.database;
    return await db.delete(tableInvoices, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Invoice>> getAllInvoices() async {
    Database db = await instance.database;
    // جلب الأحدث أولاً
    final maps = await db.query(tableInvoices, orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Invoice.fromMap(maps[i]));
  }
  
  Future<int> clearAllInvoices() async {
    Database db = await instance.database;
    return await db.delete(tableInvoices);
  }
  
  Future<void> bulkInsertInvoices(List<Invoice> invoices) async {
    Database db = await instance.database;
    Batch batch = db.batch();
    for (var invoice in invoices) {
      batch.insert(tableInvoices, invoice.toMapWithoutId());
    }
    await batch.commit(noResult: true);
  }

  // === دوال الدفعات (Payments) ===

  Future<int> insertPayment(Payment payment) async {
    Database db = await instance.database;
    return await db.insert(tablePayments, payment.toMap());
  }
  
  Future<List<Payment>> getAllPayments() async {
    Database db = await instance.database;
    final maps = await db.query(tablePayments, orderBy: 'date ASC');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }
}
