DateTime _parseTime(dynamic value, DateTime day) {
  if (value == null) return day;

  // Если уже DateTime
  if (value is DateTime) return value;

  // Если строка
  if (value is String) {
    // ISO формат: 2026-02-09T09:00:00
    if (value.contains('T')) {
      return DateTime.parse(value);
    }

    // Формат HH:mm
    if (value.contains(':')) {
      final parts = value.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return day.copyWith(hour: hour, minute: minute);
    }
  }

  // fallback
  return day;
}
