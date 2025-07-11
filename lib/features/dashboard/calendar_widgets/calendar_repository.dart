import 'package:calendarit/app/const_values.dart';
import 'package:calendarit/models/calendar_event.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;


class CalendarRepository {
  static const _tokenEndpoint = ConstValues.tokenEndpoint;
  static const _clientId = ConstValues.clientId;
  static const _clientSecret = ConstValues.clientSecret;

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
              '?maxResults=20&orderBy=startTime&singleEvents=true&timeMin=${DateTime.now().toUtc().toIso8601String()}',
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
            startTime: DateTime.parse(start).toLocal(),
            endTime: DateTime.parse(end).toLocal(),
          ));
        }
      } catch (_) {
        continue;
      }
    }

    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
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
}
