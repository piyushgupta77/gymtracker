import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/workout.dart';

class DatabaseService {
  static const String tableName = 'workouts';
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
      version: 1,
      onCreate: _createTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
  }

  /// Insert or update a workout
  Future<int> saveWorkout(Workout workout) async {
    final db = await database;
    try {
      if (workout.id == null) {
        // Insert new workout
        return await db.insert(tableName, workout.toMap());
      } else {
        // Update existing workout
        await db.update(
          tableName,
          workout.copyWith(updatedAt: DateTime.now()).toMap(),
          where: 'id = ?',
          whereArgs: [workout.id],
        );
        return workout.id!;
      }
    } catch (e) {
      throw Exception('Error saving workout: $e');
    }
  }

  /// Get all workouts
  Future<List<Workout>> getAllWorkouts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(tableName);
      return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Error fetching all workouts: $e');
    }
  }

  /// Get workout by date
  Future<Workout?> getWorkoutByDate(DateTime date) async {
    final db = await database;
    try {
      final normalizedDate = Workout.normalizeDate(date);
      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'date = ?',
        whereArgs: [normalizedDate.toIso8601String()],
      );

      if (maps.isEmpty) return null;
      return Workout.fromMap(maps.first);
    } catch (e) {
      throw Exception('Error fetching workout by date: $e');
    }
  }

  /// Get workouts in date range
  Future<List<Workout>> getWorkoutsInRange(DateTime start, DateTime end) async {
    final db = await database;
    try {
      final normalizedStart = Workout.normalizeDate(start).toIso8601String();
      final normalizedEnd = Workout.normalizeDate(end).toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: 'date BETWEEN ? AND ?',
        whereArgs: [normalizedStart, normalizedEnd],
        orderBy: 'date DESC',
      );

      return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Error fetching workouts in range: $e');
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

