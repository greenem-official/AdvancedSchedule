import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter7/data/constants.dart';

class LessonType {
  final String internalName;
  final String displayName;
  final int typeOid;
  final Color color;

  const LessonType({
    required this.internalName,
    required this.displayName,
    required this.typeOid,
    required this.color,
  });
}

class Lesson {
  final int id;
  final DateTime date;
  final DateTime beginTime;
  final DateTime endTime;
  late final String title;
  late final String room;
  late final LessonType lessonType;
  final Map<String, dynamic> raw;

  Lesson({
    required this.id,
    required this.date,
    required this.beginTime,
    required this.endTime,
    required this.raw,
  }) {
    _populateExtraFields();
  }

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

    return Lesson(
      id: json['lessonOid'] ?? 0,
      date: date,
      beginTime: parseTime(json['beginLesson']),
      endTime: parseTime(json['endLesson']),
      raw: json,
    );
  }

  /// Разбор из локального JSON
  factory Lesson.fromJson(Map<String, dynamic> json) {
    final raw = Map<String, dynamic>.from(json['raw'] ?? {});

    DateTime parseTimeField(dynamic field, [DateTime? fallback]) {
      final effectiveFallback = fallback ?? DateTime.now();
      if (field == null) return effectiveFallback;
      if (field is DateTime) return field;
      if (field is String) return DateTime.tryParse(field) ?? effectiveFallback;
      return effectiveFallback;
    }

    return Lesson(
      id: json['id'] ?? 0,
      date: parseTimeField(json['date']),
      beginTime: parseTimeField(json['beginTime'], parseTimeField(raw['beginLesson'])),
      endTime: parseTimeField(json['endTime'], parseTimeField(raw['endLesson'])),
      raw: raw,
    );
  }

  /// Общий метод для заполнения остальных полей
  void _populateExtraFields() {
    // title
    final discipline = raw['discipline'];
    if (discipline == null) {
      title = 'Без названия';
    } else if (discipline is String) {
      title = discipline;
    } else if (discipline is Map<String, dynamic>) {
      title = discipline['name']?.toString() ?? 'Без названия';
    } else {
      title = 'Без названия';
    }

    // room
    room = raw['auditorium']?.toString() ?? '—';

    final typeOid = raw['kindOfWorkOid'];
    lessonType = lessonTypeMapById[typeOid] ?? LessonType(
      internalName: "unknown_$typeOid",
      displayName: raw['kindOfWork'] ?? "Неизвестно",
      typeOid: typeOid ?? -1,
      color: const Color(0xFF9E9E9E), // серый для неизвестных
    );
    // if(lessonType.displayName.startsWith("unknown")) debugPrint("Unknown lesson type $typeOid");
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

  @override
  String toString() =>
      'Lesson(id: $id, title: $title, room: $room, date: $date, begin: $beginTime, end: $endTime)';
}
