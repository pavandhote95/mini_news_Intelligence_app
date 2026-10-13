import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../shared/data/models/article_model.dart';
import '../data/datasources/favorites_local_data_source.dart';
import '../data/repositories/favorites_repository_impl.dart';
import '../domain/repositories/favorites_repository.dart';
import '../domain/usecases/favorites_usecases.dart';

final favoritesBoxProvider = Provider<Box<ArticleModel>>(
  (ref) => Hive.box<ArticleModel>(HiveBoxes.favorites),
);

final favoritesLocalDataSourceProvider = Provider<FavoritesLocalDataSource>(
  (ref) => FavoritesLocalDataSource(ref.watch(favoritesBoxProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepositoryImpl(ref.watch(favoritesLocalDataSourceProvider)),
);

final getFavoritesProvider = Provider((ref) => GetFavorites(ref.watch(favoritesRepositoryProvider)));
final toggleFavoriteProvider = Provider((ref) => ToggleFavorite(ref.watch(favoritesRepositoryProvider)));
final addFavoriteProvider = Provider((ref) => AddFavorite(ref.watch(favoritesRepositoryProvider)));
final removeFavoriteProvider = Provider((ref) => RemoveFavorite(ref.watch(favoritesRepositoryProvider)));
final clearFavoritesProvider = Provider((ref) => ClearFavorites(ref.watch(favoritesRepositoryProvider)));
