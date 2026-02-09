import 'package:flutter/material.dart';
import 'package:flutter7/data/blacklist/blacklist_engine.dart';
import 'package:flutter7/data/blacklist/blacklist_repository.dart';
import 'package:flutter7/data/blacklist/blacklist_rule.dart';
import 'package:flutter7/data/repository.dart';
import 'package:flutter7/ui/blacklist_page.dart';
import 'package:flutter7/ui/lesson_details_page.dart';
import '../models/lesson.dart';

class SchedulePageContent extends StatefulWidget {
  final ScheduleRepository repo;
  final BlacklistRepository blacklistRepo;

  const SchedulePageContent({
    super.key,
    required this.repo,
    required this.blacklistRepo,
  });

  @override
  State<SchedulePageContent> createState() => _SchedulePageContentState();
}


class _SchedulePageContentState extends State<SchedulePageContent> {
  final String groupId = "154481"; // хардкод, потом настройки
  DateTime selectedDate = DateTime.now();

  bool loading = false;
  String? error;
  List<Lesson> lessons = [];

  DateTime get weekStart => selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  List<DateTime> get weekDays => List.generate(7, (i) => weekStart.add(Duration(days: i)));

  @override
  void initState() {
    super.initState();
    loadDay(selectedDate);
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
      final start = weekStart.subtract(const Duration(days: 3));
      final end = weekStart.add(const Duration(days: 9));

      await widget.repo.getDay(
        groupId: groupId,
        date: selectedDate,
        refresh: true,
      );

      await loadDay(selectedDate);
    } catch (e, stack) {
      debugPrint("Ошибка обновления недели: $e\n$stack");
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
    });

    try {
      final data = await widget.repo.getDay(
        groupId: groupId,
        date: day,
        refresh: false,
      );

      if (!mounted) return;

      setState(() {
        lessons = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  void changeWeek(int offset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: offset * 7));
    });
    loadDay(selectedDate);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Расписание"),
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
      ),

      body: Column(
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
            child: lessons.isEmpty
                ? const Center(child: Text("Нет занятий"))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lessons.length,
              itemBuilder: (context, i) {
                final l = lessons[i];
                return GestureDetector(
                  onTap: () {
                    // открываем экран деталей пары
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LessonDetailPage(lesson: l, blacklistRepo: widget.blacklistRepo)),
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
                              getLessonNumber(l.beginTime), // или порядковый номер пары
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ===== Контент пары =====
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Время сверху
                              Text(
                                "${l.beginTime.hour.toString().padLeft(2, '0')}:${l.beginTime.minute.toString().padLeft(2, '0')} - "
                                    "${l.endTime.hour.toString().padLeft(2, '0')}:${l.endTime.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Название дисциплины
                              Text(
                                l.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),

                              // Аудитория
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

      floatingActionButton: FloatingActionButton(
        onPressed: refreshWeek, // пока пусть обновляет неделю
        child: const Icon(Icons.sync),
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
                      setState(() => selectedDate = date);
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
