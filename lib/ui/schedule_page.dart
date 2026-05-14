import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/category_engine.dart';
import 'package:flutter7/data/blacklist/category_repository.dart';
import 'package:flutter7/data/blacklist/categories.dart';
import 'package:flutter7/data/constants.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/data/smart_cache_manager.dart';
import 'package:flutter7/ui/lesson_details_page.dart';
import '../models/lesson.dart';

class SchedulePageContent extends StatefulWidget {
  final ScheduleRepository repo;
  final CategoryRepository categoryRepo;
  final String groupId; // передаём извне
  final String? title; // опциональный заголовок
  final bool showAppBar; // для встраивания без AppBar

  const SchedulePageContent({
    super.key,
    required this.repo,
    required this.categoryRepo,
    required this.groupId,
    this.title,
    this.showAppBar = true,
  });

  @override
  State<SchedulePageContent> createState() => _SchedulePageContentState();
}


class _SchedulePageContentState extends State<SchedulePageContent> {
  final categoryEngine = CategoryEngine();
  late final SmartCacheManager cacheManager;

  String get groupId => widget.groupId;
  DateTime selectedDate = DateTime.now();

  bool loading = false;
  String? error;
  List<Lesson> lessons = [];

  DateTime get weekStart => selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  List<DateTime> get weekDays => List.generate(7, (i) => weekStart.add(Duration(days: i)));

  bool showBlacklisted = false;
  bool fabOpen = false;

  @override
  void initState() {
    super.initState();
    // cacheManager = SmartCacheManager(repo: widget.repo);
    loadDay(selectedDate);
  }

  @override
  void didUpdateWidget(SchedulePageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      loadDay(selectedDate);
    }
  }

  // Future<void> loadBlacklist() async {
  //   blacklistRules = await blacklistRepo.getAll();
  //   setState(() {}); // чтобы перерисовать карточки с кнопками
  // }

  Future<void> refreshWeek() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // один вызов с force=true
      await widget.repo.getDay(
        groupId: groupId,
        date: selectedDate,
        refresh: true,
      );

      await loadDay(selectedDate);
    } catch (e, stack) {
      debugPrint("Ошибка обновления: $e\n$stack");
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> loadDay(DateTime day) async {
    if (loading) return;

    setState(() {
      loading = true;
      error = null;
      selectedDate = day; // сразу обновляем дату
    });

    try {
      // один вызов, который сам решит нужна ли загрузка
      final data = await widget.repo.getDay(
        groupId: groupId,
        date: day,
        refresh: false,
      );

      if (!mounted) return;

      setState(() {
        lessons = data;
      });

      await updateFilteredLessons();

    } catch (e, stack) {
      if (!mounted) return;
      setState(() {
        debugPrint("Ошибка загрузки дня: $e\n$stack");
        error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  void changeDay(int offset) {
    final newDate = selectedDate.add(Duration(days: offset));
    loadDay(newDate);
  }

  void changeWeek(int offset) {
    final newDate = selectedDate.add(Duration(days: offset * 7));
    loadDay(newDate);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null) {
      setState(() => selectedDate = date);
      loadDay(date);
    }
  }

  String formatWeekRange(DateTime start) {
    final end = start.add(const Duration(days: 6));

    String monthName(int month) {
      const names = [
        '', // индекс 0
        'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      return names[month];
    }

    if (start.month == end.month) {
      // один месяц
      return "${start.day}–${end.day} ${monthName(start.month)}";
    } else {
      // разные месяцы
      return "${start.day} ${monthName(start.month)} – ${end.day} ${monthName(end.month)}";
    }
  }

  String getLessonNumber(DateTime beginTime) {
    // эталонные времена начала пар
    final lessonTimes = [
      const Duration(hours: 8, minutes: 30),
      const Duration(hours: 10, minutes: 10),
      const Duration(hours: 11, minutes: 50),
      const Duration(hours: 14, minutes: 0),
      const Duration(hours: 15, minutes: 40),
      const Duration(hours: 17, minutes: 20),
      const Duration(hours: 18, minutes: 55),
      const Duration(hours: 20, minutes: 30),
    ];

    final t = Duration(hours: beginTime.hour, minutes: beginTime.minute);

    for (int i = 0; i < lessonTimes.length; i++) {
      if (t == lessonTimes[i]) return "$i";
      if (i > 0 && t > lessonTimes[i - 1] && t < lessonTimes[i]) {
        return "${i - 1}*"; // между предыдущей и текущей
      }
    }

    if (t < lessonTimes[0]) return "0*"; // до первой пары
    return "${lessonTimes.length - 1}*"; // после последней пары
  }

  Future<bool> checkLessonBlacklisted(Lesson l) async {
    bool result = categoryEngine.matchCategory(l.raw, (await widget.categoryRepo.getCategoryByTitleAsync("blacklist"))!);
    // debugPrint("${l.title} blacklisted: ${result}");
    return result;
  }

  List<Lesson> filteredLessons = [];

  Future<void> updateFilteredLessons() async {
    if (showBlacklisted) {
      filteredLessons = List.from(lessons);
    } else {
      final results = await Future.wait(
        lessons.map((l) async => (await checkLessonBlacklisted(l)) ? null : l),
      );
      filteredLessons = results.whereType<Lesson>().toList();
    }
    setState(() {});
  }

  // schedule_page.dart - метод build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: Text(widget.title ?? "Расписание"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Обновить неделю",
            onPressed: loading ? null : refreshWeek,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDate,
          ),
        ],
      ) : null,

      // Оборачиваем ВЕСЬ body в GestureDetector для свайпов
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;

          if (details.primaryVelocity! > 100) {
            // Свайп вправо - предыдущий день
            changeDay(-1);
          } else if (details.primaryVelocity! < -100) {
            // Свайп влево - следующий день
            changeDay(1);
          }
        },
        child: Column(
          children: [
            // ===== WEEK HEADER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => changeWeek(-1),
                  ),
                  Text(
                    formatWeekRange(weekStart),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => changeWeek(1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ===== DAYS STRIP =====
            buildWeekStrip(),

            const SizedBox(height: 10),

            // ===== STATUS BAR =====
            if (loading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),

            if (error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Ошибка: $error",
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // ===== LESSONS LIST =====
            Expanded(
              child: filteredLessons.isEmpty
                  ? const Center(child: Text("Нет занятий"))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredLessons.length,
                itemBuilder: (context, i) {
                  final l = filteredLessons[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonDetailPage(
                            lesson: l,
                            categoryRepo: widget.categoryRepo,
                            fieldDefs: fieldDefs,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Center(
                              child: Text(
                                getLessonNumber(l.beginTime),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: l.lessonType.color,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l.lessonType.displayName,
                                        style: const TextStyle(
                                          color: Color(0xFFFFFFFF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${l.beginTime.hour.toString().padLeft(2, '0')}:${l.beginTime.minute.toString().padLeft(2, '0')} - "
                                          "${l.endTime.hour.toString().padLeft(2, '0')}:${l.endTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1565C0),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Ауд. ${l.room}",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (fabOpen) ...[
            FloatingActionButton.small(
              heroTag: "fabBlacklist",
              onPressed: () {
                setState(() {
                  showBlacklisted = !showBlacklisted;
                });
                updateFilteredLessons();
              },
              child: Icon(
                showBlacklisted ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            const SizedBox(height: 8),

            FloatingActionButton.small(
              heroTag: "fabSync",
              onPressed: refreshWeek,
              child: const Icon(Icons.sync),
            ),
            const SizedBox(height: 8),
          ],

          FloatingActionButton(
            heroTag: "fabMore",
            onPressed: () {
              setState(() {
                fabOpen = !fabOpen;
              });
            },
            child: Icon(fabOpen ? Icons.close : Icons.more_vert),
          ),
        ],
      ),
    );
  }

  // ===== WEEK STRIP =====
  Widget buildWeekStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final stripWidth = screenWidth * 0.7;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: stripWidth,
              maxWidth: screenWidth,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = weekDays[index];
                final active = isSameDay(date, selectedDate);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      selectedDate = date;
                      loadDay(date);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? Colors.blue.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? Colors.blue : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"][index],
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            "${date.day}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
