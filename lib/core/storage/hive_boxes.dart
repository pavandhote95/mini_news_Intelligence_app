/// Names and type ids used by Hive. Keeping them in one place prevents
/// accidental collisions as the app grows.
abstract final class HiveBoxes {
  static const String auth = 'auth_box';
  static const String favorites = 'favorites_box';
  static const String newsCache = 'news_cache_box';
  static const String searchHistory = 'search_history_box';
}

abstract final class HiveTypeIds {
  static const int article = 0;
}
