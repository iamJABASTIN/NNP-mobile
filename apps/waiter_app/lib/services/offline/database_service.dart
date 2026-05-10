import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/menu_item.dart';
import '../../models/table_info.dart';

class DatabaseService {
  static Database? _database;
  static const int _dbVersion = 2; // Bump version to force schema update

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nnp_waiter_v2.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Table for cached menu items
        await db.execute('''
          CREATE TABLE menu_items(
            id TEXT PRIMARY KEY,
            name TEXT,
            price REAL,
            category_name TEXT,
            is_available INTEGER,
            veg_type TEXT
          )
        ''');

        // Table for cached tables
        await db.execute('''
          CREATE TABLE tables(
            id TEXT PRIMARY KEY,
            table_number TEXT,
            status TEXT
          )
        ''');

        // Table for pending orders (sync queue)
        await db.execute('''
          CREATE TABLE pending_orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_id TEXT,
            order_type TEXT,
            customer_name TEXT,
            customer_phone TEXT,
            cart_json TEXT,
            total_amount REAL,
            created_at TEXT,
            sync_status TEXT DEFAULT 'pending',
            error_message TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Recreate pending_orders if version is old
          await db.execute('DROP TABLE IF EXISTS pending_orders');
          await db.execute('''
            CREATE TABLE pending_orders(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              table_id TEXT,
              order_type TEXT,
              customer_name TEXT,
              customer_phone TEXT,
              cart_json TEXT,
              total_amount REAL,
              created_at TEXT,
              sync_status TEXT DEFAULT 'pending',
              error_message TEXT
            )
          ''');
        }
      },
    );
  }

  // --- Menu Operations ---

  static Future<void> saveMenuItems(List<MenuItem> items) async {
    final db = await database;
    final batch = db.batch();
    
    // Clear existing to ensure freshness
    batch.delete('menu_items');
    
    for (var item in items) {
      batch.insert('menu_items', {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'category_name': item.categoryName,
        'is_available': item.isAvailable ? 1 : 0,
        'veg_type': item.vegType,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<MenuItem>> getMenuItems() async {
    final db = await database;
    final maps = await db.query('menu_items');
    
    return List.generate(maps.length, (i) {
      return MenuItem(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        price: maps[i]['price'] as double,
        categoryName: maps[i]['category_name'] as String?,
        isAvailable: maps[i]['is_available'] == 1,
        vegType: maps[i]['veg_type'] as String,
      );
    });
  }

  // --- Table Operations ---

  static Future<void> saveTables(List<TableInfo> tables) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('tables');
    for (var t in tables) {
      batch.insert('tables', {
        'id': t.id,
        'table_number': t.tableNumber,
        'status': t.status,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<TableInfo>> getTables() async {
    final db = await database;
    final maps = await db.query('tables');
    return maps.map((m) => TableInfo.fromJson(m)).toList();
  }

  // --- Pending Order Operations ---

  static Future<int> queueOrder({
    required String? tableId,
    required String orderType,
    required String? customerName,
    required String? customerPhone,
    required String cartJson,
    required double totalAmount,
  }) async {
    try {
      final db = await database;
      final data = {
        'table_id': tableId,
        'order_type': orderType,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'cart_json': cartJson,
        'total_amount': totalAmount,
        'created_at': DateTime.now().toIso8601String(),
        'sync_status': 'pending',
      };
      
      print('DB: Attempting to queue order: $data');
      final id = await db.insert('pending_orders', data);
      print('DB: Order queued successfully with ID: $id');
      return id;
    } catch (e, stack) {
      print('DB ERROR: Failed to queue order: $e');
      print('DB STACK: $stack');
      rethrow; // Pass it up to the UI
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await database;
    return await db.query('pending_orders', where: "sync_status = 'pending'");
  }

  static Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'pending_orders',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> markAsFailed(int id, String error) async {
    final db = await database;
    await db.update(
      'pending_orders',
      {'sync_status': 'failed', 'error_message': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
