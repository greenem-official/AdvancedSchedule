import 'dart:convert';
import 'dart:io';
import 'package:flutter7/data/blacklist/categories.dart';
import 'package:path_provider/path_provider.dart';

class CategoryStorage {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/AdvancedSchedule');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/categories.json');
  }

  Future<List<Category>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];

    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as List;
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<void> save(List<Category> categories) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode(categories.map((e) => e.toJson()).toList()),
    );
  }
}
