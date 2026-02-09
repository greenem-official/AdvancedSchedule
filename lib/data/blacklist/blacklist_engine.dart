import 'package:flutter7/data/blacklist/blacklist_rule.dart';
import 'package:flutter7/data/blacklist/json_path.dart';

class BlacklistEngine {
  bool match(Map<String, dynamic> raw, BlacklistRule rule) {
    final value = getByPath(raw, rule.path);

    if (value is List) {
      return value.any((v) => _matchValue(v, rule));
    }

    return _matchValue(value, rule);
  }

  bool _matchValue(dynamic value, BlacklistRule rule) {
    if (value == null) return false;
    final str = value.toString();

    switch (rule.op) {
      case BlacklistOp.equals:
        return str == rule.value;
      case BlacklistOp.contains:
        return str.contains(rule.value);
      case BlacklistOp.regex:
        return RegExp(rule.value).hasMatch(str);
    }
  }
}
