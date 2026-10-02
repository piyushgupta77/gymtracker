import 'package:flutter/foundation.dart';

import '../models/workout.dart';
import '../services/database_service.dart';
import '../services/firestore_workout_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final FirestoreWorkoutService _firestoreWorkoutService =
      FirestoreWorkoutService();

  List<Workout> _workouts = [];
  Workout? _selectedWorkout;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  /// Getters
  List<Workout> get workouts => _workouts;
  Workout? get selectedWorkout => _selectedWorkout;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;

  /// Initialize provider and load all workouts
  Future<void> initialize() async {
    if (_currentUserId == null) {
      _workouts = [];
      _selectedWorkout = null;
      notifyListeners();
      return;
    }

    await syncFromFirebase();
    await loadAllWorkouts();
  }

  void updateCurrentUser(String? userId) {
    if (_currentUserId == userId) {
      return;
    }

    _currentUserId = userId;
    _workouts = [];
    _selectedWorkout = null;
    _clearError();

    if (_currentUserId == null) {
      notifyListeners();
      return;
    }

    _selectedDate = Workout.normalizeDate(DateTime.now());
    notifyListeners();
  }

  /// Load all workouts from database
  Future<void> loadAllWorkouts() async {
    if (_currentUserId == null) {
      _workouts = [];
      _selectedWorkout = null;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _workouts = await _databaseService.getAllWorkouts(userId: _currentUserId!);
      _selectedWorkout = await _databaseService.getWorkoutByDate(
        _selectedDate,
        userId: _currentUserId!,
      );
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

    if (_currentUserId == null) {
      _selectedWorkout = null;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _selectedWorkout = await _databaseService.getWorkoutByDate(
        _selectedDate,
        userId: _currentUserId!,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load workout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Start a new workout for the selected date (clears any existing selection)
  Future<void> startNewWorkout(DateTime date) async {
    _selectedDate = Workout.normalizeDate(date);
    _selectedWorkout = null; // Clear existing workout for new creation
    notifyListeners();
  }

  /// Save or update a workout - local first, Firebase in background
  Future<void> saveWorkout({
    required String title,
    required String notes,
    required WorkoutTime timeOfDay,
  }) async {
    if (_currentUserId == null) {
      _setError('Please log in before saving a workout.');
      return;
    }

    if (title.trim().isEmpty) {
      _setError('Heading cannot be empty');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final now = DateTime.now();
      final localDraft = Workout(
        id: _selectedWorkout?.id,
        firebaseId: _selectedWorkout?.firebaseId,
        userId: _currentUserId,
        date: _selectedDate,
        title: title.trim(),
        notes: notes.trim(),
        timeOfDay: timeOfDay,
        createdAt: _selectedWorkout?.createdAt ?? now,
        updatedAt: now,
      );

      // STEP 1: Save to local DB immediately
      // ignore: avoid_print
      print('💾 Saving workout to SQLite: ${localDraft.title}');
      final localId = await _databaseService.saveWorkout(localDraft);

      // STEP 2: Update UI immediately with local ID
      final savedWorkout = localDraft.copyWith(id: localId);
      await _upsertInMemoryWorkout(savedWorkout);
      _selectedWorkout = savedWorkout;
      notifyListeners();
      // ignore: avoid_print
      print('✅ Workout saved to SQLite with ID: $localId');

      _setLoading(false);

      // STEP 3: Sync to Firebase in background (non-blocking)
      _syncToFirebaseBackground(savedWorkout);
    } catch (e) {
      _setError('Failed to save workout locally: $e');
      _setLoading(false);
      // ignore: avoid_print
      print('❌ Error saving workout: $e');
    }
  }

  /// Background Firebase sync - fire and forget with error logging
  Future<void> _syncToFirebaseBackground(Workout workout) async {
    try {
      final remoteWorkout = await _firestoreWorkoutService.saveWorkout(
        userId: _currentUserId!,
        workout: workout,
      );

      // Update with Firebase data (server timestamps, etc.)
      if (remoteWorkout.firebaseId != null &&
          remoteWorkout.firebaseId != workout.firebaseId) {
        final updatedWorkout = workout.copyWith(
          firebaseId: remoteWorkout.firebaseId,
          createdAt: remoteWorkout.createdAt,
          updatedAt: remoteWorkout.updatedAt,
        );

        // Update local DB with Firebase-generated data
        await _databaseService.saveWorkout(updatedWorkout);
        await _upsertInMemoryWorkout(updatedWorkout);
        _selectedWorkout = updatedWorkout;
        notifyListeners();
      }
    } catch (e) {
      // Log Firebase error but don't block user - data is already saved locally
      // ignore: avoid_print
      print('⚠️ Firebase sync error (data saved locally): $e');
      // Could show a non-blocking notification here if desired
    }
  }

  /// Delete a workout - local first, Firebase in background
  Future<void> deleteWorkout(int workoutId) async {
    if (_currentUserId == null) {
      _setError('Please log in before deleting a workout.');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final workoutToDelete = _workouts.cast<Workout?>().firstWhere(
        (workout) => workout?.id == workoutId,
        orElse: () => _selectedWorkout?.id == workoutId ? _selectedWorkout : null,
      );

      // STEP 1: Delete from local DB immediately
      await _databaseService.deleteWorkout(workoutId);

      // STEP 2: Update UI immediately
      _workouts.removeWhere((w) => w.id == workoutId);
      if (_selectedWorkout?.id == workoutId) {
        _selectedWorkout = null;
      }
      notifyListeners();

      _setLoading(false);

      // STEP 3: Delete from Firebase in background (non-blocking)
      final firebaseId = workoutToDelete?.firebaseId;
      if (firebaseId != null && firebaseId.isNotEmpty) {
        _deleteWorkoutFromFirebaseBackground(
          userId: _currentUserId!,
          firebaseId: firebaseId,
        );
      }
    } catch (e) {
      _setError('Failed to delete workout: $e');
      _setLoading(false);
    }
  }

  Future<void> _deleteWorkoutFromFirebaseBackground({
    required String userId,
    required String firebaseId,
  }) async {
    try {
      await _firestoreWorkoutService.deleteWorkout(
        userId: userId,
        firebaseId: firebaseId,
      );
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Firebase delete error (workout deleted locally): $e');
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

  Future<void> syncFromFirebase() async {
    if (_currentUserId == null) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final remoteWorkouts = await _firestoreWorkoutService.getAllWorkouts(
        _currentUserId!,
      );

      // Only replace local workouts if we successfully got data from Firebase
      // This prevents offline mode from deleting or overwriting local data
      await _databaseService.replaceWorkoutsForUser(_currentUserId!, remoteWorkouts);
      // ignore: avoid_print
      print('✅ Synced ${remoteWorkouts.length} workouts from Firebase');
    } catch (e) {
      // Silently fail in offline mode - keep local data intact
      // User's offline workouts will sync when connectivity is restored
      // ignore: avoid_print
      print('⚠️ Firebase sync failed (offline mode?), keeping local data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _upsertInMemoryWorkout(Workout workout) async {
    // If workout has an ID, update the existing entry by ID
    if (workout.id != null) {
      final existingIndex = _workouts.indexWhere((item) => item.id == workout.id);
      if (existingIndex != -1) {
        _workouts[existingIndex] = workout;
      } else {
        _workouts.add(workout);
      }
    } else {
      // New workout without ID - just add it
      _workouts.add(workout);
    }

    _workouts.sort((a, b) => b.date.compareTo(a.date));
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
