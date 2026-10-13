import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../shared/data/models/article_model.dart';

@immutable
class CachedHeadlines {
  const CachedHeadlines({required this.articles, required this.cachedAt});

  final List<ArticleModel> articles;
  final DateTime cachedAt;
}

/// Caches the first page of each category so the feed still works offline.
class NewsLocalDataSource {
  NewsLocalDataSource(this._box);

  final Box<dynamic> _box;

  Future<void> cacheHeadlines(String category, List<ArticleModel> articles) async {
    try {
      await _box.put(category, {
        'cachedAt': DateTime.now().toIso8601String(),
        'articles': articles.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      throw CacheException('Failed to cache headlines: $e');
    }
  }

  CachedHeadlines? getCachedHeadlines(String category) {
    final raw = _box.get(category);
    if (raw is! Map) return null;
    try {
      final list = (raw['articles'] as List)
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => ArticleModel.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.isValid)
          .toList();
      return CachedHeadlines(
        articles: list,
        cachedAt: DateTime.parse(raw['cachedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
