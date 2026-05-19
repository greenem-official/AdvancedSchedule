import 'package:flutter/material.dart';
import 'package:flutter7/api/api_client.dart';
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
  final ScheduleType scheduleType;

  const SchedulePageContent({
    super.key,
    required this.repo,
    required this.categoryRepo,
    required this.groupId,
    this.title,
    this.showAppBar = true,
    this.scheduleType = ScheduleType.group,
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

  Map<String, int> lessonsCountByDay = {}; // кеш количества занятий по дням
  Set<String> loadedDays = {}; // дни, которые уже загружались
  Set<String> loadingDays = {}; // дни, которые сейчас загружаются

  bool showBlacklisted = false;
  bool fabOpen = false;

  @override
  void initState() {
    super.initState();
    loadDay(selectedDate);

    // Фоновая загрузка всей недели без спиннеров
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadWeekDays(selectedDate, showIndicators: false);
    });
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
      await widget.repo.getDay(
        id: groupId,
        date: selectedDate,
        refresh: true,
        type: widget.scheduleType,
      );

      // Очищаем кеш счётчиков для этой недели
      final ws = weekStart;
      for (int i = 0; i < 7; i++) {
        final day = ws.add(Duration(days: i));
        final dayKey = day.toIso8601String().substring(0, 10);
        loadedDays.remove(dayKey);
        lessonsCountByDay.remove(dayKey);
      }

      await loadDay(selectedDate);

      // Показываем индикаторы при ручном обновлении
      await _preloadWeekDays(selectedDate, showIndicators: true);

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
        id: groupId,
        date: day,
        refresh: false,
        type: widget.scheduleType,
      );

      if (!mounted) return;

      final dayKey = day.toIso8601String().substring(0, 10);

      setState(() {
        lessons = data;
        selectedDate = day;
        loadedDays.add(dayKey);

        if (data.isNotEmpty) {
          lessonsCountByDay[dayKey] = data.length;
        } else {
          lessonsCountByDay.remove(dayKey);
        }
      });

      await updateFilteredLessons();

    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void changeDay(int offset) {
    final newDate = selectedDate.add(Duration(days: offset));
    loadDay(newDate);
  }

  // Замените существующий changeWeek
  void changeWeek(int offset) {
    final newDate = selectedDate.add(Duration(days: offset * 7));
    setState(() {
      selectedDate = newDate;
    });

    loadDay(selectedDate);

    // Фоновая загрузка без индикаторов
    _preloadWeekDays(selectedDate, showIndicators: false);
  }

  Future<void> _preloadWeekDays(DateTime date, {bool showIndicators = true}) async {
    final ws = DateTime(date.year, date.month, date.day - (date.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = ws.add(Duration(days: i));
      final dayKey = day.toIso8601String().substring(0, 10);

      // Пропускаем уже загруженные и загружающиеся
      if (loadedDays.contains(dayKey) || loadingDays.contains(dayKey)) {
        continue;
      }

      // Если не показываем индикаторы - не добавляем в loadingDays
      if (showIndicators) {
        loadingDays.add(dayKey);
      }

      try {
        final data = await widget.repo.getDay(
          id: groupId,
          date: day,
          refresh: false,
          type: widget.scheduleType,
        );

        if (!mounted) return;

        setState(() {
          loadedDays.add(dayKey);
          if (data.isNotEmpty) {
            lessonsCountByDay[dayKey] = data.length;
          } else {
            lessonsCountByDay.remove(dayKey);
          }
        });
      } catch (e) {
        // Тихо игнорируем ошибки фоновой загрузки
        debugPrint("Фоновая загрузка $dayKey не удалась: $e");
      } finally {
        if (showIndicators) {
          loadingDays.remove(dayKey);
        }
      }
    }
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
                final dayKey = date.toIso8601String().substring(0, 10);
                final isLoading = loadingDays.contains(dayKey);
                final isLoaded = loadedDays.contains(dayKey);
                final count = lessonsCountByDay[dayKey];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedDate = date);
                      loadDay(date);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.blue.shade100
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? Colors.blue
                              : Colors.grey.shade300,
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

                            SizedBox(
                              height: 8, // фиксированная высота
                              child: _buildDotIndicator(
                                dayKey: date.toIso8601String().substring(0, 10),
                                active: active,
                              ),
                            ),
                          ],
                        )
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

  Widget _buildDotIndicator({
    required String dayKey,
    required bool active,
  }) {
    final count = lessonsCountByDay[dayKey];
    final isLoading = loadingDays.contains(dayKey);
    final isLoaded = loadedDays.contains(dayKey);

    // Загружается (только если явно в loadingDays)
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              active ? Colors.blue : Colors.grey.shade400,
            ),
          ),
        ),
      );
    }

    // Ещё не загружался
    if (!isLoaded) {
      return const SizedBox.shrink();
    }

    // Нет занятий
    if (count == null || count == 0) {
      return const SizedBox.shrink();
    }

    // Есть занятия - показываем точки
    final dots = count > 3 ? 3 : count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dots, (i) => Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.blue : Colors.grey.shade500,
        ),
      )),
    );
  }
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
