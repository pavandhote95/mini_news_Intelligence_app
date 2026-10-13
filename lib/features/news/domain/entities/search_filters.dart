import 'package:flutter/foundation.dart';

enum SearchSortBy {
  publishedAt('Latest'),
  relevancy('Most relevant'),
  popularity('Most popular');

  const SearchSortBy(this.label);
  final String label;
}

enum SearchDateRange {
  any('Any time', null),
  day('Past 24 hours', Duration(days: 1)),
  week('Past week', Duration(days: 7)),
  month('Past month', Duration(days: 30));

  const SearchDateRange(this.label, this.duration);
  final String label;
  final Duration? duration;

  DateTime? fromDate(DateTime now) => duration == null ? null : now.subtract(duration!);
}

enum SearchLanguage {
  all(null, 'All languages'),
  en('en', 'English'),
  de('de', 'German'),
  fr('fr', 'French'),
  es('es', 'Spanish'),
  it('it', 'Italian');

  const SearchLanguage(this.code, this.label);
  final String? code;
  final String label;
}

/// Server-side filters applied to the search API call.
@immutable
class SearchFilters {
  const SearchFilters({
    this.sortBy = SearchSortBy.publishedAt,
    this.dateRange = SearchDateRange.any,
    this.language = SearchLanguage.en,
  });

  final SearchSortBy sortBy;
  final SearchDateRange dateRange;
  final SearchLanguage language;

  static const SearchFilters defaults = SearchFilters();

  bool get isDefault => this == defaults;

  /// Number of filters changed from the defaults (shown as a badge).
  int get activeCount =>
      (sortBy != defaults.sortBy ? 1 : 0) +
      (dateRange != defaults.dateRange ? 1 : 0) +
      (language != defaults.language ? 1 : 0);

  SearchFilters copyWith({SearchSortBy? sortBy, SearchDateRange? dateRange, SearchLanguage? language}) {
    return SearchFilters(
      sortBy: sortBy ?? this.sortBy,
      dateRange: dateRange ?? this.dateRange,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchFilters &&
      other.sortBy == sortBy &&
      other.dateRange == dateRange &&
      other.language == language;

  @override
  int get hashCode => Object.hash(sortBy, dateRange, language);
}
