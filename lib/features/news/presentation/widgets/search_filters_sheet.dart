import 'package:flutter/material.dart';

import '../../domain/entities/search_filters.dart';

/// Bottom sheet for server-side search filters. Returns the chosen filters,
/// or null if dismissed.
Future<SearchFilters?> showSearchFiltersSheet(BuildContext context, SearchFilters current) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _SearchFiltersSheet(initial: current),
  );
}

class _SearchFiltersSheet extends StatefulWidget {
  const _SearchFiltersSheet({required this.initial});

  final SearchFilters initial;

  @override
  State<_SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<_SearchFiltersSheet> {
  late SearchFilters _filters = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Filters', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: _filters.isDefault ? null : () => setState(() => _filters = SearchFilters.defaults),
                  child: const Text('Reset'),
                ),
              ],
            ),
            _Section<SearchSortBy>(
              title: 'Sort by',
              values: SearchSortBy.values,
              selected: _filters.sortBy,
              labelOf: (v) => v.label,
              onSelected: (v) => setState(() => _filters = _filters.copyWith(sortBy: v)),
            ),
            _Section<SearchDateRange>(
              title: 'Published',
              values: SearchDateRange.values,
              selected: _filters.dateRange,
              labelOf: (v) => v.label,
              onSelected: (v) => setState(() => _filters = _filters.copyWith(dateRange: v)),
            ),
            _Section<SearchLanguage>(
              title: 'Language',
              values: SearchLanguage.values,
              selected: _filters.language,
              labelOf: (v) => v.label,
              onSelected: (v) => setState(() => _filters = _filters.copyWith(language: v)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _filters),
                child: const Text('Apply filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section<T> extends StatelessWidget {
  const _Section({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(labelOf(value)),
                  selected: value == selected,
                  onSelected: (_) => onSelected(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
