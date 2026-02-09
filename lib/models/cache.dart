import 'package:flutter7/models/lesson.dart';

class ScheduleCache {
  final String groupId;
  final DateTime lastUpdated;
  final DateTime start;
  final DateTime end;
  final Map<String, List<Lesson>> days;

  ScheduleCache({
    required this.groupId,
    required this.lastUpdated,
    required this.start,
    required this.end,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'meta': {
      'groupId': groupId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'range': {
        'start': start.toIso8601String().substring(0, 10),
        'end': end.toIso8601String().substring(0, 10),
      }
    },
    'days': days.map((k, v) =>
        MapEntry(k, v.map((e) => e.toJson()).toList())),
  };

  factory ScheduleCache.fromJson(Map<String, dynamic> json) {
    final days = <String, List<Lesson>>{};
    final rawDays = json['days'] as Map<String, dynamic>;

    for (final entry in rawDays.entries) {
      days[entry.key] = (entry.value as List)
          .map((e) => Lesson.fromJson(e))
          .toList();
    }

    return ScheduleCache(
      groupId: json['meta']['groupId'],
      lastUpdated: DateTime.parse(json['meta']['lastUpdated']),
      start: DateTime.parse(json['meta']['range']['start']),
      end: DateTime.parse(json['meta']['range']['end']),
      days: days,
    );
  }
}
