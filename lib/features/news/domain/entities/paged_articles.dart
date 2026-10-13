import 'package:flutter/foundation.dart';

import '../../../../shared/domain/entities/article.dart';

/// One page of articles plus what the UI needs to keep paginating.
@immutable
class PagedArticles {
  const PagedArticles({
    required this.articles,
    required this.page,
    required this.hasMore,
    this.totalResults = 0,
    this.isFromCache = false,
    this.cachedAt,
  });

  final List<Article> articles;
  final int page;
  final bool hasMore;
  final int totalResults;

  /// True when the network failed and the last saved page is shown instead.
  final bool isFromCache;
  final DateTime? cachedAt;
}
