dynamic getByPath(dynamic json, String path) {
  final parts = path.split('.');
  return _walk(json, parts);
}

dynamic _walk(dynamic current, List<String> parts) {
  if (current == null || parts.isEmpty) return current;

  final part = parts.first;
  final rest = parts.skip(1).toList();

  // wildcard: groups[*].name
  if (part.endsWith('[*]')) {
    final key = part.substring(0, part.length - 3);
    final list = current[key];
    if (list is List) {
      return list.map((e) => _walk(e, rest)).toList();
    }
    return null;
  }

  if (current is Map<String, dynamic>) {
    return _walk(current[part], rest);
  }

  if (current is List) {
    return current.map((e) => _walk(e, parts)).toList();
  }

  return null;
}
