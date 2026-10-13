import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/news_category.dart';
import '../entities/paged_articles.dart';
import '../entities/search_filters.dart';
import '../repositories/news_repository.dart';

class GetTopHeadlines {
  const GetTopHeadlines(this._repository);
  final NewsRepository _repository;

  Future<Result<PagedArticles>> call({required NewsCategory category, int page = 1}) {
    return _repository.getTopHeadlines(category: category, page: page);
  }
}

class SearchArticles {
  const SearchArticles(this._repository);
  final NewsRepository _repository;

  Future<Result<PagedArticles>> call({
    required String query,
    SearchFilters filters = SearchFilters.defaults,
    int page = 1,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < AppConstants.minSearchLength) {
      return const Err(
        ValidationFailure('Type at least ${AppConstants.minSearchLength} characters to search.'),
      );
    }
    return _repository.searchArticles(query: trimmed, filters: filters, page: page);
  }
}
