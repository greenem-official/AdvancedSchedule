import '../models/lesson.dart';

class TimetableRepository {
  final Map<DateTime, List<Lesson>> _data = {};

  List<Lesson> getLessons(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _data[key] ?? [];
  }

  void addLesson(DateTime date, Lesson lesson) {
    final key = DateTime(date.year, date.month, date.day);
    _data.putIfAbsent(key, () => []);
    _data[key]!.add(lesson);
  }
}
