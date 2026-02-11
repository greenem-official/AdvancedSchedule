import 'package:flutter/cupertino.dart';
import 'package:flutter7/data/blacklist/categories.dart';
import 'package:flutter7/data/blacklist/category_storage.dart';
import 'package:uuid/uuid.dart';

class CategoryRepository {
  final storage = CategoryStorage();
  final _uuid = const Uuid();

  List<Category>? _cache;
  final Map<String, List<CategoryRule>> _index = {};

  Future<List<Category>> getAllCategories() async {
    if (_cache == null) {
      _cache = await storage.load();
      _rebuildIndex();
    }
    return _cache!;
  }

  void _rebuildIndex() {
    _index.clear();

    final titles = <String>{};

    for (final c in _cache!) {
      if (titles.contains(c.title)) {
        debugPrint("⚠ Duplicate category title detected: ${c.title}");
      }
      titles.add(c.title);

      _index[c.id] = c.rules;
    }
  }

  List<CategoryRule> getRules(String categoryId) {
    return _index[categoryId] ?? [];
  }

  Future<Category?> getCategoryByIdAsync(String id) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Category?> getCategoryByTitleAsync(String title) async {
    final categories = await getAllCategories();
    try {
      return categories.firstWhere((c) => c.title == title);
    } catch (_) {
      return null;
    }
  }

  Future<void> addRule({
    required String categoryId,
    required String fieldId,
    required CategoryOp op,
    required JsonEntry unique,
    required JsonEntry display,
  }) async {
    final categories = await getAllCategories();

    final category = categories.firstWhere(
          (c) => c.id == categoryId,
      orElse: () {
        final c = Category(id: categoryId, title: categoryId, rules: []);
        categories.add(c);
        return c;
      },
    );

    category.rules.add(
      CategoryRule(
        id: _uuid.v4(),
        fieldId: fieldId,
        op: op,
        unique: unique,
        display: display,
        createdAt: DateTime.now(),
      ),
    );

    _rebuildIndex();
    await storage.save(categories);
  }

  Future<void> removeRule({
    required String categoryId,
    required String ruleId,
  }) async {
    final categories = await getAllCategories();

    final category = categories.firstWhere(
          (c) => c.id == categoryId,
      orElse: () => throw Exception("Category not found: $categoryId"),
    );

    category.rules.removeWhere((r) => r.id == ruleId);

    _rebuildIndex();
    await storage.save(categories);
  }

  Future<Category> addCategory({required String title}) async {
    final categories = await getAllCategories();

    final existing = categories.where((c) => c.title == title).toList();
    if (existing.isNotEmpty) {
      return existing.first; // exists already
    }

    final c = Category(
      id: _uuid.v4(),
      title: title,
      rules: [],
    );

    categories.add(c);
    _rebuildIndex();
    await storage.save(categories);

    return c;
  }

  Future<void> removeCategory(String categoryId) async {
    final categories = await getAllCategories();

    categories.removeWhere((c) => c.id == categoryId);

    _rebuildIndex();
    await storage.save(categories);
  }
}
