import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/blacklist_engine.dart';
import 'package:flutter7/data/blacklist/blacklist_repository.dart';
import 'package:flutter7/data/blacklist/blacklist_rule.dart';
import 'package:flutter7/data/blacklist/json_path.dart';
import '../models/lesson.dart';

class LessonDetailPage extends StatefulWidget {
  final Lesson lesson;
  final BlacklistRepository blacklistRepo;

  const LessonDetailPage({
    super.key,
    required this.lesson,
    required this.blacklistRepo,
  });

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  List<BlacklistRule> blacklistRules = [];
  final engine = BlacklistEngine();

  @override
  void initState() {
    super.initState();
    loadRules();
  }

  Future<void> loadRules() async {
    blacklistRules = await widget.blacklistRepo.getAll();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final blacklistFields = [
      {"label": "Дисциплина", "path": "discipline"},
      {"label": "Группа", "path": "groupGUID"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // например, показываем базовые поля
            Text("Аудитория: ${widget.lesson.room}"),
            const SizedBox(height: 10),
            Text("Время: ${widget.lesson.beginTime} — ${widget.lesson.endTime}"),
            const SizedBox(height: 20),

            // кнопки блеклиста
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: blacklistFields.map((f) {
                final value = getByPath(widget.lesson.raw, f['path']!);
                final alreadyBlacklisted = blacklistRules.any(
                      (rule) => rule.path == f['path'] && rule.value == value?.toString(),
                );

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alreadyBlacklisted ? Colors.grey : Colors.red.shade300,
                  ),
                  onPressed: value == null || alreadyBlacklisted
                      ? null
                      : () async {
                    await widget.blacklistRepo.addRule(
                      path: f['path']!,
                      op: BlacklistOp.equals,
                      value: value.toString(),
                    );

                    // обновляем кэш
                    blacklistRules = await widget.blacklistRepo.getAll();
                    setState(() {});

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${f['label']} добавлено в блеклист')),
                    );
                  },
                  child: Text(f['label']!),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
