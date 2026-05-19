import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter7/models/lesson.dart';
import 'package:http/http.dart' as http;

enum ScheduleType {
  group,
  person,
  auditorium,
  building,
}

class ScheduleApi {
  static const baseUrl = 'https://ruz.fa.ru/api';

  DateTime? _lastRequest;
  final Duration minInterval = const Duration(milliseconds: 50);

  Future<List<Lesson>> fetchLessons({
    required String groupId,
    required DateTime start,
    required DateTime end,
  }) async {
    final now = DateTime.now();

    if (_lastRequest != null &&
        now.difference(_lastRequest!) < minInterval) {
      debugPrint("⚠️ API throttled: too frequent requests");
      await Future.delayed(minInterval);
    }

    _lastRequest = DateTime.now();

    final url =
        '$baseUrl/schedule/group/$groupId?start=${_fmt(start)}&finish=${_fmt(end)}&lng=1';

    debugPrint("📡 API request: $url");

    final res = await http.get(Uri.parse(url));

    debugPrint("📥 API response: ${res.statusCode}, size=${res.body.length}");

    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => Lesson.fromApi(e)).toList();
  }

  Future<List<Map<String, String>>> searchTeachers(String query) async {
    final now = DateTime.now();

    if (_lastRequest != null &&
        now.difference(_lastRequest!) < minInterval) {
      debugPrint("API throttled: too frequent requests");
      await Future.delayed(minInterval);
    }

    _lastRequest = DateTime.now();

    final url = '$baseUrl/search?term=${Uri.encodeQueryComponent(query)}&type=person';

    debugPrint("API request: $url");

    final res = await http.get(Uri.parse(url));

    debugPrint("API response: ${res.statusCode}, size=${res.body.length}");

    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List;

    return data.map((e) => {
      'id': e['id'] as String,
      'name': e['label'] as String,
      'department': (e['description'] as String).trim(),
    }).toList();
  }

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);
}
