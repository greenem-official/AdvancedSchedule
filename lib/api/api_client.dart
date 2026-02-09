import 'dart:convert';
import 'package:flutter7/models/lesson.dart';
import 'package:http/http.dart' as http;

class ScheduleApi {
  static const baseUrl = 'https://ruz.fa.ru/api';

  Future<List<Lesson>> fetchLessons({
    required String groupId,
    required DateTime start,
    required DateTime end,
  }) async {
    final url =
        '$baseUrl/schedule/group/$groupId?start=${_fmt(start)}&finish=${_fmt(end)}&lng=1';

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => Lesson.fromApi(e)).toList();
  }

  String _fmt(DateTime d) =>
      d.toIso8601String().substring(0, 10);
}
