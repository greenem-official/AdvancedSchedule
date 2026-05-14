// smart_cache_manager.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter7/data/repository.dart';

class SmartCacheManager {
  final ScheduleRepository repo;
  final Map<String, DateTime> _lastPreload = {};

  SmartCacheManager({required this.repo});

  /// Предзагружает диапазон вокруг даты, если давно не грузили
  Future<void> preloadIfNeeded({
    required String groupId,
    required DateTime center,
    int halfRange = 7,
    Duration minInterval = const Duration(minutes: 5),
  }) async {
    final now = DateTime.now();
    final last = _lastPreload[groupId];

    // не грузим слишком часто
    if (last != null && now.difference(last) < minInterval) {
      debugPrint("⏭️ Skip preload for $groupId, last was ${now.difference(last).inSeconds}s ago");
      return;
    }

    _lastPreload[groupId] = now;

    // сначала проверяем кеш
    final cache = await repo.storage.load(groupId);
    if (cache != null) {
      final inRange = !center.isBefore(cache.start) && !center.isAfter(cache.end);
      if (inRange) {
        debugPrint("Cache already covers $center");
        return;
      }
    }

    // Загружаем в фоне, не блокируя UI
    await repo.fetchRange(
      groupId: groupId,
      center: center,
      halfRange: halfRange,
      force: false,
    );
  }
}