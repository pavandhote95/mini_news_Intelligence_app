import '../../domain/entities/article.dart';

/// Data-layer representation of an article: knows how to (de)serialize
/// NewsAPI JSON and is persisted in Hive via [ArticleModelAdapter].
class ArticleModel {
  const ArticleModel({
    required this.url,
    required this.title,
    required this.sourceName,
    this.author,
    this.description,
    this.content,
    this.imageUrl,
    this.publishedAt,
    this.savedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final source = json['source'];
    final sourceName = source is Map ? source['name'] as String? : null;

    return ArticleModel(
      url: (json['url'] as String?)?.trim() ?? '',
      title: _cleanTitle(json['title'] as String?, sourceName),
      sourceName: (sourceName == null || sourceName.trim().isEmpty) ? 'Unknown source' : sourceName.trim(),
      author: _nullIfBlank(json['author'] as String?),
      description: _nullIfBlank(json['description'] as String?),
      content: _nullIfBlank(json['content'] as String?),
      imageUrl: _nullIfBlank(json['urlToImage'] as String?),
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    );
  }

  factory ArticleModel.fromEntity(Article article, {DateTime? savedAt}) => ArticleModel(
        url: article.url,
        title: article.title,
        sourceName: article.sourceName,
        author: article.author,
        description: article.description,
        content: article.content,
        imageUrl: article.imageUrl,
        publishedAt: article.publishedAt,
        savedAt: savedAt,
      );

  final String url;
  final String title;
  final String sourceName;
  final String? author;
  final String? description;
  final String? content;
  final String? imageUrl;
  final DateTime? publishedAt;

  /// When the user saved it as a favourite (used for ordering).
  final DateTime? savedAt;

  /// NewsAPI returns placeholder "[Removed]" entries for deleted articles.
  bool get isValid => url.isNotEmpty && title.isNotEmpty && title != '[Removed]' && url != 'https://removed.com';

  Map<String, dynamic> toJson() => {
        'source': {'name': sourceName},
        'url': url,
        'title': title,
        'author': author,
        'description': description,
        'content': content,
        'urlToImage': imageUrl,
        'publishedAt': publishedAt?.toIso8601String(),
      };

  Article toEntity() => Article(
        url: url,
        title: title,
        sourceName: sourceName,
        author: author,
        description: description,
        content: content,
        imageUrl: imageUrl,
        publishedAt: publishedAt,
      );

  static String? _nullIfBlank(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  /// Headlines usually end with " - Source Name"; strip it since the source
  /// is shown separately in the UI.
  static String _cleanTitle(String? title, String? sourceName) {
    final t = title?.trim() ?? '';
    if (sourceName == null || sourceName.isEmpty) return t;
    final suffix = ' - $sourceName';
    return t.endsWith(suffix) ? t.substring(0, t.length - suffix.length).trim() : t;
  }
}
