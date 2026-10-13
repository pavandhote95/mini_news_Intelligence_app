import 'package:hive/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../shared/data/models/article_model.dart';

/// Stores favourite articles in a typed Hive box (see `ArticleModelAdapter`).
class FavoritesLocalDataSource {
  FavoritesLocalDataSource(this._box);

  final Box<ArticleModel> _box;

  List<ArticleModel> getAll() {
    try {
      final items = _box.values.toList()
        ..sort((a, b) {
          final aTime = a.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.savedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
      return items;
    } catch (e) {
      throw CacheException('Failed to read favourites: $e');
    }
  }

  Future<void> put(ArticleModel model) async {
    try {
      await _box.put(keyFor(model.url), model);
    } catch (e) {
      throw CacheException('Failed to save favourite: $e');
    }
  }

  Future<void> delete(String url) async {
    try {
      await _box.delete(keyFor(url));
    } catch (e) {
      throw CacheException('Failed to remove favourite: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (e) {
      throw CacheException('Failed to clear favourites: $e');
    }
  }

  /// Hive string keys must be ASCII and at most 255 chars, which URLs don't
  /// guarantee. A stable FNV-1a hash (plus the length) makes a safe key.
  static String keyFor(String url) {
    var hash = 0x811c9dc5;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'fav_${hash.toRadixString(16)}_${url.length}';
  }
}
