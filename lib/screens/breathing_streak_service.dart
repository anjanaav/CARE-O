import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BreathingStreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> getUserBreathingData() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('breathing_sessions').doc(userId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching breathing session data: $e");
      return null;
    }
  }

  Future<void> updateBreathingSession() async {
    try {
      DocumentReference userDoc =
          _firestore.collection('breathing_sessions').doc(userId);
      DocumentSnapshot doc = await userDoc.get();
      DateTime now = DateTime.now();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime lastSessionDate =
            (data['lastSessionDate'] as Timestamp).toDate();
        int streakCount = data['streakCount'];
        int totalSessions = data['totalSessions'];

        // Check if the last session was yesterday to continue the streak
        if (now.difference(lastSessionDate).inDays == 1) {
          streakCount++;
        } else if (now.difference(lastSessionDate).inDays > 1) {
          // Reset streak if the user skipped a day
          streakCount = 1;
        }

        // Update Firestore
        await userDoc.update({
          'lastSessionDate': now,
          'streakCount': streakCount,
          'totalSessions': totalSessions + 1,
        });
      } else {
        // Create a new document for first-time users
        await userDoc.set({
          'lastSessionDate': now,
          'streakCount': 1,
          'totalSessions': 1,
          'userId': userId,
        });
      }
    } catch (e) {
      debugPrint("Error updating breathing session: $e");
    }
  }
}
