import 'dart:convert';

enum BlacklistOp {
  equals,
  contains,
  regex,
}

class BlacklistRule {
  final String id; // uuid или timestamp
  final String path; // например: "discipline.name" или "teacher[*].name"
  final BlacklistOp op;
  final String value;
  final DateTime createdAt;

  BlacklistRule({
    required this.id,
    required this.path,
    required this.op,
    required this.value,
    required this.createdAt,
  });

  factory BlacklistRule.fromJson(Map<String, dynamic> json) => BlacklistRule(
    id: json['id'],
    path: json['path'],
    op: BlacklistOp.values.firstWhere((e) => e.name == json['op']),
    value: json['value'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'op': op.name,
    'value': value,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  String toString() => jsonEncode(toJson());
}
