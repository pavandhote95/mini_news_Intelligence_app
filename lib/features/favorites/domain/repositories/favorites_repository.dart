import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/article.dart';

abstract interface class FavoritesRepository {
  /// All saved articles, most recently saved first. Fully offline.
  Result<List<Article>> getFavorites();

  Future<Result<void>> add(Article article);

  Future<Result<void>> remove(String url);

  Future<Result<void>> clear();
}
