import 'package:flutter7/api/api_client.dart';
import 'package:flutter7/data/file_cache.dart';
import 'package:flutter7/models/cache.dart';
import 'package:flutter7/models/lesson.dart';

class ScheduleRepository {
  final api = ScheduleApi();
  final storage = ScheduleStorage();

  Future<List<Lesson>> getDay({
    required String groupId,
    required DateTime date,
  }) async {
    final cache = await storage.load(groupId);

    final key = date.toIso8601String().substring(0, 10);

    // 1) если есть кеш и дата внутри диапазона
    if (cache != null &&
        date.isAfter(cache.start.subtract(const Duration(days: 1))) &&
        date.isBefore(cache.end.add(const Duration(days: 1)))) {
      return cache.days[key] ?? [];
    }

    // 2) иначе — грузим диапазон (например, неделю)
    final start = date.subtract(const Duration(days: 3));
    final end = date.add(const Duration(days: 3));

    final lessons = await api.fetchLessons(
      groupId: groupId,
      start: start,
      end: end,
    );

    final days = <String, List<Lesson>>{};

    for (final l in lessons) {
      final d = l.date.toIso8601String().substring(0, 10);
      days.putIfAbsent(d, () => []).add(l);
    }

    final newCache = ScheduleCache(
      groupId: groupId,
      lastUpdated: DateTime.now(),
      start: start,
      end: end,
      days: days,
    );

    await storage.save(newCache);

    return days[key] ?? [];
  }
}
