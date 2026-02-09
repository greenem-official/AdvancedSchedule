// class Lesson {
//   final String title;
//   final String room;
//   final DateTime time;
//
//   Lesson({
//     required this.title,
//     required this.room,
//     required this.time,
//   });
// }

class Lesson {
  final int id;
  final DateTime date;
  final String begin;
  final String end;
  final Map<String, dynamic> raw;

  Lesson({
    required this.id,
    required this.date,
    required this.begin,
    required this.end,
    required this.raw,
  });

  factory Lesson.fromApi(Map<String, dynamic> json) {
    return Lesson(
      id: json['lessonOid'],
      date: DateTime.parse(json['date']),
      begin: json['beginLesson'],
      end: json['endLesson'],
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'begin': begin,
    'end': end,
    'raw': raw,
  };

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      date: DateTime.parse(json['date']),
      begin: json['begin'],
      end: json['end'],
      raw: Map<String, dynamic>.from(json['raw']),
    );
  }
}