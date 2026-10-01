enum WorkoutTime { morning, evening }

class Workout {
  final int? id;
  final DateTime date;
  final String title;
  final String notes;
  final WorkoutTime timeOfDay;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Workout({
    this.id,
    required this.date,
    required this.title,
    required this.notes,
    this.timeOfDay = WorkoutTime.morning,
    required this.createdAt,
    this.updatedAt,
  });

  /// Normalize date to midnight (no time component)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Convert Workout to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'notes': notes,
      'timeOfDay': timeOfDay.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create Workout from database map
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      title: map['title'] as String,
      notes: map['notes'] as String,
      timeOfDay: _parseTimeOfDay(map['timeOfDay'] as String?),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  /// Helper to parse timeOfDay from string
  static WorkoutTime _parseTimeOfDay(String? value) {
    if (value == null) return WorkoutTime.morning;
    try {
      return WorkoutTime.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return WorkoutTime.morning;
    }
  }

  /// Create a copy of Workout with optional field updates
  Workout copyWith({
    int? id,
    DateTime? date,
    String? title,
    String? notes,
    WorkoutTime? timeOfDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Workout(id: $id, date: $date, title: $title, timeOfDay: $timeOfDay, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

