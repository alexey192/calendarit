import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GmailAuthService {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const _clientId = '[REDACTED_GOOGLE_CLIENT_ID]'; // ← replace
  static const _redirectUrl = 'com.smartscheduler:/oauthredirect'; // ← match what you registered
  static const _scopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'email',
    'openid',
  ];

  Future<void> connectAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not signed in');

    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUrl,
        scopes: _scopes,
        promptValues: ['consent'], // Forces account selector
      ),
    );

    if (result == null) throw Exception('OAuth flow failed or canceled');

    final email = _extractEmailFromIdToken(result.idToken) ?? 'unknown';
    final accountId = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gmailAccounts')
        .doc(accountId);

    await ref.set({
      'email': email,
      'accessToken': result.accessToken,
      'refreshToken': result.refreshToken,
      'expiry': result.accessTokenExpirationDateTime?.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final createWorkflow = _functions.httpsCallable('createN8nWorkflow');
    await createWorkflow.call({
      'uid': user.uid,
      'accountId': accountId,
      'email': email,
      'refreshToken': result.refreshToken,
    });
  }

  String? _extractEmailFromIdToken(String? idToken) {
    if (idToken == null) return null;
    final parts = idToken.split('.');
    if (parts.length != 3) return null;

    final payload = utf8.decode(base64Url.decode(base64.normalize(parts[1])));
    final json = jsonDecode(payload);
    return json['email'];
  }
}
