# 🎨 Gym Tracker - Visual Component Guide

## Screen Layouts & Component Structure

---

## 1. HOME SCREEN (Calendar View)

```
┌─────────────────────────────────────────┐
│  Gym Tracker                       [≡]  │  ← AppBar
└─────────────────────────────────────────┘
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  < March 2024 >                   │  │  ← Month Navigation
│  ├───────────────────────────────────┤  │
│  │  Sun  Mon  Tue  Wed  Thu  Fri Sat │  │
│  ├───────────────────────────────────┤  │
│  │  26   27   28   29   1    2   3   │  │
│  │  4    5    6    7  [8●] 9   10    │  │  ← [8●] = Selected Day
│  │  11   12   13   14   15   16   17 │  │
│  │  18   19   20  [21●] 22   23   24 │  │  ← [21●] = Day with workout
│  │  25   26   27   28   29   30   31 │  │
│  │  1    2    3    4    5    6    7  │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Workout for 21/3/2024                  │  ← Date Label
│  ┌─────────────────────────────────┐   │
│  │ Chest & Triceps                 │   │  ← Workout Card
│  │ Bench press 4x8, Dips 3x10...  │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
                    ⊕                       ← FAB (Add/Edit)
```

### HomeScreen Components

```dart
AppBar {
  title: "Gym Tracker"
  elevation: 0
}

TableCalendar {
  focusedDay: DateTime
  selectedDayPredicate: (day) → bool
  onDaySelected: (day) → void
  eventLoader: (day) → List<Workout>
  calendarStyle: {
    selectedDecoration: primary color
    todayDecoration: secondary color
    markerDecoration: tertiary color
  }
  headerStyle: {
    formatButtonVisible: false
    titleCentered: true
  }
}

WorkoutPreview {
  if (selectedWorkout != null)
    Card {
      title: Workout.title
      notes: Workout.notes (truncated)
    }
  else
    Container {
      "No workout recorded for this date"
    }
}

FloatingActionButton {
  icon: Icons.add
  onPressed: openWorkoutDetailsScreen()
}
```

### HomeScreen State

```dart
_focusedDay: DateTime        // Calendar navigation focus
_selectedDay: DateTime       // Currently selected date
_workouts: List<Workout>     // From WorkoutProvider
_selectedWorkout: Workout?   // From WorkoutProvider
```

---

## 2. WORKOUT DETAILS SCREEN (Note Entry)

```
┌─────────────────────────────────────────┐
│  Workout Details              [✕]       │  ← Close button
└─────────────────────────────────────────┘
│                                         │
│  Date: 21/3/2024                        │  ← Date Info
│                                         │
│  Heading/Title                          │  ← Label
│  ┌─────────────────────────────┐        │
│  │ Chest & Triceps          │45│        │  ← Input field
│  └─────────────────────────────┘        │     (100 char limit)
│                                         │
│  Workout Notes                          │  ← Label
│  ┌─────────────────────────────┐        │
│  │ • Bench press 4x8          │        │
│  │ • Incline dumbbell 3x10    │        │
│  │ • Tricep dips 3x12         │        │
│  │ • Rope pushdowns 4x15      │        │
│  │ • Close grip bench 3x8     │        │
│  │ • Overhead extension 3x12  │        │
│  │ • Finished with 50 pushups │        │
│  │                            │        │  ← Multiline editor
│  │                            │        │
│  │                            │        │
│  └─────────────────────────────┘        │
│                                         │
│  [○ ○ ○ ○]  (loading indicator)        │  ← Shows if saving
│                                         │
│  ┌──────────────┬──────────────┐        │
│  │   Cancel     │     Save     │        │  ← Fixed footer
│  └──────────────┴──────────────┘        │     (appears above keyboard)
```

### WorkoutDetailsScreen Components

```dart
AppBar {
  title: "Workout Details"
  leading: IconButton(
    icon: Icons.close
    onPressed: onCancel()
  )
}

Body {
  SingleChildScrollView {
    Column {
      DateDisplay {
        text: "Date: ${day}/${month}/${year}"
      }
      
      TitleSection {
        label: "Heading/Title"
        textField: {
          maxLength: 100
          hint: "e.g., Chest & Triceps"
        }
      }
      
      NotesSection {
        label: "Workout Notes"
        textArea: {
          minLines: 6
          maxLines: 10
          hint: "Enter your workout details..."
        }
      }
      
      if (isLoading)
        CircularProgressIndicator()
    }
  }
}

BottomNavigationBar {
  Row {
    Expanded {
      OutlinedButton("Cancel")
    }
    Expanded {
      ElevatedButton("Save")
    }
  }
}
```

### WorkoutDetailsScreen State

```dart
_titleController: TextEditingController
_notesController: TextEditingController
_hasChanges: bool
_selectedWorkout: Workout?  // From WorkoutProvider
_selectedDate: DateTime     // From WorkoutProvider
_isLoading: bool            // From WorkoutProvider
```

---

## 3. DATA FLOW DIAGRAM

```
                        ┌─────────────┐
                        │   HomeScreen│
                        └──────┬──────┘
                               │
                    ┌──────────┴──────────┐
                    │                    │
            ┌───────▼────────┐  ┌────────▼──────────┐
            │  TableCalendar │  │  WorkoutPreview  │
            └────────────────┘  └───────┬──────────┘
                    │ (onDaySelected)   │
                    │                   │
            ┌───────▼─────────────────────────┐
            │  WorkoutProvider.               │
            │  setSelectedDate(date)          │
            └───────┬─────────────────────────┘
                    │
            ┌───────▼──────────────────────┐
            │  DatabaseService.            │
            │  getWorkoutByDate(date)      │
            └───────┬──────────────────────┘
                    │
            ┌───────▼──────────────────────┐
            │  SQLite Database             │
            │  Query: WHERE date = ?       │
            └──────────────────────────────┘


            FAB Tap (Add/Edit)
                    │
            ┌───────▼──────────────────────┐
            │  WorkoutDetailsScreen        │
            │  (title + notes inputs)      │
            └───────┬──────────────────────┘
                    │ (onSave)
            ┌───────▼──────────────────────┐
            │  WorkoutProvider.saveWorkout │
            │  (title, notes)              │
            └───────┬──────────────────────┘
                    │
            ┌───────▼──────────────────────┐
            │  DatabaseService.saveWorkout │
            │  (insert or update)          │
            └───────┬──────────────────────┘
                    │
            ┌───────▼──────────────────────┐
            │  SQLite Database             │
            │  INSERT or UPDATE            │
            └───────┬──────────────────────┘
                    │
            ┌───────▼──────────────────────┐
            │  Return to HomeScreen        │
            │  loadAllWorkouts()           │
            │  Refresh Calendar Display    │
            └──────────────────────────────┘
```

---

## 4. COMPONENT INTERACTION FLOW

### Adding a Workout
```
User taps FAB
    ↓
setSelectedDate(date)
    ↓
WorkoutDetailsScreen opens (with empty fields if new)
    ↓
User types title & notes
    ↓
User taps Save
    ↓
Validation: title not empty?
    ├─ NO → Show error SnackBar
    └─ YES ↓
saveWorkout(title, notes)
    ↓
Create Workout object
    ↓
DatabaseService.saveWorkout()
    ↓
SQLite INSERT/UPDATE
    ↓
Update local _workouts list
    ↓
notifyListeners()
    ↓
HomeScreen rebuilds with new workout
    ↓
Show success SnackBar
    ↓
Pop WorkoutDetailsScreen
```

### Editing a Workout
```
User taps date with existing workout
    ↓
setSelectedDate(date)
    ↓
getWorkoutByDate(date) returns existing Workout
    ↓
WorkoutDetailsScreen opens (fields pre-filled)
    ↓
User modifies content
    ↓
User taps Save
    ↓
saveWorkout() called with same date
    ↓
Existing Workout.id used for UPDATE
    ↓
DatabaseService.saveWorkout() updates row
    ↓
Local list updated
    ↓
Calendar refreshes
```

### Handling Unsaved Changes
```
User taps Cancel or back
    ↓
_hasChanges detected?
    ├─ NO → Pop immediately
    └─ YES ↓
        Show confirmation dialog
            ↓
        User confirms discard?
        ├─ NO → Dialog closes, stay on screen
        └─ YES ↓
            Pop WorkoutDetailsScreen
            No database changes
```

---

## 5. WIDGET TREE STRUCTURE

```
MyApp
└── ChangeNotifierProvider<WorkoutProvider>
    └── MaterialApp
        └── HomeScreen
            ├── AppBar
            ├── Body: Consumer<WorkoutProvider>
            │   ├── SingleChildScrollView
            │   │   └── Column
            │   │       ├── Card
            │   │       │   └── TableCalendar
            │   │       │       ├── Header (Navigation)
            │   │       │       ├── Calendar Grid
            │   │       │       └── Event Markers
            │   │       └── WorkoutPreview
            │   │           └── Card (or placeholder)
            ├── FloatingActionButton
            └── [WorkoutDetailsScreen] (pushed to navigator)
                ├── PopScope
                │   └── Scaffold
                │       ├── AppBar
                │       ├── Body: Consumer<WorkoutProvider>
                │       │   └── SingleChildScrollView
                │       │       └── Column
                │       │           ├── DateDisplay
                │       │           ├── TitleInput
                │       │           ├── NotesInput
                │       │           └── LoadingIndicator
                │       └── BottomNavigationBar
                │           └── Row
                │               ├── CancelButton
                │               └── SaveButton
```

---

## 6. STATE MANAGEMENT HIERARCHY

```
WorkoutProvider (ChangeNotifier)
├── _workouts: List<Workout>
├── _selectedWorkout: Workout?
├── _selectedDate: DateTime
├── _isLoading: bool
├── _errorMessage: String?
│
└── Methods:
    ├── initialize()
    ├── loadAllWorkouts()
    ├── setSelectedDate(date)
    ├── saveWorkout(title, notes)
    ├── deleteWorkout(id)
    ├── getWorkoutForDate(date)
    └── getWorkoutsForMonth(month)

Database Access Pattern:
  WorkoutProvider
    └── DatabaseService (singleton)
        └── SQLite Database
            └── workouts table
```

---

## 7. UI THEME & STYLING

```
Color Scheme:
  Primary Color: Deep Purple
  Secondary Color: Secondary Purple
  Tertiary Color: Tertiary Purple
  Background: Material background
  Surface: Material surface

Text Styles:
  AppBar: headline/title
  Labels: titleMedium
  Body: bodyMedium
  Headers: headlineSmall

Spacing:
  Padding: 16.0 (standard)
  Card elevation: 2-4
  Border radius: 8.0
  Gap between sections: 24.0

Icons:
  Add: Icons.add (FAB)
  Close: Icons.close (Cancel)
  Back: Material default
```

---

## 8. ERROR STATES & FEEDBACK

```
Input Validation:
  Empty Title → "Please enter a heading"
  Others → Allow

Save Feedback:
  Success → SnackBar (green, "Workout saved successfully")
  Error → SnackBar (red, error message)

Navigation:
  Unsaved Changes → AlertDialog confirmation
  
  Loading State:
    Disabled buttons → User can't double-click
    Progress indicator → Visual feedback
```

---

## 9. RESPONSIVE BEHAVIOR

```
Portrait Mode (Mobile):
  Calendar: Full width (minus padding)
  TextFields: Full width
  Buttons: Stack horizontally (Expanded)
  Scrollable content

Landscape Mode (if supported):
  Calendar: Adjusted to fit
  Layout: Maintains readability
  
  Soft Keyboard:
    BottomNavBar: Moves above keyboard
    Content: Scrollable
    No overlap on inputs
```

---

This visual guide complements the technical documentation and provides a clear picture of how all components interact!

Generated: October 1, 2026

