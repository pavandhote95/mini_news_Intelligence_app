import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_news_intelligence/core/constants/app_constants.dart';
import 'package:mini_news_intelligence/features/news/di/news_providers.dart';
import 'package:mini_news_intelligence/features/news/domain/entities/search_filters.dart';
import 'package:mini_news_intelligence/features/news/presentation/providers/search_provider.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeNewsRepository repository;
  late FakeSearchHistoryRepository history;
  late ProviderContainer container;

  setUp(() {
    repository = FakeNewsRepository();
    history = FakeSearchHistoryRepository();
    container = ProviderContainer(
      overrides: [
        newsRepositoryProvider.overrideWithValue(repository),
        searchHistoryRepositoryProvider.overrideWithValue(history),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> waitForDebounce() =>
      Future<void>.delayed(AppConstants.searchDebounce + const Duration(milliseconds: 100));

  test('typing is debounced into a single API call', () async {
    final notifier = container.read(searchProvider.notifier);
    notifier
      ..onQueryChanged('t')
      ..onQueryChanged('te')
      ..onQueryChanged('tes')
      ..onQueryChanged('tesla');

    expect(repository.searchQueries, isEmpty);
    await waitForDebounce();

    expect(repository.searchQueries, ['tesla']);
    expect(container.read(searchProvider).articles, hasLength(20));
  });

  test('queries shorter than the minimum never hit the API', () async {
    container.read(searchProvider.notifier).onQueryChanged('a');
    await waitForDebounce();
    expect(repository.searchQueries, isEmpty);
  });

  test('submit searches immediately and saves history', () async {
    await container.read(searchProvider.notifier).submit('inflation');
    expect(repository.searchQueries, ['inflation']);
    expect(container.read(searchProvider).recentSearches, ['inflation']);
  });

  test('changing filters re-runs the search', () async {
    final notifier = container.read(searchProvider.notifier);
    await notifier.submit('oil');
    await notifier.updateFilters(const SearchFilters(sortBy: SearchSortBy.popularity));
    expect(repository.searchQueries, ['oil', 'oil']);
    expect(container.read(searchProvider).filters.activeCount, 1);
  });

  test('source filter narrows results without an API call', () async {
    final notifier = container.read(searchProvider.notifier);
    await notifier.submit('banks');
    notifier.selectSource('Reuters');

    final state = container.read(searchProvider);
    expect(state.visibleArticles, hasLength(10));
    expect(state.visibleArticles.every((a) => a.sourceName == 'Reuters'), isTrue);
    expect(repository.searchQueries, hasLength(1));
  });
}
