import '../../../../core/utils/result.dart';
import '../entities/news_category.dart';
import '../entities/paged_articles.dart';
import '../entities/search_filters.dart';

abstract interface class NewsRepository {
  /// Top headlines for a category. Falls back to the cached first page when offline.
  Future<Result<PagedArticles>> getTopHeadlines({
    required NewsCategory category,
    required int page,
  });

  Future<Result<PagedArticles>> searchArticles({
    required String query,
    required SearchFilters filters,
    required int page,
  });
}

/// Recently submitted search queries, persisted locally.
abstract interface class SearchHistoryRepository {
  List<String> getRecent();

  Future<List<String>> add(String query);

  Future<List<String>> remove(String query);

  Future<void> clear();
}
