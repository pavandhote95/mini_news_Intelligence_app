import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/storage/hive_boxes.dart';
import 'shared/data/models/article_model.dart';
import 'shared/data/models/article_model_adapter.dart';

/// Everything that must be ready before the first frame.
abstract final class Bootstrap {
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(HiveTypeIds.article)) {
      Hive.registerAdapter(ArticleModelAdapter());
    }

    await Future.wait([
      _openBoxSafely<dynamic>(HiveBoxes.auth),
      _openBoxSafely<ArticleModel>(HiveBoxes.favorites),
      _openBoxSafely<dynamic>(HiveBoxes.newsCache),
      _openBoxSafely<dynamic>(HiveBoxes.searchHistory),
    ]);
  }

  /// A corrupted box (e.g. after a crash mid-write) would otherwise stop the
  /// app from launching. Recover by recreating it.
  static Future<Box<T>> _openBoxSafely<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Hive box "$name" could not be opened ($e). Recreating it.');
      await Hive.deleteBoxFromDisk(name);
      return Hive.openBox<T>(name);
    }
  }
}
