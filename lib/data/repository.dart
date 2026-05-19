// repository.dart (полностью новый)
import 'package:flutter/cupertino.dart';
import 'package:flutter7/api/api_client.dart';
import 'package:flutter7/data/cache_policy.dart';
import 'package:flutter7/data/file_cache.dart';
import 'package:flutter7/models/cache.dart';
import 'package:flutter7/models/lesson.dart';

class ScheduleRepository {
  final api = ScheduleApi();
  final storage = ScheduleStorage();

  // защита от повторных запросов
  String? _lastFetchedRange;
  final Map<String, Future<List<Lesson>>> _pendingRequests = {};

  /// Загружает уроки за конкретный день (из кеша или API)
  Future<List<Lesson>> getDay({
    required String id,
    required DateTime date,
    required bool refresh,
    ScheduleType type = ScheduleType.group,
  }) async {
    final key = date.toIso8601String().substring(0, 10);
    final requestKey = '$id-${type.name}-$key-$refresh';

    if (_pendingRequests.containsKey(requestKey)) {
      return _pendingRequests[requestKey]!;
    }

    final future = _getDayInternal(
      id: id,
      date: date,
      refresh: refresh,
      dayKey: key,
      type: type,
    );

    _pendingRequests[requestKey] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  Future<List<Lesson>> _getDayInternal({
    required String id,
    required DateTime date,
    required bool refresh,
    required String dayKey,
    required ScheduleType type,
  }) async {
    final cache = await storage.load(id);
    final key = date.toIso8601String().substring(0, 10);

    bool needFetch = refresh || cache == null;

    if (!needFetch && cache != null) {
      final inRange =
          !date.isBefore(cache.start) && !date.isAfter(cache.end);

      needFetch = !inRange;
    }

    if (needFetch) {
      final start = _normalizeDate(date.subtract(const Duration(days: 3)));
      final end = _normalizeDate(date.add(const Duration(days: 3)));

      debugPrint("Fetch range: $start - $end (refresh=$refresh, type=${type.name})");

      final lessons = await api.fetchLessons(
        id: id,
        start: start,
        end: end,
        type: type,
      );

      final days = <String, List<Lesson>>{};

      for (final l in lessons) {
        final d = _key(l.date);
        days.putIfAbsent(d, () => []).add(l);
      }

      final newCache = ScheduleCache(
        groupId: id,
        lastUpdated: DateTime.now(),
        start: start,
        end: end,
        days: days,
      );

      await storage.save(newCache);
    }

    final newCache = await storage.load(id);
    return newCache?.days[key] ?? [];
  }

  // Для обратной совместимости
  Future<List<Lesson>> getDayForGroup({
    required String groupId,
    required DateTime date,
    required bool refresh,
  }) async {
    return getDay(
      id: groupId,
      date: date,
      refresh: refresh,
      type: ScheduleType.group,
    );
  }

  Future<void> getLessonsForRange({
    required String id,
    required DateTime start,
    required DateTime end,
    ScheduleType type = ScheduleType.group,
  }) async {
    debugPrint("Fetching range: $start - $end (type=${type.name})");

    final lessons = await api.fetchLessons(
      id: id,
      start: start,
      end: end,
      type: type,
    );

    final days = <String, List<Lesson>>{};

    for (final l in lessons) {
      final d = _key(l.date);
      days.putIfAbsent(d, () => []).add(l);
    }

    final newCache = ScheduleCache(
      groupId: id,
      lastUpdated: DateTime.now(),
      start: start,
      end: end,
      days: days,
    );

    await storage.save(newCache);
  }

  String _key(DateTime d) => d.toIso8601String().substring(0, 10);

  DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}