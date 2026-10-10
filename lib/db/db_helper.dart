import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

/// Single source of truth for local persistence.
/// All CRUD operations for Users, Buses, Routes, Reports and Trip History.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_bus_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        profileImage TEXT,
        isAdmin INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        destination TEXT NOT NULL,
        stops TEXT NOT NULL,
        distanceKm REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE buses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        busNumber TEXT NOT NULL,
        busName TEXT NOT NULL,
        driverName TEXT NOT NULL,
        busImage TEXT,
        routeId INTEGER,
        lastLat REAL DEFAULT 13.0827,
        lastLng REAL DEFAULT 80.2707,
        FOREIGN KEY (routeId) REFERENCES routes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        photoPath TEXT,
        audioPath TEXT,
        description TEXT NOT NULL,
        issueType TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        reportTime TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE trip_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        busNumber TEXT NOT NULL,
        route TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await _seedDemoData(db);
  }

  Future<void> _seedDemoData(Database db) async {
    // Demo admin account
    await db.insert('users', AppUser(
      name: 'Admin',
      email: 'admin@bus.com',
      phone: '9999999999',
      password: 'admin123',
      isAdmin: true,
    ).toMap()..remove('id'));

    // Demo routes
    final r1 = await db.insert('routes', BusRoute(
      source: 'Tambaram',
      destination: 'Central Station',
      stops: 'Tambaram, Chromepet, Guindy, Saidapet, Central Station',
      distanceKm: 24.5,
    ).toMap()..remove('id'));

    final r2 = await db.insert('routes', BusRoute(
      source: 'Sholinganallur',
      destination: 'T Nagar',
      stops: 'Sholinganallur, OMR Toll, Thoraipakkam, Adyar, T Nagar',
      distanceKm: 18.2,
    ).toMap()..remove('id'));

    // Demo buses
    await db.insert('buses', Bus(
      busNumber: '21G',
      busName: 'Express Line',
      driverName: 'R. Kumar',
      routeId: r1,
      lastLat: 12.9249,
      lastLng: 80.1000,
    ).toMap()..remove('id'));

    await db.insert('buses', Bus(
      busNumber: '5C',
      busName: 'City Connect',
      driverName: 'S. Priya',
      routeId: r2,
      lastLat: 12.9010,
      lastLng: 80.2279,
    ).toMap()..remove('id'));
  }

  // ---------------- USERS ----------------
  Future<int> registerUser(AppUser user) async {
    final db = await database;
    final map = user.toMap()..remove('id');
    return db.insert('users', map);
  }

  Future<AppUser?> login(String email, String password) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    if (res.isEmpty) return null;
    return AppUser.fromMap(res.first);
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty;
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (res.isEmpty) return null;
    return AppUser.fromMap(res.first);
  }

  Future<int> updateUser(AppUser user) async {
    final db = await database;
    return db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;
    return db.update('users', {'password': newPassword}, where: 'id = ?', whereArgs: [userId]);
  }

  // ---------------- ROUTES ----------------
  Future<List<BusRoute>> getRoutes() async {
    final db = await database;
    final res = await db.query('routes', orderBy: 'id DESC');
    return res.map((e) => BusRoute.fromMap(e)).toList();
  }

  Future<int> addRoute(BusRoute route) async {
    final db = await database;
    return db.insert('routes', route.toMap()..remove('id'));
  }

  Future<int> updateRoute(BusRoute route) async {
    final db = await database;
    return db.update('routes', route.toMap(), where: 'id = ?', whereArgs: [route.id]);
  }

  Future<int> deleteRoute(int id) async {
    final db = await database;
    return db.delete('routes', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- BUSES ----------------
  Future<List<Bus>> getBuses() async {
    final db = await database;
    final res = await db.query('buses', orderBy: 'id DESC');
    return res.map((e) => Bus.fromMap(e)).toList();
  }

  Future<int> addBus(Bus bus) async {
    final db = await database;
    return db.insert('buses', bus.toMap()..remove('id'));
  }

  Future<int> updateBus(Bus bus) async {
    final db = await database;
    return db.update('buses', bus.toMap(), where: 'id = ?', whereArgs: [bus.id]);
  }

  Future<int> deleteBus(int id) async {
    final db = await database;
    return db.delete('buses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateBusLocation(int id, double lat, double lng) async {
    final db = await database;
    return db.update('buses', {'lastLat': lat, 'lastLng': lng}, where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- REPORTS ----------------
  Future<int> addReport(Report report) async {
    final db = await database;
    return db.insert('reports', report.toMap()..remove('id'));
  }

  Future<List<Report>> getReports() async {
    final db = await database;
    final res = await db.query('reports', orderBy: 'id DESC');
    return res.map((e) => Report.fromMap(e)).toList();
  }

  Future<List<Report>> getReportsByUser(int userId) async {
    final db = await database;
    final res = await db.query('reports', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
    return res.map((e) => Report.fromMap(e)).toList();
  }

  Future<int> deleteReport(int id) async {
    final db = await database;
    return db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- TRIP HISTORY ----------------
  Future<int> addTrip(TripHistory trip) async {
    final db = await database;
    return db.insert('trip_history', trip.toMap()..remove('id'));
  }

  Future<List<TripHistory>> getTripsByUser(int userId) async {
    final db = await database;
    final res = await db.query('trip_history', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
    return res.map((e) => TripHistory.fromMap(e)).toList();
  }
}
