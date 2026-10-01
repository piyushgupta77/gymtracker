import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../services/database_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Workout> _workouts = [];
  Workout? _selectedWorkout;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;

  /// Getters
  List<Workout> get workouts => _workouts;
  Workout? get selectedWorkout => _selectedWorkout;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize provider and load all workouts
  Future<void> initialize() async {
    await loadAllWorkouts();
  }

  /// Load all workouts from database
  Future<void> loadAllWorkouts() async {
    _setLoading(true);
    _clearError();

    try {
      _workouts = await _databaseService.getAllWorkouts();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load workouts: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected date and load workout for that date
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = Workout.normalizeDate(date);
    _setLoading(true);
    _clearError();

    try {
      _selectedWorkout = await _databaseService.getWorkoutByDate(_selectedDate);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load workout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save or update a workout
  Future<void> saveWorkout({
    required String title,
    required String notes,
    required WorkoutTime timeOfDay,
  }) async {
    if (title.trim().isEmpty) {
      _setError('Heading cannot be empty');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final now = DateTime.now();
      final workout = Workout(
        id: _selectedWorkout?.id,
        date: _selectedDate,
        title: title.trim(),
        notes: notes.trim(),
        timeOfDay: timeOfDay,
        createdAt: _selectedWorkout?.createdAt ?? now,
        updatedAt: now,
      );

      await _databaseService.saveWorkout(workout);

      // Update local list
      if (_selectedWorkout == null) {
        _workouts.add(workout);
      } else {
        final index = _workouts.indexWhere((w) => w.id == workout.id);
        if (index != -1) {
          _workouts[index] = workout;
        }
      }

      _selectedWorkout = workout;
      notifyListeners();
    } catch (e) {
      _setError('Failed to save workout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a workout
  Future<void> deleteWorkout(int workoutId) async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.deleteWorkout(workoutId);
      _workouts.removeWhere((w) => w.id == workoutId);
      if (_selectedWorkout?.id == workoutId) {
        _selectedWorkout = null;
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete workout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get workout for a specific date
  Workout? getWorkoutForDate(DateTime date) {
    final normalizedDate = Workout.normalizeDate(date);
    try {
      return _workouts.firstWhere(
        (workout) => Workout.normalizeDate(workout.date) == normalizedDate,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all workouts in a specific month for calendar display
  Map<DateTime, List<Workout>> getWorkoutsForMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    final Map<DateTime, List<Workout>> workoutsByDate = {};

    for (final workout in _workouts) {
      if (workout.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          workout.date.isBefore(monthEnd.add(const Duration(days: 1)))) {
        final normalizedDate = Workout.normalizeDate(workout.date);
        workoutsByDate.putIfAbsent(normalizedDate, () => []);
        workoutsByDate[normalizedDate]!.add(workout);
      }
    }

    return workoutsByDate;
  }

  /// Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

