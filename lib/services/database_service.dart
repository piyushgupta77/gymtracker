import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout.dart';

class DatabaseService {
  static const String tableName = 'workouts';
  static const int _databaseVersion = 2;
  static Database? _database;

  /// Get or initialize database
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize and create database tables
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gym_tracker.db');

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebaseId TEXT,
        userId TEXT,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT NOT NULL,
        timeOfDay TEXT DEFAULT 'morning',
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
      ''',
    );

    // Create index on date for faster queries
    await db.execute(
      'CREATE INDEX idx_date ON $tableName(date)',
    );
    await db.execute(
      'CREATE INDEX idx_user_date ON $tableName(userId, date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN firebaseId TEXT',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN userId TEXT',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_date ON $tableName(userId, date)',
      );
    }
  }

  /// Insert or update a workout
  Future<int> saveWorkout(Workout workout) async {
    final db = await database;

    if (workout.userId == null || workout.userId!.isEmpty) {
      throw Exception('A userId is required to save a workout locally');
    }

    try {
      final workoutToPersist = workout.copyWith(
        updatedAt: workout.updatedAt ?? DateTime.now(),
      );

      // If workout has no ID, it's a new creation - insert it
      if (workoutToPersist.id == null) {
        return await db.insert(tableName, workoutToPersist.toMap());
      }

      // If workout has ID, it's an update - update the existing record
      await db.update(
        tableName,
        workoutToPersist.toMap(),
        where: 'id = ?',
        whereArgs: [workoutToPersist.id],
      );
      return workoutToPersist.id!;
    } catch (e) {
      throw Exception('Error saving workout: $e');
    }
  }

  /// Get all workouts
  Future<List<Workout>> getAllWorkouts({required String userId}) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Error fetching all workouts: $e');
    }
  }

  /// Get workout by date
  Future<Workout?> getWorkoutByDate(DateTime date, {required String userId}) async {
    final db = await database;
    try {
      final normalizedDate = Workout.normalizeDate(date);
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'date = ? AND userId = ?',
        whereArgs: [normalizedDate.toIso8601String(), userId],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return Workout.fromMap(maps.first);
    } catch (e) {
      throw Exception('Error fetching workout by date: $e');
    }
  }

  /// Get workouts in date range
  Future<List<Workout>> getWorkoutsInRange(
    DateTime start,
    DateTime end, {
    required String userId,
  }) async {
    final db = await database;
    try {
      final normalizedStart = Workout.normalizeDate(start).toIso8601String();
      final normalizedEnd = Workout.normalizeDate(end).toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'date BETWEEN ? AND ? AND userId = ?',
        whereArgs: [normalizedStart, normalizedEnd, userId],
        orderBy: 'date DESC',
      );

      return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Error fetching workouts in range: $e');
    }
  }

  Future<void> replaceWorkoutsForUser(
    String userId,
    List<Workout> workouts,
  ) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        await txn.delete(
          tableName,
          where: 'userId = ?',
          whereArgs: [userId],
        );

        for (final workout in workouts) {
          await txn.insert(
            tableName,
            workout.copyWith(userId: userId).toMap()..remove('id'),
          );
        }
      });
    } catch (e) {
      throw Exception('Error replacing workouts for user: $e');
    }
  }

  Future<void> clearWorkoutsForUser(String userId) async {
    final db = await database;

    try {
      await db.delete(
        tableName,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Error clearing workouts for user: $e');
    }
  }

  /// Delete a workout by ID
  Future<int> deleteWorkout(int id) async {
    final db = await database;
    try {
      return await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Error deleting workout: $e');
    }
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
