import 'package:calendarit/app/secret_values.dart';
import 'package:calendarit/models/calendar_event.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../app/endpoints.dart';


class CalendarRepository {
  static const _tokenEndpoint = Endpoints.tokenEndpoint;
  static const _clientId = SecretValues.clientId;
  static const _clientSecret = SecretValues.clientSecret;

  Future<List<CalendarEvent>> fetchCalendarEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final accountDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('gmailAccounts')
        .get();

    final allEvents = <CalendarEvent>[];

    for (final doc in accountDocs.docs) {
      final data = doc.data();
      String accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final rawExpiry = data['expiry'];
      final expiry = rawExpiry is Timestamp
          ? rawExpiry.toDate()
          : DateTime.parse(rawExpiry.toString());
      final email = data['email'];

      if (DateTime.now().isAfter(expiry)) {
        final refreshed = await _refreshAccessToken(refreshToken);
        if (refreshed != null) {
          accessToken = refreshed['access_token'];
          await doc.reference.update({
            'accessToken': accessToken,
            'expiry': DateTime.now().add(Duration(seconds: refreshed['expires_in'])),
          });
        } else {
          continue; // Skip account if refresh fails
        }
      }

      try {
        final uri = Uri.parse(
          'https://www.googleapis.com/calendar/v3/calendars/$email/events'
              '?maxResults=200&orderBy=startTime&singleEvents=true&timeMin=${DateTime.now().add(Duration(days: -7)).toUtc().toIso8601String()}',
        );

        final response = await http.get(uri, headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        });

        if (response.statusCode != 200) continue;

        final json = jsonDecode(response.body);
        for (final item in (json['items'] ?? [])) {
          final start = item['start']['dateTime'] ?? item['start']['date'];
          final end = item['end']['dateTime'] ?? item['end']['date'];
          if (start == null || end == null) continue;

          allEvents.add(CalendarEvent(
            id: item['id'],
            title: item['summary'] ?? 'No Title',
            start: DateTime.parse(start).toLocal(),
            end: DateTime.parse(end).toLocal(),
          ));
        }
      } catch (_) {
        continue;
      }
    }

    //allEvents.sort((a, b) => a.start.compareTo(b.start));
    allEvents.sort((a, b) => b.start!.compareTo(a.start!));
    return allEvents;
  }

  Future<Map<String, dynamic>?> _refreshAccessToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<void> addEventToGoogleCalendar({
    required String accountId,
    required String title,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? location,
  }) async {
    // Fetch the latest tokens from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('gmailAccounts')
        .doc(accountId)
        .get();

    final data = doc.data();
    if (data == null || data['accessToken'] == null) {
      throw Exception('Missing access token for $accountId');
    }

    final accessToken = data['accessToken'];

    final url = Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary/events');
    final body = {
      'summary': title,
      'start': {
        'dateTime': startDateTime.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      'end': {
        'dateTime': endDateTime.toUtc().toIso8601String(),
        'timeZone': 'UTC',
      },
      if (location != null && location.trim().isNotEmpty)
        'location': location.trim(),
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('CalendarRepository: Response status code: ${response.statusCode}');

    if (response.statusCode == 401) {
      // TODO: Implement token refresh if needed
      throw Exception('Unauthorized – token may have expired.');
    } else if (response.statusCode >= 400) {
      throw Exception('Google Calendar API error: ${response.body}');
    }

    // Successfully added
  }
}

