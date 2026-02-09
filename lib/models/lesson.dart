import 'package:flutter/cupertino.dart';

class Lesson {
  final int id;
  final DateTime date;
  final DateTime beginTime;
  final DateTime endTime;
  final String title;
  final String room;
  final Map<String, dynamic> raw;

  Lesson({
    required this.id,
    required this.date,
    required this.beginTime,
    required this.endTime,
    required this.title,
    required this.room,
    required this.raw,
  });

  /// Разбор с API
  factory Lesson.fromApi(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date'] ?? '') ?? DateTime.now();

    DateTime parseTime(String? timeStr) {
      if (timeStr == null) return date;
      if (timeStr.contains('T')) return DateTime.tryParse(timeStr) ?? date;
      final parts = timeStr.split(':');
      if (parts.length < 2) return date;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // название дисциплины
    final discipline = json['discipline'];
    String title = 'Без названия';
    if (discipline != null) {
      if (discipline is String) {
        title = discipline;
      } else if (discipline is Map<String, dynamic>) {
        title = discipline['name']?.toString() ?? 'Без названия';
      }
    }

    // аудитория
    final room = json['auditorium']?.toString() ?? '—';

    return Lesson(
      id: json['lessonOid'] ?? 0,
      date: date,
      beginTime: parseTime(json['beginLesson']),
      endTime: parseTime(json['endLesson']),
      title: title,
      room: room,
      raw: json,
    );
  }

  /// Разбор из сохранённого JSON (например, локальный storage)
  factory Lesson.fromJson(Map<String, dynamic> json) {
    try {
      final raw = Map<String, dynamic>.from(json['raw'] ?? {});

      DateTime parseTimeField(dynamic field, [DateTime? fallback]) {
        final effectiveFallback = fallback ?? DateTime.now();

        if (field == null) return effectiveFallback;
        if (field is DateTime) return field;
        if (field is String) return DateTime.tryParse(field) ?? effectiveFallback;
        return effectiveFallback;
      }

      final discipline = raw['discipline'];
      final aud = raw['auditorium'];

      return Lesson(
        id: json['id'] ?? 0,
        date: parseTimeField(json['date']),
        beginTime: parseTimeField(json['beginTime'], parseTimeField(raw['beginLesson'])),
        endTime: parseTimeField(json['endTime'], parseTimeField(raw['endLesson'])),
        title: (discipline is Map) ? (discipline['name']?.toString() ?? 'Без названия') : 'Без названия',
        room: aud?.toString() ?? '—',
        raw: raw,
      );
    } catch (e, stack) {
      debugPrint("Ошибка при разборе Lesson.fromJson: $e\nСтек:\n$stack");
      debugPrint("JSON snippet: id=${json['id']}, date=${json['date']}, discipline=${json['raw']?['discipline']}, auditorium=${json['raw']?['auditorium']}");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'beginTime': beginTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'title': title,
    'room': room,
    'raw': raw,
  };

  /// Debug
  @override
  String toString() =>
      'Lesson(id: $id, title: $title, room: $room, date: $date, begin: $beginTime, end: $endTime)';
}
