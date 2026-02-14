enum CategoryOp {
  equals,
  contains,
  regex,
}

class FieldDef {
  final String id;          // "discipline", "teacher", "room"
  final String uniquePath;  // "discipline.name"
  final String displayPath; // "discipline.name" или другое
  final String title;       // "Дисциплина"

  const FieldDef({
    required this.id,
    required this.uniquePath,
    required this.displayPath,
    required this.title,
  });
}

class Category {
  final String id;        // system id: "blacklist", "favorites", "hidden", etc
  final String title;     // отображаемое имя (локализуешь в UI)
  final List<CategoryRule> rules;

  Category({
    required this.id,
    required this.title,
    required this.rules,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    title: json['title'],
    rules: (json['rules'] as List)
        .map((e) => CategoryRule.fromJson(e))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'rules': rules.map((e) => e.toJson()).toList(),
  };
}

class JsonEntry {
  final String path;
  final String value;

  const JsonEntry({
    required this.path,
    required this.value,
  });

  factory JsonEntry.fromJson(Map<String, dynamic> json) => JsonEntry(
    path: json['path'],
    value: json['value'],
  );

  Map<String, dynamic> toJson() => {
    'path': path,
    'value': value,
  };
}

class CategoryRule {
  final String id;
  final String fieldId;
  final CategoryOp op;
  final JsonEntry unique;   // уникальное значение
  final JsonEntry display;  // отображаемое значение
  final DateTime createdAt;

  CategoryRule({
    required this.id,
    required this.fieldId,
    required this.op,
    required this.unique,
    required this.display,
    required this.createdAt,
  });

  factory CategoryRule.fromJson(Map<String, dynamic> json) => CategoryRule(
    id: json['id'],
    fieldId: json['fieldId'],
    op: CategoryOp.values.firstWhere((e) => e.name == json['op']),
    unique: JsonEntry.fromJson(json['unique']),
    display: JsonEntry.fromJson(json['display']),
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fieldId': fieldId,
    'op': op.name,
    'unique': unique.toJson(),
    'display': display.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };
}
