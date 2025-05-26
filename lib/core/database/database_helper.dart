import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/client.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pedidos_ruta.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de productos
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        imageUrl TEXT,
        category TEXT NOT NULL,
        available INTEGER NOT NULL,
        stock INTEGER NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla de clientes
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        active INTEGER NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla de pedidos
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        clientId TEXT NOT NULL,
        clientName TEXT NOT NULL,
        clientAddress TEXT NOT NULL,
        clientLat REAL NOT NULL,
        clientLng REAL NOT NULL,
        items TEXT NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (clientId) REFERENCES clients (id)
      )
    ''');

    // Tabla de rutas
    await db.execute('''
      CREATE TABLE route_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // CRUD para Productos
  Future<void> insertProducts(List<Product> products) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (Product product in products) {
        await txn.insert('products', {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'available': product.available ? 1 : 0,
          'stock': product.stock,
          'updatedAt': product.updatedAt.toIso8601String(),
        });
      }
    });
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        imageUrl: maps[i]['imageUrl'],
        category: maps[i]['category'],
        available: maps[i]['available'] == 1,
        stock: maps[i]['stock'],
        updatedAt: DateTime.parse(maps[i]['updatedAt']),
      );
    });
  }

  // CRUD para Clientes
  Future<void> insertClients(List<Client> clients) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('clients');
      for (Client client in clients) {
        await txn.insert('clients', {
          'id': client.id,
          'name': client.name,
          'address': client.address,
          'lat': client.lat,
          'lng': client.lng,
          'phone': client.phone,
          'email': client.email,
          'active': client.active ? 1 : 0,
          'updatedAt': client.updatedAt.toIso8601String(),
        });
      }
    });
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(maps.length, (i) {
      return Client(
        id: maps[i]['id'],
        name: maps[i]['name'],
        address: maps[i]['address'],
        lat: maps[i]['lat'],
        lng: maps[i]['lng'],
        phone: maps[i]['phone'],
        email: maps[i]['email'],
        active: maps[i]['active'] == 1,
        updatedAt: DateTime.parse(maps[i]['updatedAt']),
      );
    });
  }

  // CRUD para Pedidos
  Future<void> insertOrder(Order order) async {
    final db = await database;
    await db.insert('orders', {
      'id': order.id,
      'clientId': order.clientId,
      'clientName': order.clientName,
      'clientAddress': order.clientAddress,
      'clientLat': order.clientLat,
      'clientLng': order.clientLng,
      'items': jsonEncode(order.items.map((e) => e.toJson()).toList()),
      'total': order.total,
      'status': order.status.toString().split('.').last,
      'createdAt': order.createdAt.toIso8601String(),
      'completedAt': order.completedAt?.toIso8601String(),
      'synced': order.synced ? 1 : 0,
    });
  }

  Future<List<Order>> getOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) {
      final itemsJson = jsonDecode(maps[i]['items']) as List;
      final items = itemsJson.map((e) => OrderItem.fromJson(e)).toList();

      return Order(
        id: maps[i]['id'],
        clientId: maps[i]['clientId'],
        clientName: maps[i]['clientName'],
        clientAddress: maps[i]['clientAddress'],
        clientLat: maps[i]['clientLat'],
        clientLng: maps[i]['clientLng'],
        items: items,
        total: maps[i]['total'],
        status: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == maps[i]['status'],
        ),
        createdAt: DateTime.parse(maps[i]['createdAt']),
        completedAt: maps[i]['completedAt'] != null
            ? DateTime.parse(maps[i]['completedAt'])
            : null,
        synced: maps[i]['synced'] == 1,
      );
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'status': status.toString().split('.').last,
        'completedAt': status == OrderStatus.completed
            ? DateTime.now().toIso8601String()
            : null,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<Order>> getUnsyncedOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) {
      final itemsJson = jsonDecode(maps[i]['items']) as List;
      final items = itemsJson.map((e) => OrderItem.fromJson(e)).toList();

      return Order(
        id: maps[i]['id'],
        clientId: maps[i]['clientId'],
        clientName: maps[i]['clientName'],
        clientAddress: maps[i]['clientAddress'],
        clientLat: maps[i]['clientLat'],
        clientLng: maps[i]['clientLng'],
        items: items,
        total: maps[i]['total'],
        status: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == maps[i]['status'],
        ),
        createdAt: DateTime.parse(maps[i]['createdAt']),
        completedAt: maps[i]['completedAt'] != null
            ? DateTime.parse(maps[i]['completedAt'])
            : null,
        synced: maps[i]['synced'] == 1,
      );
    });
  }

  Future<void> markOrderAsSynced(String orderId) async {
    final db = await database;
    await db.update(
      'orders',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // CRUD para puntos de ruta
  Future<void> insertRoutePoint(double lat, double lng) async {
    final db = await database;
    await db.insert('route_points', {
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRoutePoints() async {
    final db = await database;
    return await db.query('route_points', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markRoutePointsAsSynced(List<int> ids) async {
    final db = await database;
    await db.transaction((txn) async {
      for (int id in ids) {
        await txn.update(
          'route_points',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('products');
    await db.delete('clients');
    await db.delete('orders');
    // Agrega aquí más tablas si tienes otras
  }
}
