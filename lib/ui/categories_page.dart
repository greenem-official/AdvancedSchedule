import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/blacklist/categories.dart';

class CategoriesPage extends StatefulWidget {
  final CategoryRepository categoryRepo;

  const CategoriesPage({super.key, required this.categoryRepo});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category> categories = [];
  Category? selectedCategory;
  List<CategoryRule> rules = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    categories = await widget.categoryRepo.getAllCategories();
    if (categories.isNotEmpty) {
      selectedCategory ??= categories.first;
      await loadRules();
    }
    setState(() {});
  }

  Future<void> loadRules() async {
    if (selectedCategory == null) return;
    rules = widget.categoryRepo.getRules(selectedCategory!.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupRulesByField(rules);

    return Scaffold(
      appBar: AppBar(title: const Text("Категории и правила")),
      body: Row(
        children: [
          // ===== LEFT SIDEBAR =====
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                right: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: ListView(
              children: categories.map((c) {
                final selected = selectedCategory?.id == c.id;
                return ListTile(
                  title: Text(c.title),
                  selected: selected,
                  onTap: () async {
                    selectedCategory = c;
                    await loadRules();
                  },
                );
              }).toList(),
            ),
          ),

          // ===== RIGHT CONTENT =====
          Expanded(
            child: selectedCategory == null
                ? const Center(child: Text("Нет категорий"))
                : rules.isEmpty
                ? const Center(child: Text("В этой категории нет правил"))
                : ListView(
              padding: const EdgeInsets.all(12),
              children: grouped.entries.map((entry) {
                final fieldKey = entry.key;
                final fieldRules = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      fieldKey,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: fieldRules.map((r) {
                      return ListTile(
                        title: Text(r.display.value.toString()),
                        subtitle: Text(r.unique.value.toString()), // Text(r.op.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await widget.categoryRepo.removeRule(
                              categoryId: selectedCategory!.id,
                              ruleId: r.id,
                            );
                            await loadRules();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, List<CategoryRule>> groupRulesByField(List<CategoryRule> rules) {
  final map = <String, List<CategoryRule>>{};
  for (final r in rules) {
    final key = r.fieldId;
    map.putIfAbsent(key, () => []).add(r);
  }
  return map;
}
