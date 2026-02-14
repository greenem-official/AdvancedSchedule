import 'dart:io';
import 'dart:convert';
import 'package:flutter7/models/cache.dart';
import 'package:path_provider/path_provider.dart';

class ScheduleStorage {
  Future<File> _file(String groupId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/AdvancedSchedule');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/schedule_group_$groupId.json');
  }

  Future<ScheduleCache?> load(String groupId) async {
    final file = await _file(groupId);
    if (!await file.exists()) return null;

    final jsonStr = await file.readAsString();
    return ScheduleCache.fromJson(jsonDecode(jsonStr));
  }

  Future<void> save(ScheduleCache cache) async {
    final file = await _file(cache.groupId);
    await file.writeAsString(jsonEncode(cache.toJson()));
  }
}
