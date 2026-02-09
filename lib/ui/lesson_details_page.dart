import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/blacklist_repository.dart';
import '../models/lesson.dart';

class LessonDetailPage extends StatelessWidget {
  final Lesson lesson;
  const LessonDetailPage({super.key, required this.lesson});

  void addToBlacklist(String path, dynamic value) {
    // Blacklist().add(path, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Аудитория: ${lesson.room}"),
          Text("Начало: ${lesson.beginTime.hour}:${lesson.beginTime.minute.toString().padLeft(2,'0')}"),
          Text("Конец: ${lesson.endTime.hour}:${lesson.endTime.minute.toString().padLeft(2,'0')}"),
          const Divider(),
          ...lesson.raw.entries.map((e) {
            if (e.key == 'date' || e.key == 'beginLesson' || e.key == 'endLesson') return SizedBox.shrink();
            return ListTile(
              title: Text("${e.key}: ${e.value}"),
              trailing: IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () {
                  addToBlacklist(e.key, e.value);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
