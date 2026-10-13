import 'package:mini_news_intelligence/core/error/failures.dart';
import 'package:mini_news_intelligence/core/utils/result.dart';
import 'package:mini_news_intelligence/features/auth/domain/entities/user.dart';
import 'package:mini_news_intelligence/features/auth/domain/repositories/auth_repository.dart';
import 'package:mini_news_intelligence/features/news/domain/entities/news_category.dart';
import 'package:mini_news_intelligence/features/news/domain/entities/paged_articles.dart';
import 'package:mini_news_intelligence/features/news/domain/entities/search_filters.dart';
import 'package:mini_news_intelligence/features/news/domain/repositories/news_repository.dart';
import 'package:mini_news_intelligence/shared/domain/entities/article.dart';

List<Article> fakeArticles(int count, {int start = 0, String prefix = 'a'}) => List.generate(
      count,
      (i) => Article(
        url: 'https://example.com/$prefix/${start + i}',
        title: 'Headline ${start + i}',
        sourceName: i.isEven ? 'Reuters' : 'Bloomberg',
        publishedAt: DateTime(2026, 10, 13),
      ),
    );

/// Serves 3 pages of 20 articles; can be told to fail.
class FakeNewsRepository implements NewsRepository {
  Failure? failWith;
  int headlineCalls = 0;
  final List<String> searchQueries = [];

  @override
  Future<Result<PagedArticles>> getTopHeadlines({required NewsCategory category, required int page}) async {
    headlineCalls++;
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Success(
      PagedArticles(
        articles: fakeArticles(20, start: (page - 1) * 20, prefix: category.name),
        page: page,
        hasMore: page < 3,
        totalResults: 60,
      ),
    );
  }

  @override
  Future<Result<PagedArticles>> searchArticles({
    required String query,
    required SearchFilters filters,
    required int page,
  }) async {
    searchQueries.add(query);
    final failure = failWith;
    if (failure != null) return Err(failure);
    return Success(
      PagedArticles(
        articles: fakeArticles(20, start: (page - 1) * 20, prefix: query),
        page: page,
        hasMore: page < 2,
        totalResults: 40,
      ),
    );
  }
}

class FakeSearchHistoryRepository implements SearchHistoryRepository {
  final List<String> items = [];

  @override
  List<String> getRecent() => List.of(items);

  @override
  Future<List<String>> add(String query) async {
    items
      ..remove(query)
      ..insert(0, query);
    return getRecent();
  }

  @override
  Future<List<String>> remove(String query) async {
    items.remove(query);
    return getRecent();
  }

  @override
  Future<void> clear() async => items.clear();
}

class FakeAuthRepository implements AuthRepository {
  User? user;

  @override
  User? getCurrentUser() => user;

  @override
  Future<Result<User>> login({required String email, required String password}) async {
    user = User(id: '1', email: email, name: 'Test User', loggedInAt: DateTime(2026));
    return Success(user!);
  }

  @override
  Future<Result<void>> logout() async {
    user = null;
    return const Success(null);
  }
}
