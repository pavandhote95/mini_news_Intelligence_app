import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_news_intelligence/core/error/failures.dart';
import 'package:mini_news_intelligence/features/news/di/news_providers.dart';
import 'package:mini_news_intelligence/features/news/domain/entities/news_category.dart';
import 'package:mini_news_intelligence/features/news/presentation/providers/feed_provider.dart';

import '../../helpers/fakes.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeNewsRepository repository;
  late ProviderContainer container;
  final provider = feedProvider(NewsCategory.business);

  setUp(() {
    repository = FakeNewsRepository();
    container = ProviderContainer(
      overrides: [newsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('loads the first page on creation', () async {
    expect(container.read(provider).isLoading, isTrue);
    await _settle();

    final state = container.read(provider);
    expect(state.isLoading, isFalse);
    expect(state.articles, hasLength(20));
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
  });

  test('loadMore appends pages and stops at the end', () async {
    container.read(provider);
    await _settle();

    final notifier = container.read(provider.notifier);
    await notifier.loadMore();
    expect(container.read(provider).articles, hasLength(40));

    await notifier.loadMore();
    expect(container.read(provider).articles, hasLength(60));
    expect(container.read(provider).hasMore, isFalse);

    await notifier.loadMore(); // no-op
    expect(repository.headlineCalls, 3);
  });

  test('first-page failure is exposed, and refresh recovers', () async {
    repository.failWith = const NetworkFailure();
    container.read(provider);
    await _settle();
    expect(container.read(provider).failure, isA<NetworkFailure>());
    expect(container.read(provider).articles, isEmpty);

    repository.failWith = null;
    await container.read(provider.notifier).refresh();
    expect(container.read(provider).failure, isNull);
    expect(container.read(provider).articles, hasLength(20));
  });

  test('load-more failure keeps the list and waits for an explicit retry', () async {
    container.read(provider);
    await _settle();

    repository.failWith = const TimeoutFailure();
    final notifier = container.read(provider.notifier);
    await notifier.loadMore();
    expect(container.read(provider).loadMoreFailure, isA<TimeoutFailure>());
    expect(container.read(provider).articles, hasLength(20));

    repository.failWith = null;
    await notifier.loadMore(); // ignored: needs retry
    expect(container.read(provider).articles, hasLength(20));

    await notifier.loadMore(retry: true);
    expect(container.read(provider).articles, hasLength(40));
    expect(container.read(provider).loadMoreFailure, isNull);
  });
}
