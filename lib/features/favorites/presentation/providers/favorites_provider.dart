import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/domain/entities/article.dart';
import '../../di/favorites_providers.dart';

/// In-memory mirror of the Hive favourites box. Every write goes to Hive
/// first and the list is re-read afterwards, so UI and disk never diverge.
class FavoritesNotifier extends Notifier<List<Article>> {
  @override
  List<Article> build() => _read();

  List<Article> _read() => ref.read(getFavoritesProvider)().fold<List<Article>>(
        onSuccess: (list) => list,
        onFailure: (_) => const <Article>[],
      );

  /// Returns the new saved state, or a failure for the UI to report.
  Future<Result<bool>> toggle(Article article) async {
    final isFav = state.any((a) => a.url == article.url);
    final result = await ref.read(toggleFavoriteProvider)(article, isCurrentlyFavorite: isFav);
    state = _read();
    return result;
  }

  Future<Failure?> remove(String url) async {
    // Optimistic update: a swiped Dismissible must leave the tree in the
    // same frame. The list is re-read from Hive right after, so a failed
    // delete puts the item back.
    state = state.where((a) => a.url != url).toList();
    final result = await ref.read(removeFavoriteProvider)(url);
    state = _read();
    return result.fold<Failure?>(onSuccess: (_) => null, onFailure: (f) => f);
  }

  /// Used by "Undo" after a swipe-to-delete.
  Future<Failure?> restore(Article article) async {
    final result = await ref.read(addFavoriteProvider)(article);
    state = _read();
    return result.fold<Failure?>(onSuccess: (_) => null, onFailure: (f) => f);
  }

  Future<Failure?> clearAll() async {
    final result = await ref.read(clearFavoritesProvider)();
    state = _read();
    return result.fold<Failure?>(onSuccess: (_) => null, onFailure: (f) => f);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Article>>(FavoritesNotifier.new);

/// O(1) membership checks for bookmark icons in long lists.
final favoriteUrlsProvider = Provider<Set<String>>(
  (ref) => ref.watch(favoritesProvider).map((a) => a.url).toSet(),
);

final isFavoriteProvider = Provider.family<bool, String>(
  (ref, url) => ref.watch(favoriteUrlsProvider).contains(url),
);
