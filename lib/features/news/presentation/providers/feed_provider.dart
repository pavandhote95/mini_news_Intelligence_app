import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../shared/domain/entities/article.dart';
import '../../di/news_providers.dart';
import '../../domain/entities/news_category.dart';

@immutable
class FeedState {
  const FeedState({
    this.articles = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.isFromCache = false,
    this.cachedAt,
  });

  final List<Article> articles;
  final int page;
  final bool hasMore;

  /// First page / pull-to-refresh in progress.
  final bool isLoading;
  final bool isLoadingMore;

  /// Failure of the first page or a refresh.
  final Failure? failure;

  /// Failure of a "next page" request; shown inline in the list footer.
  final Failure? loadMoreFailure;

  final bool isFromCache;
  final DateTime? cachedAt;

  FeedState copyWith({
    List<Article>? articles,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
    bool? isFromCache,
    DateTime? cachedAt,
  }) {
    return FeedState(
      articles: articles ?? this.articles,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
      loadMoreFailure: clearLoadMoreFailure ? null : (loadMoreFailure ?? this.loadMoreFailure),
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}

/// Paginated headlines for one category. A `family` keeps an independent,
/// cached state per category, so switching tabs back is instant.
class FeedNotifier extends FamilyNotifier<FeedState, NewsCategory> {
  /// Incremented on every first-page load; responses from older
  /// requests (e.g. a page-2 call that finishes after a refresh) are dropped.
  int _generation = 0;

  @override
  FeedState build(NewsCategory arg) {
    unawaited(Future.microtask(_loadFirstPage));
    return const FeedState(isLoading: true);
  }

  Future<void> refresh() => _loadFirstPage();

  Future<void> _loadFirstPage() async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearFailure: true,
      clearLoadMoreFailure: true,
    );

    final result = await ref.read(getTopHeadlinesProvider)(category: arg, page: 1);
    if (generation != _generation) return;

    state = result.fold(
      onSuccess: (paged) => FeedState(
        articles: paged.articles,
        page: 1,
        hasMore: paged.hasMore,
        isFromCache: paged.isFromCache,
        cachedAt: paged.cachedAt,
      ),
      // Keep whatever is already on screen; the UI shows a snackbar instead
      // of wiping the list when a refresh fails.
      onFailure: (failure) => state.copyWith(isLoading: false, failure: failure),
    );
  }

  /// Requests the next page. Safe to call repeatedly from a scroll listener.
  /// After a failure, automatic calls are ignored until [retry] is true.
  Future<void> loadMore({bool retry = false}) async {
    final s = state;
    if (s.isLoading || s.isLoadingMore || !s.hasMore || s.articles.isEmpty) return;
    if (s.loadMoreFailure != null && !retry) return;

    final generation = _generation;
    final nextPage = s.page + 1;
    state = s.copyWith(isLoadingMore: true, clearLoadMoreFailure: true);

    final result = await ref.read(getTopHeadlinesProvider)(category: arg, page: nextPage);
    if (generation != _generation) return;

    result.fold<void>(
      onSuccess: (paged) {
        final seen = state.articles.map((a) => a.url).toSet();
        final fresh = paged.articles.where((a) => seen.add(a.url)).toList();
        state = state.copyWith(
          articles: [...state.articles, ...fresh],
          page: nextPage,
          hasMore: paged.hasMore,
          isLoadingMore: false,
        );
      },
      onFailure: (failure) {
        state = failure is EndOfResultsFailure
            ? state.copyWith(isLoadingMore: false, hasMore: false)
            : state.copyWith(isLoadingMore: false, loadMoreFailure: failure);
      },
    );
  }
}

final feedProvider = NotifierProvider.family<FeedNotifier, FeedState, NewsCategory>(FeedNotifier.new);

/// Category currently selected on the feed screen.
class SelectedCategoryNotifier extends Notifier<NewsCategory> {
  @override
  NewsCategory build() => NewsCategory.business;

  void select(NewsCategory category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, NewsCategory>(SelectedCategoryNotifier.new);
