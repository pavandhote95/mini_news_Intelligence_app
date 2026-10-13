import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/domain/entities/article.dart';
import '../../di/news_providers.dart';
import '../../domain/entities/search_filters.dart';

@immutable
class SearchState {
  const SearchState({
    this.query = '',
    this.filters = SearchFilters.defaults,
    this.articles = const [],
    this.totalResults = 0,
    this.page = 0,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
    this.loadMoreFailure,
    this.selectedSource,
    this.recentSearches = const [],
  });

  final String query;
  final SearchFilters filters;
  final List<Article> articles;
  final int totalResults;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? failure;
  final Failure? loadMoreFailure;

  /// Client-side source filter applied on top of the API results.
  final String? selectedSource;
  final List<String> recentSearches;

  bool get hasValidQuery => query.trim().length >= AppConstants.minSearchLength;

  /// Results after the instant, client-side source filter.
  List<Article> get visibleArticles {
    final source = selectedSource;
    if (source == null) return articles;
    return articles.where((a) => a.sourceName == source).toList();
  }

  /// Most frequent sources in the current results, for quick filter chips.
  List<String> get topSources {
    final counts = <String, int>{};
    for (final a in articles) {
      counts[a.sourceName] = (counts[a.sourceName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => e.key).toList();
  }

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    List<Article>? articles,
    int? totalResults,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
    Failure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
    String? selectedSource,
    bool clearSelectedSource = false,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      articles: articles ?? this.articles,
      totalResults: totalResults ?? this.totalResults,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
      loadMoreFailure: clearLoadMoreFailure ? null : (loadMoreFailure ?? this.loadMoreFailure),
      selectedSource: clearSelectedSource ? null : (selectedSource ?? this.selectedSource),
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

/// Search with efficient querying:
/// * debounced typing — one API call after the user pauses, not per keystroke;
/// * stale-response protection — only the latest request may update state;
/// * minimum query length — no wasted calls for 1-character queries;
/// * server-side filters (sort, date, language) plus an instant client-side
///   source filter that needs no network round-trip.
class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return SearchState(recentSearches: ref.read(searchHistoryRepositoryProvider).getRecent());
  }

  /// Called on every keystroke.
  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();

    if (!state.hasValidQuery) {
      _requestId++; // invalidate anything in flight
      state = state.copyWith(
        articles: const [],
        totalResults: 0,
        page: 0,
        hasMore: false,
        isLoading: false,
        isLoadingMore: false,
        clearFailure: true,
        clearLoadMoreFailure: true,
        clearSelectedSource: true,
      );
      return;
    }
    _debounce = Timer(AppConstants.searchDebounce, _searchFirstPage);
  }

  /// Keyboard "search" pressed or a suggestion tapped: search immediately.
  Future<void> submit(String query) async {
    _debounce?.cancel();
    state = state.copyWith(query: query);
    if (!state.hasValidQuery) return;
    unawaited(saveQueryToHistory());
    await _searchFirstPage();
  }

  Future<void> updateFilters(SearchFilters filters) async {
    if (filters == state.filters) return;
    state = state.copyWith(filters: filters);
    if (state.hasValidQuery) {
      _debounce?.cancel();
      await _searchFirstPage();
    }
  }

  void selectSource(String? source) {
    state = source == null || source == state.selectedSource
        ? state.copyWith(clearSelectedSource: true)
        : state.copyWith(selectedSource: source);
  }

  Future<void> retry() => _searchFirstPage();

  Future<void> _searchFirstPage() async {
    if (!state.hasValidQuery) return;
    final requestId = ++_requestId;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearFailure: true,
      clearLoadMoreFailure: true,
      clearSelectedSource: true,
    );

    final result = await ref.read(searchArticlesProvider)(
      query: state.query,
      filters: state.filters,
      page: 1,
    );
    if (requestId != _requestId) return; // a newer search superseded this one

    state = result.fold(
      onSuccess: (paged) => state.copyWith(
        articles: paged.articles,
        totalResults: paged.totalResults,
        page: 1,
        hasMore: paged.hasMore,
        isLoading: false,
      ),
      onFailure: (failure) => state.copyWith(
        articles: const [],
        totalResults: 0,
        hasMore: false,
        isLoading: false,
        failure: failure,
      ),
    );
  }

  Future<void> loadMore({bool retry = false}) async {
    final s = state;
    if (s.isLoading || s.isLoadingMore || !s.hasMore || s.articles.isEmpty) return;
    if (s.loadMoreFailure != null && !retry) return;

    final requestId = _requestId;
    final nextPage = s.page + 1;
    state = s.copyWith(isLoadingMore: true, clearLoadMoreFailure: true);

    final result = await ref.read(searchArticlesProvider)(
      query: s.query,
      filters: s.filters,
      page: nextPage,
    );
    if (requestId != _requestId) return;

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

  /// Saved when the user commits to a query (submit or opens a result),
  /// so half-typed debounce queries don't pollute the history.
  Future<void> saveQueryToHistory() async {
    final query = state.query.trim();
    if (query.length < AppConstants.minSearchLength) return;
    try {
      final updated = await ref.read(searchHistoryRepositoryProvider).add(query);
      state = state.copyWith(recentSearches: updated);
    } catch (_) {
      // History is a convenience; failing to save it must not break search.
    }
  }

  Future<void> removeRecent(String query) async {
    try {
      final updated = await ref.read(searchHistoryRepositoryProvider).remove(query);
      state = state.copyWith(recentSearches: updated);
    } catch (_) {
      // See saveQueryToHistory.
    }
  }

  Future<void> clearRecent() async {
    try {
      await ref.read(searchHistoryRepositoryProvider).clear();
      state = state.copyWith(recentSearches: const []);
    } catch (_) {
      // See saveQueryToHistory.
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
