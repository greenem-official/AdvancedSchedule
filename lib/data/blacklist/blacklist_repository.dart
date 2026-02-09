import 'package:flutter7/data/blacklist/blacklist_rule.dart';
import 'package:flutter7/data/blacklist/blacklist_storage.dart';
import 'package:uuid/uuid.dart';

class BlacklistRepository {
  final storage = BlacklistStorage();
  final _uuid = const Uuid();

  List<BlacklistRule>? _cache;

  Future<List<BlacklistRule>> getAll() async {
    _cache ??= await storage.load();
    return _cache!;
  }

  Future<void> addRule({
    required String path,
    required BlacklistOp op,
    required String value,
  }) async {
    final rules = await getAll();

    rules.add(
      BlacklistRule(
        id: _uuid.v4(),
        path: path,
        op: op,
        value: value,
        createdAt: DateTime.now(),
      ),
    );

    await storage.save(rules);
  }

  Future<void> removeRule(String id) async {
    final rules = await getAll();
    rules.removeWhere((r) => r.id == id);
    await storage.save(rules);
  }
}
