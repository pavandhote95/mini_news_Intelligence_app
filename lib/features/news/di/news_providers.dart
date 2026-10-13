import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/config/env.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/hive_boxes.dart';
import '../data/datasources/news_local_data_source.dart';
import '../data/datasources/news_remote_data_source.dart';
import '../data/repositories/news_repository_impl.dart';
import '../data/repositories/search_history_repository_impl.dart';
import '../domain/repositories/news_repository.dart';
import '../domain/usecases/news_usecases.dart';

/// Dependency graph for the news feature. Tests override [newsRepositoryProvider].
final newsCacheBoxProvider = Provider<Box<dynamic>>((ref) => Hive.box<dynamic>(HiveBoxes.newsCache));
final searchHistoryBoxProvider = Provider<Box<dynamic>>((ref) => Hive.box<dynamic>(HiveBoxes.searchHistory));

final newsRemoteDataSourceProvider = Provider<NewsRemoteDataSource>(
  (ref) => NewsApiRemoteDataSource(ref.watch(dioProvider), apiKey: Env.newsApiKey),
);

final newsLocalDataSourceProvider = Provider<NewsLocalDataSource>(
  (ref) => NewsLocalDataSource(ref.watch(newsCacheBoxProvider)),
);

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepositoryImpl(
    remote: ref.watch(newsRemoteDataSourceProvider),
    local: ref.watch(newsLocalDataSourceProvider),
  ),
);

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>(
  (ref) => SearchHistoryRepositoryImpl(ref.watch(searchHistoryBoxProvider)),
);

final getTopHeadlinesProvider = Provider((ref) => GetTopHeadlines(ref.watch(newsRepositoryProvider)));
final searchArticlesProvider = Provider((ref) => SearchArticles(ref.watch(newsRepositoryProvider)));
