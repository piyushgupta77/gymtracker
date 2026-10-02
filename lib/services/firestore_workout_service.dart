import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workout.dart';

class FirestoreWorkoutService {
  FirestoreWorkoutService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _workoutCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('workouts');
  }

  /// Generate unique workout ID using Firestore's auto-ID
  /// This allows multiple workouts per day
  String generateUniqueWorkoutId() {
    return _workoutCollection('dummy').doc().id;
  }

  Future<Workout> saveWorkout({
    required String userId,
    required Workout workout,
  }) async {
    try {
      // Use existing firebaseId or generate a new one
      final documentId = workout.firebaseId ?? generateUniqueWorkoutId();
      final documentReference = _workoutCollection(userId).doc(documentId);

      final Map<String, dynamic> data = workout
          .copyWith(firebaseId: documentId, userId: userId)
          .toFirestoreMap();

      data['updatedAt'] = FieldValue.serverTimestamp();
      if (workout.firebaseId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      // ignore: avoid_print
      print('💾 Saving workout to Firestore: users/$userId/workouts/$documentId');

      await documentReference.set(data, SetOptions(merge: true));

      final snapshot = await documentReference.get();
      final snapshotData = snapshot.data();

      if (snapshotData == null) {
        throw Exception('Workout was saved to Firebase but no data was returned.');
      }

      // ignore: avoid_print
      print('✅ Workout saved successfully to Firestore: $documentId');

      return Workout.fromFirestore(documentId, userId, snapshotData);
    } catch (e) {
      // ignore: avoid_print
      print('❌ Firestore save error: $e');
      rethrow;
    }
  }

  Future<List<Workout>> getAllWorkouts(String userId) async {
    try {
      // ignore: avoid_print
      print('📖 Fetching all workouts from Firestore for user: $userId');

      final snapshot = await _workoutCollection(userId).orderBy('date').get();

      // ignore: avoid_print
      print('📊 Found ${snapshot.docs.length} workouts in Firestore');

      return snapshot.docs
          .map((doc) => Workout.fromFirestore(doc.id, userId, doc.data()))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Firestore fetch error: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkout({
    required String userId,
    required String firebaseId,
  }) async {
    try {
      // ignore: avoid_print
      print('🗑️ Deleting workout from Firestore: users/$userId/workouts/$firebaseId');

      await _workoutCollection(userId).doc(firebaseId).delete();

      // ignore: avoid_print
      print('✅ Workout deleted successfully from Firestore: $firebaseId');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Firestore delete error: $e');
      rethrow;
    }
  }
}
