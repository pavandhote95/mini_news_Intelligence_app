import 'package:flutter/foundation.dart';

/// Core domain entity shared by the feed, search, detail and favourites features.
///
/// Pure Dart (no JSON, no Hive) so business logic stays independent of
/// the API shape and storage technology.
@immutable
class Article {
  const Article({
    required this.url,
    required this.title,
    required this.sourceName,
    this.author,
    this.description,
    this.content,
    this.imageUrl,
    this.publishedAt,
  });

  final String url;
  final String title;
  final String sourceName;
  final String? author;
  final String? description;
  final String? content;
  final String? imageUrl;
  final DateTime? publishedAt;

  /// NewsAPI does not provide ids; the canonical URL is unique per article.
  String get id => url;

  static final RegExp _truncationMarker = RegExp(r'\s*\[\+(\d+) chars\]\s*$');

  /// Content without NewsAPI's trailing "[+1234 chars]" marker.
  String? get cleanContent {
    final raw = content;
    if (raw == null) return null;
    final cleaned = raw.replaceAll(_truncationMarker, '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Whether the API truncated the content (free plans return ~200 chars).
  bool get isContentTruncated => content != null && _truncationMarker.hasMatch(content!);

  /// Estimated reading time of the *full* article in minutes, at ~200 wpm.
  /// Uses the hidden character count NewsAPI reports for truncated content.
  int get readingMinutes {
    final visible = '${description ?? ''} ${cleanContent ?? ''}'.length;
    final match = content == null ? null : _truncationMarker.firstMatch(content!);
    final hidden = int.tryParse(match?.group(1) ?? '') ?? 0;
    final words = (visible + hidden) / 5.5;
    final minutes = (words / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Article && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'Article($title, $sourceName)';
}
