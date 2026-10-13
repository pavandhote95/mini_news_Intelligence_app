import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/data/models/article_model.dart';
import '../../../../shared/domain/entities/article.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._local);

  final FavoritesLocalDataSource _local;

  @override
  Result<List<Article>> getFavorites() {
    try {
      return Success(_local.getAll().map((m) => m.toEntity()).toList());
    } catch (e, st) {
      return Err(ErrorMapper.map(e, st));
    }
  }

  @override
  Future<Result<void>> add(Article article) => _guard(
        () => _local.put(ArticleModel.fromEntity(article, savedAt: DateTime.now())),
      );

  @override
  Future<Result<void>> remove(String url) => _guard(() => _local.delete(url));

  @override
  Future<Result<void>> clear() => _guard(_local.clear);

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Success(null);
    } catch (e, st) {
      return Err(ErrorMapper.map(e, st));
    }
  }
}
