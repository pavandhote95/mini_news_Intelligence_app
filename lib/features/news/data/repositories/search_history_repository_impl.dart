import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/news_repository.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  SearchHistoryRepositoryImpl(this._box);

  final Box<dynamic> _box;
  static const String _key = 'recent_queries';

  @override
  List<String> getRecent() {
    final raw = _box.get(_key);
    return raw is List ? raw.whereType<String>().toList() : <String>[];
  }

  /// Most recent first, de-duplicated case-insensitively, capped in size.
  @override
  Future<List<String>> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getRecent();
    final updated = [
      q,
      ...getRecent().where((e) => e.toLowerCase() != q.toLowerCase()),
    ].take(AppConstants.maxRecentSearches).toList();
    await _box.put(_key, updated);
    return updated;
  }

  @override
  Future<List<String>> remove(String query) async {
    final updated = getRecent().where((e) => e != query).toList();
    await _box.put(_key, updated);
    return updated;
  }

  @override
  Future<void> clear() => _box.delete(_key);
}
