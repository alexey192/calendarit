import 'package:calendarit/features/auth/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreUtils {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> saveEventWithPendingStatus(Map<String, dynamic> eventJson) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;

    final enriched = {
      ...eventJson,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .add(enriched);
  }

  static Future<String?> _getCurrentUserId() async {
    // Replace this with your actual logic for getting the user ID
    // For example: FirebaseAuth.instance.currentUser?.uid
    // Or if using provider: context.read<AuthCubit>().userId
    //return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
