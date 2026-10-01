# Gym Tracker - Quick Reference Guide

## Running the App

```bash
cd /Users/piyushgupta/AndroidStudioProjects/gym_tracker
flutter run
```

---

## Component APIs

### Workout Model

```dart
// Create a new workout
final workout = Workout(
  date: DateTime.now(),
  title: "Chest & Triceps",
  notes: "Bench press: 4x8, Dips: 3x10",
  createdAt: DateTime.now(),
);

// Normalize date (remove time component)
DateTime normalized = Workout.normalizeDate(DateTime.now());

// Convert to/from database
Map<String, dynamic> map = workout.toMap();
Workout fromDb = Workout.fromMap(map);

// Copy with updates
Workout updated = workout.copyWith(
  title: "Updated Title",
  notes: "Updated notes",
);
```

---

### DatabaseService

```dart
final db = DatabaseService();

// Initialize database
final database = await db.database;

// Save (insert or update) a workout
int id = await db.saveWorkout(workout);

// Get all workouts
List<Workout> all = await db.getAllWorkouts();

// Get workout for specific date
Workout? workout = await db.getWorkoutByDate(DateTime.now());

// Get workouts in range
List<Workout> range = await db.getWorkoutsInRange(start, end);

// Delete a workout
int deleted = await db.deleteWorkout(workoutId);

// Close connection
await db.closeDatabase();
```

---

### WorkoutProvider

```dart
// Access provider
final provider = context.read<WorkoutProvider>();
final provider = context.watch<WorkoutProvider>();  // Reactive

// Initialize (load all workouts)
await provider.initialize();

// Set selected date and load its workout
await provider.setSelectedDate(DateTime.now());

// Save a workout
await provider.saveWorkout(
  title: "Chest Day",
  notes: "Detailed workout notes",
);

// Delete a workout
await provider.deleteWorkout(workoutId);

// Get workout for specific date (from loaded list)
Workout? workout = provider.getWorkoutForDate(DateTime.now());

// Get workouts for entire month
Map<DateTime, List<Workout>> monthWorkouts = 
  provider.getWorkoutsForMonth(DateTime(2024, 1));

// Access state
List<Workout> workouts = provider.workouts;
Workout? selected = provider.selectedWorkout;
DateTime selectedDate = provider.selectedDate;
bool isLoading = provider.isLoading;
String? error = provider.errorMessage;
```

---

### HomeScreen

**Purpose**: Displays interactive calendar with workouts and selected workout preview

**Key Features**:
- Calendar navigation
- Workout event indicators
- Selected date highlighting
- Quick workout preview
- FAB to add/edit workouts

**Usage**:
```dart
// Typically used as home page
MaterialApp(
  home: const HomeScreen(),
)
```

---

### WorkoutDetailsScreen

**Purpose**: Note entry and editing interface for individual dates

**Key Features**:
- Title input field
- Multi-line notes editor
- Save/Cancel buttons
- Unsaved changes detection
- Loading states

**Usage**:
```dart
// Push from HomeScreen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const WorkoutDetailsScreen(),
  ),
);
```

---

## State Management Pattern

### Using Provider in Widgets

```dart
// Read-only (one-time access)
final workouts = context.read<WorkoutProvider>().workouts;

// Watch (reactive, rebuilds on changes)
final provider = context.watch<WorkoutProvider>();

// Consumer widget (rebuild only this widget)
Consumer<WorkoutProvider>(
  builder: (context, provider, child) {
    return Text(provider.isLoading ? 'Loading...' : 'Ready');
  },
)

// Consumer + Selector (rebuild on specific data change)
Selector<WorkoutProvider, List<Workout>>(
  selector: (_, provider) => provider.workouts,
  builder: (context, workouts, child) {
    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (_, i) => Text(workouts[i].title),
    );
  },
)
```

---

## Common Tasks

### Add a New Workout

```dart
final provider = context.read<WorkoutProvider>();

// Step 1: Set the date
await provider.setSelectedDate(selectedDate);

// Step 2: Navigate to details screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const WorkoutDetailsScreen()),
);

// Step 3: User enters data and saves (handled in WorkoutDetailsScreen)
// Step 4: Provider saves to database
// Step 5: HomeScreen reloads on return
```

### Edit Existing Workout

```dart
// Same flow as adding, but provider.selectedWorkout will be pre-populated
final provider = context.read<WorkoutProvider>();
await provider.setSelectedDate(workoutDate);
// WorkoutDetailsScreen detects existing workout and loads it
```

### Display Calendar Events

```dart
// In CalendarStyle, use eventLoader
TableCalendar(
  eventLoader: (day) {
    final workout = provider.getWorkoutForDate(day);
    return workout != null ? [workout] : [];
  },
)
```

### Handle Errors

```dart
// In WorkoutProvider, errors are stored
if (provider.errorMessage != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.errorMessage!)),
  );
}
```

---

## Date Handling Examples

```dart
// Get current date (normalized)
DateTime today = Workout.normalizeDate(DateTime.now());

// Get specific date
DateTime dec15 = DateTime(2024, 12, 15);  // Already normalized

// Check if two dates are same day
bool sameDay = Workout.normalizeDate(date1) == 
               Workout.normalizeDate(date2);

// Get first day of month
DateTime monthStart = DateTime(date.year, date.month, 1);

// Get last day of month
DateTime monthEnd = DateTime(date.year, date.month + 1, 0);

// Format date for display
String formatted = '${date.day}/${date.month}/${date.year}';
```

---

## Debugging Tips

### Enable Console Logging

```dart
// In DatabaseService or WorkoutProvider
print('Workouts loaded: ${_workouts.length}');
print('Selected date: ${_selectedDate}');
print('Error: ${_errorMessage}');
```

### Check Database Content

```dart
// In DatabaseService
Future<void> printAllWorkouts() async {
  final workouts = await getAllWorkouts();
  for (var w in workouts) {
    print(w.toString());
  }
}
```

### Monitor State Changes

```dart
// In build method
print('Provider rebuilt with ${provider.workouts.length} workouts');
```

### Verify Date Normalization

```dart
final date = DateTime.now();
final normalized = Workout.normalizeDate(date);
assert(normalized.hour == 0);
assert(normalized.minute == 0);
assert(normalized.second == 0);
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/main.dart` | App initialization and theme |
| `lib/models/workout.dart` | Data model definition |
| `lib/services/database_service.dart` | SQLite CRUD operations |
| `lib/providers/workout_provider.dart` | State management & business logic |
| `lib/screens/home_screen.dart` | Calendar view |
| `lib/screens/workout_details_screen.dart` | Note entry/editing |
| `pubspec.yaml` | Dependencies configuration |

---

## Troubleshooting

### Workouts not showing on calendar
- Verify dates are normalized (no time component)
- Check if `getWorkoutForDate()` returns null
- Ensure workouts loaded in WorkoutProvider

### Save button not working
- Check if title is empty (must have title)
- Verify database is initialized
- Check error message in provider

### Blank screen after opening app
- Ensure WorkoutProvider.initialize() is called
- Check database file exists at correct path
- Verify imports are correct

### Hot reload issues
- Use `flutter clean && flutter pub get`
- If database schema issues, uninstall app and reinstall

---

## Performance Notes

- Database queries use index on date column
- Calendar only renders visible months (efficient)
- Workouts loaded once and cached in provider
- Use `Selector` to optimize rebuilds

---

Generated: October 1, 2026

