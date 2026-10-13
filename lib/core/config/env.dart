/// Compile-time configuration.
///
/// Secrets are never hard-coded. Provide them at build time:
/// `flutter run --dart-define-from-file=env.json`
/// or `flutter run --dart-define=NEWS_API_KEY=xxxx`.
abstract final class Env {
  static const String newsApiKey = String.fromEnvironment('NEWS_API_KEY');

  static bool get hasNewsApiKey => newsApiKey.trim().isNotEmpty;
}
