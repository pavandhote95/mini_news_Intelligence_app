/// NewsAPI endpoints. Docs: https://newsapi.org/docs/endpoints
abstract final class ApiEndpoints {
  static const String baseUrl = 'https://newsapi.org/v2';
  static const String topHeadlines = '/top-headlines';
  static const String everything = '/everything';

  /// Country used for category headlines.
  static const String defaultCountry = 'us';
}
