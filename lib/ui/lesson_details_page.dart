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
            final uniqueValue = getByPath(raw, f.uniquePath)?.toString();
            final displayValue = getByPath(raw, f.displayPath)?.toString();

            // Если нет display и unique, пропускаем
            if ((uniqueValue == null || uniqueValue.isEmpty) &&
                (displayValue == null || displayValue.isEmpty)) {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Info =====
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          if (displayValue != null && displayValue.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(displayValue,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                          if (uniqueValue != null && uniqueValue.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(uniqueValue,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ],
                      ),
                    ),

                    // ===== Add button =====
                    if ((uniqueValue != null && uniqueValue.isNotEmpty) ||
                        (displayValue != null && displayValue.isNotEmpty))
                      Material(
                        color: Colors.transparent,
                        child: IconButton(
                          onPressed: () => _showAddToCategory(f, uniqueValue ?? "", displayValue ?? ""),
                          icon: Icon(Icons.add_circle, color: Colors.blue.shade400, size: 28),
                          tooltip: "Добавить в категорию",
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
