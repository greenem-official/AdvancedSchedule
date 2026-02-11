import 'package:flutter7/data/blacklist/categories.dart';
import 'package:flutter7/data/blacklist/json_path.dart';

class CategoryEngine {
  bool match(Map<String, dynamic> raw, CategoryRule rule) {
    final field = fieldMap[rule.fieldId];
    if (field == null) return false;

    final value = getByPath(raw, field.uniquePath);

    if (value is List) {
      return value.any((v) => _matchValue(v, rule));
    }

    return _matchValue(value, rule);
  }

  bool matchCategory(Map<String, dynamic> raw, Category category) {
    for (final rule in category.rules) {
      if (match(raw, rule)) return true;
    }
    return false;
  }

  bool _matchValue(dynamic value, CategoryRule rule) {
    if (value == null) return false;
    final str = value.toString();

    switch (rule.op) {
      case CategoryOp.equals:
        return str == rule.unique.value;
      case CategoryOp.contains:
        return str.contains(rule.unique.value);
      case CategoryOp.regex:
        return RegExp(rule.unique.value).hasMatch(str);
    }
  }
}
