import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkoutTime { morning, evening }

class Workout {
  final int? id;
  final String? firebaseId;
  final String? userId;
  final DateTime date;
  final String title;
  final String notes;
  final WorkoutTime timeOfDay;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Workout({
    this.id,
    this.firebaseId,
    this.userId,
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
      'firebaseId': firebaseId,
      'userId': userId,
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
      firebaseId: map['firebaseId'] as String?,
      userId: map['userId'] as String?,
      date: _parseDateTime(map['date']),
      title: map['title'] as String,
      notes: map['notes'] as String,
      timeOfDay: _parseTimeOfDay(map['timeOfDay'] as String?),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
    );
  }

  factory Workout.fromFirestore(
    String firebaseId,
    String userId,
    Map<String, dynamic> data,
  ) {
    return Workout(
      firebaseId: firebaseId,
      userId: userId,
      date: _parseDateTime(data['date']),
      title: (data['title'] as String?) ?? '',
      notes: (data['notes'] as String?) ?? '',
      timeOfDay: _parseTimeOfDay(data['timeOfDay'] as String?),
      createdAt: data['createdAt'] != null
          ? _parseDateTime(data['createdAt'])
          : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null ? _parseDateTime(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'firebaseId': firebaseId,
      'userId': userId,
      'date': Timestamp.fromDate(normalizeDate(date)),
      'title': title,
      'notes': notes,
      'timeOfDay': timeOfDay.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    throw ArgumentError('Unsupported date value: $value');
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
    String? firebaseId,
    String? userId,
    DateTime? date,
    String? title,
    String? notes,
    WorkoutTime? timeOfDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      userId: userId ?? this.userId,
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
    return 'Workout(id: $id, firebaseId: $firebaseId, userId: $userId, date: $date, title: $title, timeOfDay: $timeOfDay, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

