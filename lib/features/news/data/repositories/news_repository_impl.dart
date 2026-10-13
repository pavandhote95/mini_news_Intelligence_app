import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/news_category.dart';
import '../../domain/entities/paged_articles.dart';
import '../../domain/entities/search_filters.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_local_data_source.dart';
import '../datasources/news_remote_data_source.dart';
import '../models/news_response_model.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl({
    required NewsRemoteDataSource remote,
    required NewsLocalDataSource local,
    this.pageSize = AppConstants.pageSize,
    DateTime Function()? clock,
  })  : _remote = remote,
        _local = local,
        _clock = clock ?? DateTime.now;

  final NewsRemoteDataSource _remote;
  final NewsLocalDataSource _local;
  final int pageSize;
  final DateTime Function() _clock;

  @override
  Future<Result<PagedArticles>> getTopHeadlines({
    required NewsCategory category,
    required int page,
  }) async {
    try {
      final response = await _remote.fetchTopHeadlines(
        category: category.apiValue,
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        // Caching is best-effort; a storage error must not hide fresh news.
        try {
          await _local.cacheHeadlines(category.apiValue, response.articles);
        } catch (_) {
          // Ignored on purpose: the user still gets the live response.
        }
      }
      return Success(_toPaged(response, page));
    } catch (e, st) {
      final failure = ErrorMapper.map(e, st);
      final isConnectivity = failure is NetworkFailure || failure is TimeoutFailure;

      if (page == 1 && isConnectivity) {
        final cached = _local.getCachedHeadlines(category.apiValue);
        if (cached != null && cached.articles.isNotEmpty) {
          return Success(
            PagedArticles(
              articles: cached.articles.map((m) => m.toEntity()).toList(),
              page: 1,
              hasMore: false,
              totalResults: cached.articles.length,
              isFromCache: true,
              cachedAt: cached.cachedAt,
            ),
          );
        }
      }
      return Err(failure);
    }
  }

  @override
  Future<Result<PagedArticles>> searchArticles({
    required String query,
    required SearchFilters filters,
    required int page,
  }) async {
    try {
      final response = await _remote.searchArticles(
        query: query,
        sortBy: filters.sortBy.name,
        language: filters.language.code,
        from: filters.dateRange.fromDate(_clock()),
        page: page,
        pageSize: pageSize,
      );
      return Success(_toPaged(response, page));
    } catch (e, st) {
      return Err(ErrorMapper.map(e, st));
    }
  }

  PagedArticles _toPaged(NewsResponseModel response, int page) {
    final reachable = math.min(response.totalResults, AppConstants.maxApiResults);
    final hasMore = response.rawCount >= pageSize && page * pageSize < reachable;

    return PagedArticles(
      articles: response.articles.map((m) => m.toEntity()).toList(),
      page: page,
      hasMore: hasMore,
      totalResults: response.totalResults,
    );
  }
}
