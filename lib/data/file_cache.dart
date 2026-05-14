// file_cache.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter7/models/cache.dart';
import 'package:path_provider/path_provider.dart';

class ScheduleStorage {
  // мьютекс для каждого файла
  final Map<String, Future<void>> _locks = {};

  Future<File> _file(String groupId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/AdvancedSchedule');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/schedule_group_$groupId.json');
  }

  /// Блокирует доступ к файлу на время операции
  Future<T> _withLock<T>(String groupId, Future<T> Function() action) async {
    // Ждём пока предыдущая операция с этим файлом завершится
    while (_locks.containsKey(groupId)) {
      await _locks[groupId];
    }

    final completer = Completer<void>();
    _locks[groupId] = completer.future;

    try {
      return await action();
    } finally {
      completer.complete();
      _locks.remove(groupId);
    }
  }

  Future<ScheduleCache?> load(String groupId) async {
    return _withLock(groupId, () async {
      try {
        final file = await _file(groupId);
        if (!await file.exists()) return null;

        final jsonStr = await file.readAsString();

        if (jsonStr.trim().isEmpty) {
          debugPrint("⚠️ Empty cache for $groupId, deleting...");
          try { await file.delete(); } catch (_) {}
          return null;
        }

        try {
          final decoded = jsonDecode(jsonStr);

          if (decoded is! Map<String, dynamic>) {
            debugPrint("⚠️ Invalid cache format for $groupId");
            try { await file.delete(); } catch (_) {}
            return null;
          }

          return ScheduleCache.fromJson(decoded);
        } on FormatException catch (e) {
          debugPrint("⚠️ Corrupted cache for $groupId: $e");
          try { await file.delete(); } catch (_) {}
          return null;
        }
      } catch (e) {
        debugPrint("⚠️ Error loading cache for $groupId: $e");
        return null;
      }
    });
  }

  Future<void> save(ScheduleCache cache) async {
    return _withLock(cache.groupId, () async {
      try {
        final file = await _file(cache.groupId);
        final jsonStr = jsonEncode(cache.toJson());

        // пишем напрямую, с flush
        await file.writeAsString(jsonStr, flush: true);

        debugPrint("💾 Cache saved: ${cache.days.length} days");
      } catch (e) {
        debugPrint("⚠️ Error saving cache: $e");
      }
    });
  }
}