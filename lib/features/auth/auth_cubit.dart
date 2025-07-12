import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

import '../../shared/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth;

  AuthCubit({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        super(AuthInitial());

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('gmailAccounts')
          .get();

      final accountIds = snapshot.docs.map((doc) => doc.id).toList();

      emit(AuthSuccess(accountIds: accountIds));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Sign-in failed.'));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final newUser = UserModel(
        uid: uid,
        email: email,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser.toMap());

      emit(AuthSuccess(accountIds: []));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Sign-up failed.'));
    } catch (e) {
      emit(AuthFailure('Unexpected error: $e'));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email);
      emit(AuthInfo('Password reset email sent.'));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Reset failed.'));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    emit(AuthInitial());
  }

  List<String> get accountIds {
    final currentState = state;
    if (currentState is AuthSuccess) {
      return currentState.accountIds;
    }
    return [];
  }
}
