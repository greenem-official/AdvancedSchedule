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
  final Map<String, Future<void>> _pendingRangeFetches = {};

  /// Загружает уроки за конкретный день (из кеша или API)
  Future<List<Lesson>> getDay({
    required String groupId,
    required DateTime date,
    required bool refresh,
  }) async {
    final cache = await storage.load(groupId);
    final key = _key(date);

    bool needFetch = refresh || cache == null;

    if (!needFetch && cache != null) {
      final inRange =
          !date.isBefore(cache.start) &&
              !date.isAfter(cache.end);
      needFetch = !inRange;
    }

    if (needFetch) {
      // загружаем большой диапазон
      await fetchRange(
        groupId: groupId,
        center: date,
        force: refresh,
      );
    }

    final newCache = await storage.load(groupId);
    return newCache?.days[key] ?? [];
  }

  /// Загружает диапазон дней ±halfRange вокруг center
  Future<void> fetchRange({
    required String groupId,
    required DateTime center,
    int halfRange = 14, // было 7, теперь ±14 дней = 29 дней всего
    bool force = false,
  }) async {
    final start = _normalizeDate(center.subtract(Duration(days: halfRange)));
    final end = _normalizeDate(center.add(Duration(days: halfRange)));

    final rangeKey = '$start-$end';

    // если такой диапазон уже грузится - ждём
    if (_pendingRangeFetches.containsKey(rangeKey)) {
      debugPrint("⏳ Range $rangeKey already loading, waiting...");
      await _pendingRangeFetches[rangeKey]!;
      return;
    }

    // если уже загружали этот диапазон и не force - пропускаем
    if (!force && _lastFetchedRange == rangeKey) {
      debugPrint("Range $rangeKey already fetched");
      return;
    }

    final future = _doFetchRange(groupId: groupId, start: start, end: end);
    _pendingRangeFetches[rangeKey] = future;

    try {
      await future;
      _lastFetchedRange = rangeKey;
    } finally {
      _pendingRangeFetches.remove(rangeKey);
    }
  }

  Future<void> _doFetchRange({
    required String groupId,
    required DateTime start,
    required DateTime end,
  }) async {
    debugPrint("📦 Fetch range: $start - $end");

    final lessons = await api.fetchLessons(
      groupId: groupId,
      start: start,
      end: end,
    );

    // Группируем по дням
    final days = <String, List<Lesson>>{};
    for (final l in lessons) {
      final d = _key(l.date);
      days.putIfAbsent(d, () => []).add(l);
    }

    // объединяем с существующим кешем, а не перезаписываем
    final existingCache = await storage.load(groupId);
    if (existingCache != null) {
      // Добавляем старые дни, которых нет в новой загрузке
      for (final entry in existingCache.days.entries) {
        if (!days.containsKey(entry.key)) {
          days[entry.key] = entry.value;
        }
      }
    }

    final newCache = ScheduleCache(
      groupId: groupId,
      lastUpdated: DateTime.now(),
      start: start,
      end: end,
      days: days,
    );

    await storage.save(newCache);
    debugPrint("💾 Cache saved: ${days.length} days, ${lessons.length} lessons");

    // очищаем старые дни в фоне
    Future.microtask(() async {
      await cleanupCache(
        groupId: groupId,
        center: start.add(Duration(days: (end.difference(start).inDays / 2).round())),
      );
    });
  }

  String _key(DateTime d) => d.toIso8601String().substring(0, 10);

  DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  Future<void> cleanupCache({
    required String groupId,
    required DateTime center,
  }) async {
    final cache = await storage.load(groupId);
    if (cache == null) return;

    final days = Map<String, List<Lesson>>.from(cache.days);
    final entries = days.entries.toList();

    // Сортируем: сначала самые далёкие от centre
    entries.sort((a, b) {
      final dateA = DateTime.tryParse(a.key) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.key) ?? DateTime(2000);
      final diffA = dateA.difference(center).abs();
      final diffB = dateB.difference(center).abs();
      return diffB.compareTo(diffA); // дальние сверху
    });

    int kept = 0;
    final toKeep = <String, List<Lesson>>{};
    final now = DateTime.now();

    for (final entry in entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;

      // Всегда сохраняем дни в защищённом радиусе
      if (date.difference(center).inDays.abs() <= CachePolicy.protectedRadius) {
        toKeep[entry.key] = entry.value;
        kept++;
        continue;
      }

      // Всегда сохраняем будущие дни в пределах keepFutureDays
      if (date.isAfter(now) &&
          date.difference(now).inDays <= CachePolicy.keepFutureDays) {
        toKeep[entry.key] = entry.value;
        kept++;
        continue;
      }

      // Всегда сохраняем недавние прошлые дни
      if (date.isBefore(now) &&
          now.difference(date).inDays <= CachePolicy.keepPastDays) {
        toKeep[entry.key] = entry.value;
        kept++;
        continue;
      }

      // Остальное сохраняем пока не превысили лимит
      if (kept < CachePolicy.maxCachedDays) {
        toKeep[entry.key] = entry.value;
        kept++;
      }
    }

    final removed = days.length - toKeep.length;
    if (removed > 0) {
      debugPrint("🧹 Cleanup: removed $removed days, kept ${toKeep.length}");

      final cleanedCache = ScheduleCache(
        groupId: cache.groupId,
        lastUpdated: cache.lastUpdated,
        start: cache.start,
        end: cache.end,
        days: toKeep,
      );

      await storage.save(cleanedCache);
    }
  }
}