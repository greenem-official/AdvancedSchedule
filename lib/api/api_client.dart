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

  Future<List<Map<String, String>>> searchGroups(String query) async {
    final now = DateTime.now();

    if (_lastRequest != null &&
        now.difference(_lastRequest!) < minInterval) {
      debugPrint("API throttled: too frequent requests");
      await Future.delayed(minInterval);
    }

    _lastRequest = DateTime.now();

    final url = '$baseUrl/search?term=${Uri.encodeQueryComponent(query)}&type=group';

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
      'description': (e['description'] as String?)?.trim() ?? '',
    }).toList();
  }

  // Поиск аудиторий (заглушка)
  Future<List<Map<String, String>>> searchAuditoriums(String query) async {
    // TODO: реализовать когда API будет доступен
    // final url = '$baseUrl/search?term=${Uri.encodeQueryComponent(query)}&type=auditorium';
    throw UnimplementedError('Поиск аудиторий пока не реализован');
  }

  // Поиск корпусов (заглушка)
  Future<List<Map<String, String>>> searchBuildings(String query) async {
    // TODO: реализовать когда API будет доступен
    // final url = '$baseUrl/search?term=${Uri.encodeQueryComponent(query)}&type=building';
    throw UnimplementedError('Поиск корпусов пока не реализован');
  }

  // Универсальный метод загрузки расписания
  Future<List<Lesson>> fetchLessons({
    required String id,
    required DateTime start,
    required DateTime end,
    ScheduleType type = ScheduleType.group,
  }) async {
    final now = DateTime.now();

    if (_lastRequest != null &&
        now.difference(_lastRequest!) < minInterval) {
      debugPrint("API throttled: too frequent requests");
      await Future.delayed(minInterval);
    }

    _lastRequest = DateTime.now();

    final typePath = _getTypePath(type);
    final url = '$baseUrl/schedule/$typePath/$id?start=${_fmt(start)}&finish=${_fmt(end)}&lng=1';

    debugPrint("API request: $url");

    final res = await http.get(Uri.parse(url));

    debugPrint("API response: ${res.statusCode}, size=${res.body.length}");

    if (res.statusCode != 200) {
      throw Exception('API error: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as List;
    return data.map((e) => Lesson.fromApi(e)).toList();
  }

  // Для обратной совместимости
  Future<List<Lesson>> fetchGroupLessons({
    required String groupId,
    required DateTime start,
    required DateTime end,
  }) async {
    return fetchLessons(
      id: groupId,
      start: start,
      end: end,
      type: ScheduleType.group,
    );
  }

  // Заглушка для расписания преподавателя
  Future<List<Lesson>> fetchPersonLessons({
    required String personId,
    required DateTime start,
    required DateTime end,
  }) async {
    return fetchLessons(
      id: personId,
      start: start,
      end: end,
      type: ScheduleType.person,
    );
  }

  // Заглушка для расписания аудитории
  Future<List<Lesson>> fetchAuditoriumLessons({
    required String auditoriumId,
    required DateTime start,
    required DateTime end,
  }) async {
    return fetchLessons(
      id: auditoriumId,
      start: start,
      end: end,
      type: ScheduleType.auditorium,
    );
  }

  // Заглушка для расписания корпуса
  Future<List<Lesson>> fetchBuildingLessons({
    required String buildingId,
    required DateTime start,
    required DateTime end,
  }) async {
    return fetchLessons(
      id: buildingId,
      start: start,
      end: end,
      type: ScheduleType.building,
    );
  }

  String _getTypePath(ScheduleType type) {
    switch (type) {
      case ScheduleType.group:
        return 'group';
      case ScheduleType.person:
        return 'person';
      case ScheduleType.auditorium:
        return 'auditorium';
      case ScheduleType.building:
        return 'building';
    }
  }

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);
}
