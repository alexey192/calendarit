import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';

import '../app/const_values.dart';

class GmailWebRedirectScreen extends StatefulWidget {
  const GmailWebRedirectScreen({super.key});

  @override
  State<GmailWebRedirectScreen> createState() => _GmailWebRedirectScreenState();
}

class _GmailWebRedirectScreenState extends State<GmailWebRedirectScreen> {
  String? message;

  @override
  void initState() {
    super.initState();
    _handleOAuthRedirect();
  }

  Future<void> _handleOAuthRedirect() async {
    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];

    if (code == null) {
      setState(() => message = 'Missing authorization code in URL.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => message = 'User is not signed in.');
      return;
    }

    try {
      //const clientId = '[REDACTED_GOOGLE_CLIENT_ID]';
      //const clientSecret = '[REDACTED_GOOGLE_CLIENT_SECRET]'; // only okay for dev
      //const redirectUri = 'https://calendar-it-31e1c.web.app/oauth2redirect';
      //const redirectUri = 'http://localhost:65508/oauth2redirect';
      const clientId = ConstValues.clientId;
      const clientSecret = ConstValues.clientSecret;
      const redirectUri = ConstValues.redirectUriWeb;

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Token exchange failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final idToken = data['id_token'];
      final expiresIn = data['expires_in'];

      final email = _extractEmailFromIdToken(idToken) ?? 'unknown';
      final accountId = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final expiry = DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('gmailAccounts')
          .doc(accountId)
          .set({
        'email': email,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiry': expiry,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Calling subscribeToGmailPush...');
      print('uid: ${user.uid}, accountId: $accountId');

      final resp = await http.post(
        Uri.parse('https://us-central1-calendar-it-31e1c.cloudfunctions.net/subscribeToGmailPushApi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'accountId': accountId,
        }),
      );
      print('Response: ${resp.body}');

      setState(() => message = '✅ Gmail connected!');
      await Future.delayed(const Duration(seconds: 2));
      context.go('/dashboard');
    } catch (e) {
      setState(() => message = '❌ Error: $e');
    }
  }

  String? _extractEmailFromIdToken(String? idToken) {
    if (idToken == null) return null;
    final parts = idToken.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(base64.normalize(parts[1])));
    final json = jsonDecode(payload);
    return json['email'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message ?? 'Connecting Gmail...'),
      ),
    );
  }
}
