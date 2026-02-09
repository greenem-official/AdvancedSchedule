import 'package:flutter/cupertino.dart';
import 'package:flutter7/api/api_client.dart';
import 'package:flutter7/data/blacklist/blacklist_engine.dart';
import 'package:flutter7/data/blacklist/blacklist_repository.dart';
import 'package:flutter7/data/file_cache.dart';
import 'package:flutter7/models/cache.dart';
import 'package:flutter7/models/lesson.dart';

class ScheduleRepository {
  final api = ScheduleApi();
  final storage = ScheduleStorage();

  Future<List<Lesson>> getDay({
    required String groupId,
    required DateTime date,
    required bool refresh,
  }) async {
    final cache = await storage.load(groupId);
    final key = date.toIso8601String().substring(0, 10);

    bool needFetch = refresh || cache == null;

    if (!needFetch && cache != null) {
      final inRange =
          !date.isBefore(cache.start) &&
              !date.isAfter(cache.end);

      needFetch = !inRange;
    }

    if (needFetch) {
      // ⚠️ ВАЖНО: фиксированный диапазон, а не плавающий
      final start = _normalizeDate(date.subtract(const Duration(days: 3)));
      final end = _normalizeDate(date.add(const Duration(days: 3)));

      debugPrint("📦 Fetch range: $start - $end (refresh=$refresh)");

      final lessons = await api.fetchLessons(
        groupId: groupId,
        start: start,
        end: end,
      );

      final days = <String, List<Lesson>>{};

      for (final l in lessons) {
        final d = _key(l.date);
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
    }

    final newCache = await storage.load(groupId);
    return newCache?.days[key] ?? [];
  }

  String _key(DateTime d) => d.toIso8601String().substring(0, 10);

  DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}
