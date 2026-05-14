import 'package:flutter/material.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/smart_cache_manager.dart';

/// Виджет-обёртка для создания независимого экземпляра расписания
class ScheduleScope extends StatefulWidget {
  final String groupId;
  final String? title;
  final Widget Function(ScheduleRepository repo, CategoryRepository categoryRepo) builder;

  const ScheduleScope({
    super.key,
    required this.groupId,
    this.title,
    required this.builder,
  });

  @override
  State<ScheduleScope> createState() => _ScheduleScopeState();
}

class _ScheduleScopeState extends State<ScheduleScope> {
  late final ScheduleRepository repo;
  late final CategoryRepository categoryRepo;

  @override
  void initState() {
    super.initState();
    // каждый ScheduleScope получает СВОЙ экземпляр репозиториев
    // если вы хотите делить кеш между экземплярами - передайте их сюда
    repo = ScheduleRepository();
    categoryRepo = CategoryRepository();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(repo, categoryRepo);
  }
}

// Использование:
// ScheduleScope(
//   groupId: "123456",
//   builder: (repo, catRepo) => SchedulePageContent(
//     repo: repo,
//     categoryRepo: catRepo,
//     groupId: "123456",
//   ),
// )