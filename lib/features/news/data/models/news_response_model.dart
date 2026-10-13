import '../../../../shared/data/models/article_model.dart';

/// Shape of a successful NewsAPI response:
/// `{ "status": "ok", "totalResults": 123, "articles": [...] }`
class NewsResponseModel {
  const NewsResponseModel({
    required this.totalResults,
    required this.articles,
    required this.rawCount,
  });

  factory NewsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['articles'];
    final items = rawList is List ? rawList : const <dynamic>[];

    final articles = items
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => ArticleModel.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.isValid)
        .toList();

    return NewsResponseModel(
      totalResults: (json['totalResults'] as num?)?.toInt() ?? 0,
      articles: articles,
      rawCount: items.length,
    );
  }

  final int totalResults;
  final List<ArticleModel> articles;

  /// Count before filtering out removed/invalid items; used to decide
  /// whether another page exists.
  final int rawCount;
}
