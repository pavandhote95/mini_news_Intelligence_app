abstract final class AppConstants {
  static const String appName = 'News Intelligence';
  static const String tagline = 'Business news, distilled.';

  /// Items requested per page from the API.
  static const int pageSize = 20;

  /// NewsAPI's developer plan never returns more than 100 results per query,
  /// so pagination stops there instead of hitting a 426 error.
  static const int maxApiResults = 100;

  /// How long to wait after the last keystroke before calling the search API.
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const int minSearchLength = 2;
  static const int maxRecentSearches = 8;

  /// Distance from the bottom of a list at which the next page is requested.
  static const double paginationThreshold = 400;

  static const int minPasswordLength = 6;

  /// Business-focused topics suggested on the empty search screen.
  static const List<String> suggestedTopics = [
    'Stock market',
    'Inflation',
    'Interest rates',
    'Startups',
    'Earnings',
    'Artificial intelligence',
    'Oil prices',
    'Mergers',
  ];
}
