import 'package:flutter/material.dart';
import 'package:flutter7/data/repository.dart';
import '../models/lesson.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final repo = ScheduleRepository();

  final String groupId = "154481"; // пока хардкод, потом вынесешь в настройки

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

  Future<void> refreshWeek() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final start = weekStart.subtract(const Duration(days: 3));
      final end = weekStart.add(const Duration(days: 9));

      await repo.getDay(
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
      final data = await repo.getDay(
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
                  "${weekStart.day}.${weekStart.month} — "
                      "${weekStart.add(const Duration(days: 6)).day}.${weekStart.month}",
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
                return Container(
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
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          "${l.beginTime.hour.toString().padLeft(2, '0')}:${l.beginTime.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
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
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
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
