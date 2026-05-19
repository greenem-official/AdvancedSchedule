import 'package:flutter/cupertino.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/api/api_client.dart';

class SmartCacheManager {
  final ScheduleRepository repo;
  final Map<String, DateTime> _lastPreload = {};

  SmartCacheManager({required this.repo});

  /// Предзагружает диапазон вокруг даты, если давно не грузили
  Future<void> preloadIfNeeded({
    required String id,
    required DateTime center,
    int halfRange = 7,
    Duration minInterval = const Duration(minutes: 5),
    ScheduleType type = ScheduleType.group,
  }) async {
    final now = DateTime.now();
    final cacheKey = '${type.name}_$id';
    final last = _lastPreload[cacheKey];

    // не грузим слишком часто
    if (last != null && now.difference(last) < minInterval) {
      debugPrint("Skip preload for $cacheKey, last was ${now.difference(last).inSeconds}s ago");
      return;
    }

    _lastPreload[cacheKey] = now;

    // сначала проверяем кеш
    final cache = await repo.storage.load(id);
    if (cache != null) {
      final inRange = !center.isBefore(cache.start) && !center.isAfter(cache.end);
      if (inRange) {
        debugPrint("Cache already covers $center");
        return;
      }
    }

    // Загружаем диапазон в фоне через репозиторий
    final start = center.subtract(Duration(days: halfRange));
    final end = center.add(Duration(days: halfRange));

    try {
      await repo.getLessonsForRange(
        id: id,
        start: start,
        end: end,
        type: type,
      );
    } catch (e) {
      debugPrint("Preload failed for $cacheKey: $e");
    }
  }
}