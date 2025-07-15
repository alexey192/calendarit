import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import '../app/endpoints.dart';
import '../app/secret_values.dart'; // Only works on Web

class GmailAuthService {
  static const _clientId = SecretValues.clientId;
  static const _redirectUriWeb = Endpoints.redirectUriWeb;
  static const _redirectUriMobile = Endpoints.redirectUriMobile;

  static const _scopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events',
    'email',
    'openid',
  ];

  final FlutterAppAuth _appAuth = FlutterAppAuth();

  Future<void> connectAccount() async {
    if (kIsWeb) {
      _startWebFlow();
    } else {
      await _startMobileFlow();
    }
  }

  /// For Flutter Web: just build and open the Google OAuth URL
  void _startWebFlow() {
    final encodedScopes = _scopes.join(' ');

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUriWeb,
      'scope': encodedScopes,
      'access_type': 'offline',
      'prompt': 'consent',
    });

    html.window.open(authUrl.toString(), 'GmailLogin');
  }

  /// For Android/iOS: use flutter_appauth to do the whole flow
  Future<void> _startMobileFlow() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUriMobile,
        scopes: _scopes,
        promptValues: ['consent'],
        issuer: 'https://accounts.google.com',
      ),
    );

    if (result == null) throw Exception('OAuth canceled or failed');
  }
}
