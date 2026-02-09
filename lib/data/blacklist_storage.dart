import 'dart:convert';
import 'dart:io';
import 'package:flutter7/data/blacklist_rule.dart';
import 'package:path_provider/path_provider.dart';

class BlacklistStorage {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/blacklist.json');
  }

  Future<List<BlacklistRule>> load() async {
    final file = await _file();
    if (!await file.exists()) return [];

    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as List;
    return data.map((e) => BlacklistRule.fromJson(e)).toList();
  }

  Future<void> save(List<BlacklistRule> rules) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(rules.map((e) => e.toJson()).toList()));
  }
}
