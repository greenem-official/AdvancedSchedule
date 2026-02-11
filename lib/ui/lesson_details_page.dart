import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/category_engine.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/blacklist/categories.dart';
import 'package:flutter7/data/blacklist/json_path.dart';
import '../models/lesson.dart';

class LessonDetailPage extends StatefulWidget {
  final Lesson lesson;
  final CategoryRepository categoryRepo;
  final List<FieldDef> fieldDefs; // заранее подготовленные поля

  const LessonDetailPage({
    super.key,
    required this.lesson,
    required this.categoryRepo,
    required this.fieldDefs,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  final engine = CategoryEngine();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: widget.fieldDefs.map((f) {
            final raw = widget.lesson.raw;
            final uniqueValue = getByPath(raw, f.uniquePath)?.toString() ?? "—";
            final displayValue = getByPath(raw, f.displayPath)?.toString() ?? "—";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(displayValue, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(uniqueValue, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddToCategory(f, uniqueValue, displayValue),
                      icon: const Icon(Icons.add),
                      label: const Text("Добавить в категорию"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade300,
                        minimumSize: const Size.fromHeight(36),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddToCategory(FieldDef field, String uniqueValue, String displayValue) async {
    // Получаем все категории
    final categories = await widget.categoryRepo.getAllCategories();

    // Показать меню выбора категории
    final selectedCategoryId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((c) {
            return ListTile(
              title: Text(c.title == "blacklist" ? "Чёрный список" : c.title),
              onTap: () => Navigator.of(ctx).pop(c.id),
            );
          }).toList(),
        );
      },
    );

    if (selectedCategoryId == null) return;

    // Добавляем правило в выбранную категорию
    await widget.categoryRepo.addRule(
      categoryId: selectedCategoryId,
      fieldId: field.id,
      op: CategoryOp.equals,
      unique: JsonEntry(path: field.uniquePath, value: uniqueValue),
      display: JsonEntry(path: field.displayPath, value: displayValue),
    );


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${field.title} добавлено в категорию')),
    );
  }
}
