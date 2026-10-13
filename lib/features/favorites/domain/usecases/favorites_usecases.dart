import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/article.dart';
import '../repositories/favorites_repository.dart';

class GetFavorites {
  const GetFavorites(this._repository);
  final FavoritesRepository _repository;

  Result<List<Article>> call() => _repository.getFavorites();
}

/// Adds the article if it isn't saved, removes it otherwise.
/// Returns `true` when the article is saved after the call.
class ToggleFavorite {
  const ToggleFavorite(this._repository);
  final FavoritesRepository _repository;

  Future<Result<bool>> call(Article article, {required bool isCurrentlyFavorite}) async {
    final result = isCurrentlyFavorite
        ? await _repository.remove(article.url)
        : await _repository.add(article);
    return result.fold<Result<bool>>(
      onSuccess: (_) => Success(!isCurrentlyFavorite),
      onFailure: (failure) => Err<bool>(failure),
    );
  }
}

class RemoveFavorite {
  const RemoveFavorite(this._repository);
  final FavoritesRepository _repository;

  Future<Result<void>> call(String url) => _repository.remove(url);
}

class AddFavorite {
  const AddFavorite(this._repository);
  final FavoritesRepository _repository;

  Future<Result<void>> call(Article article) => _repository.add(article);
}

class ClearFavorites {
  const ClearFavorites(this._repository);
  final FavoritesRepository _repository;

  Future<Result<void>> call() => _repository.clear();
}
