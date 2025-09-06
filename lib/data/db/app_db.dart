// lib/data/db/app_db.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;

// Use the cross-platform API so we can swap factories at runtime (web/desktop).
import 'package:sqflite_common/sqflite.dart'
    show
        Database,
        databaseFactory,
        databaseFactoryOrNull,
        getDatabasesPath,
        openDatabase;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;

  // Simple SHA-256 helper (used to seed admin password).
  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();

  Future<Database> get database async {
    if (_db != null) return _db!;

    // --- SAFETY NET FOR WEB (Chrome) ---
    // If the global factory wasn't initialized in main.dart (hot restart etc.),
    // wire it here so getDatabasesPath/openDatabase won't throw.
    if (kIsWeb && databaseFactoryOrNull == null) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'skillseed.db');

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int v) async {
    // Users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        age INTEGER,
        college TEXT,
        standard TEXT,
        specialty TEXT,
        about TEXT,
        isApproved INTEGER DEFAULT 0,
        hashed_password TEXT NOT NULL
      );
    ''');

    // Unique email (enforce at DB level)
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS users_email_idx ON users(email);');

    // Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY,
        name TEXT UNIQUE NOT NULL
      );
    ''');

    // Content
    await db.execute('''
      CREATE TABLE IF NOT EXISTS content(
        id TEXT PRIMARY KEY,
        category TEXT,
        title TEXT,
        description TEXT,
        type TEXT,
        urlOrPath TEXT
      );
    ''');

    // Live sessions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS live_sessions(
        id TEXT PRIMARY KEY,
        category TEXT,
        teacherId TEXT,
        title TEXT,
        startAt INTEGER,
        zoomUrl TEXT
      );
    ''');

    // Tests
    await db.execute('''
      CREATE TABLE IF NOT EXISTS test_papers(
        id TEXT PRIMARY KEY,
        category TEXT,
        title TEXT,
        durationMinutes INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS questions(
        id TEXT PRIMARY KEY,
        paperId TEXT,
        text TEXT,
        options TEXT,
        correctIndex INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attempts(
        id TEXT PRIMARY KEY,
        paperId TEXT,
        userId TEXT,
        score INTEGER,
        attemptedAt INTEGER
      );
    ''');

    // Seed the 7 categories
    final cats = <String>[
      'COMMUNICATION',
      'TEAMWORK',
      'CREATIVITY',
      'TIME MANAGEMENT',
      'LEADERSHIP',
      'PROBLEM SOLVING',
      'SELF-REFLECTION',
    ];
    for (var i = 0; i < cats.length; i++) {
      await db.insert('categories', {'id': i + 1, 'name': cats[i]});
    }

    // ---- Seed default ADMIN user ----
    // Credentials:
    //   Email: admin@skillseed.com
    //   Password: admin123
    // Change these anytime; they’re only used on first create.
    await db.insert('users', {
      'id': 'admin-1',
      'role': 'admin',
      'name': 'Super Admin',
      'email': 'admin@skillseed.com',
      'phone': '0000000000',
      'age': null,
      'college': null,
      'standard': null,
      'specialty': null,
      'about': 'Platform administrator',
      'isApproved': 1,
      'hashed_password': _hash('admin123'),
    });
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Old versions from earlier zips:
    // v1/2 -> v3 adds hashed_password and ensures unique email + seed if needed.

    if (oldV < 3) {
      // Add hashed_password if missing
      await db.execute('ALTER TABLE users ADD COLUMN hashed_password TEXT;');

      // Backfill any NULL hashed_password to a default (force reset on first login if you want).
      final defaultHash = _hash('changeme123');
      await db.rawUpdate('''
        UPDATE users SET hashed_password = ?
        WHERE hashed_password IS NULL OR TRIM(hashed_password) = ''
      ''', [defaultHash]);

      // Ensure unique email index exists
      await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS users_email_idx ON users(email);');

      // If no admin exists, seed one.
      final existing = await db.query('users',
          where: 'role = ?', whereArgs: ['admin'], limit: 1);
      if (existing.isEmpty) {
        await db.insert('users', {
          'id': 'admin-1',
          'role': 'admin',
          'name': 'Super Admin',
          'email': 'admin@skillseed.com',
          'phone': '0000000000',
          'isApproved': 1,
          'hashed_password': _hash('admin123'),
        });
      }
    }
  }
}
