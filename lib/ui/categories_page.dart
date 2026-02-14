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

  void _addCategoryPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Добавление категории — placeholder")),
    );
  }

  void _editCategoryPlaceholder(Category c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Редактирование '${c.title}' — placeholder")),
    );
  }

  void _deleteCategoryPlaceholder(Category c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Удаление '${c.title}' — placeholder")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupRulesByField(rules);

    return Scaffold(
      appBar: AppBar(title: const Text("Категории и правила")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;

          return Row(
            children: [
              if (!isMobile) _sidebar(),
              Expanded(child: _content(grouped)),
            ],
          );
        },
      ),
    );
  }

  // ================= SIDEBAR =================

  Widget _sidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Row(
              children: [
                const Text(
                  "Категории",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: "Добавить категорию",
                  onPressed: _addCategoryPlaceholder,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: categories.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = categories.removeAt(oldIndex);
                  categories.insert(newIndex, item);
                });

                // TODO: сохранить порядок в repo
              },
              itemBuilder: (context, index) {
                final c = categories[index];
                final selected = selectedCategory?.id == c.id;

                return Material(
                  key: ValueKey(c.id),
                  color: selected
                      ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.55)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      selectedCategory = c;
                      await loadRules();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator,
                              size: 18,
                              color: Colors.grey.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.folder_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (value) {
                              if (value == "edit") {
                                _editCategoryPlaceholder(c);
                              } else if (value == "delete") {
                                _deleteCategoryPlaceholder(c);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: "edit",
                                child: Text("Редактировать"),
                              ),
                              PopupMenuItem(
                                value: "delete",
                                child: Text("Удалить"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTENT =================

  Widget _content(Map<String, List<CategoryRule>> grouped) {
    if (selectedCategory == null) {
      return const Center(child: Text("Нет категорий"));
    }

    if (rules.isEmpty) {
      return const Center(child: Text("В этой категории нет правил"));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        final fieldKey = entry.key;
        final fieldRules = entry.value;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              fieldKey,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: fieldRules.map((r) {
              return ListTile(
                title: Text(r.display.value.toString()),
                subtitle: Text(r.unique.value.toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
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
