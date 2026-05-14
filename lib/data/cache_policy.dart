// cache_policy.dart
class CachePolicy {
  /// Максимальное количество дней кеша на одну группу
  /// Поставьте 365 для года, 180 для полугода, 90 для семестра
  static const int maxCachedDays = 1800; // было бы 60

  /// Минимальное количество дней вокруг выбранной даты, которые НЕ удаляются
  static const int protectedRadius = 14; // 2 недели

  /// Количество дней, которые гарантированно оставляем в будущем
  static const int keepFutureDays = 300;

  /// Количество дней, которые гарантированно оставляем в прошлом
  static const int keepPastDays = 600;

  /// Дней до истечения "свежести" кеша (после этого можно удалить, если далеко)
  static const int freshnessDays = 30; // было 7

  /// Радиус предзагрузки по умолчанию
  static const int defaultPreloadRadius = 7;

  /// Расширенный радиус предзагрузки при быстром соединении
  static const int extendedPreloadRadius = 14;
}