import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/list_footer.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../shared/domain/entities/article.dart';
import '../../../../shared/presentation/widgets/article_card.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../providers/search_provider.dart';
import '../widgets/search_filters_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryController;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Restore the text if the user returns to this tab.
    _queryController = TextEditingController(text: ref.read(searchProvider).query);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - AppConstants.paginationThreshold) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _runQuery(String query) {
    _queryController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _focusNode.unfocus();
    ref.read(searchProvider.notifier).submit(query);
  }

  void _clear() {
    _queryController.clear();
    ref.read(searchProvider.notifier).onQueryChanged('');
    _focusNode.requestFocus();
  }

  Future<void> _openFilters() async {
    final notifier = ref.read(searchProvider.notifier);
    final picked = await showSearchFiltersSheet(context, ref.read(searchProvider).filters);
    if (picked != null) await notifier.updateFilters(picked);
  }

  void _openArticle(Article article) {
    ref.read(searchProvider.notifier).saveQueryToHistory();
    context.push(AppRoutes.article, extra: article);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: TextField(
          controller: _queryController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onChanged: ref.read(searchProvider.notifier).onQueryChanged,
          onSubmitted: _runQuery,
          decoration: InputDecoration(
            hintText: 'Search companies, markets, topics…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: state.query.isEmpty
                ? null
                : IconButton(tooltip: 'Clear', icon: const Icon(Icons.close_rounded), onPressed: _clear),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: state.filters.activeCount > 0,
              label: Text('${state.filters.activeCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(SearchState state) {
    if (!state.hasValidQuery) {
      return _SearchSuggestions(
        recent: state.recentSearches,
        onSelected: _runQuery,
        onRemove: ref.read(searchProvider.notifier).removeRecent,
        onClearAll: ref.read(searchProvider.notifier).clearRecent,
      );
    }
    if (state.isLoading) return const ArticleListSkeleton();
    if (state.failure != null) {
      return ErrorView(failure: state.failure!, onRetry: ref.read(searchProvider.notifier).retry);
    }
    if (state.articles.isEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        title: 'No results for "${state.query.trim()}"',
        message: state.filters.isDefault
            ? 'Try a different keyword or a broader topic.'
            : 'Try different keywords or relax your filters.',
      );
    }

    final visible = state.visibleArticles;
    final theme = Theme.of(context);

    return CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '${state.totalResults} results • ${state.filters.sortBy.label.toLowerCase()}',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        if (state.topSources.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: state.topSources.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ChoiceChip(
                      label: const Text('All sources'),
                      selected: state.selectedSource == null,
                      onSelected: (_) => ref.read(searchProvider.notifier).selectSource(null),
                    );
                  }
                  final source = state.topSources[index - 1];
                  return ChoiceChip(
                    label: Text(source),
                    selected: state.selectedSource == source,
                    onSelected: (_) => ref.read(searchProvider.notifier).selectSource(source),
                  );
                },
              ),
            ),
          ),
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final article = visible[index];
            return ArticleCard(
              article: article,
              onTap: () => _openArticle(article),
              action: FavoriteButton(article: article),
            );
          },
        ),
        SliverToBoxAdapter(
          child: PaginationFooter(
            isLoadingMore: state.isLoadingMore,
            hasMore: state.hasMore,
            failure: state.loadMoreFailure,
            onRetry: () => ref.read(searchProvider.notifier).loadMore(retry: true),
          ),
        ),
      ],
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({
    required this.recent,
    required this.onSelected,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<String> recent;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Text('Recent searches', style: headerStyle),
                const Spacer(),
                TextButton(onPressed: onClearAll, child: const Text('Clear')),
              ],
            ),
          ),
          for (final query in recent)
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(query),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => onRemove(query),
              ),
              onTap: () => onSelected(query),
            ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text('Trending in business', style: headerStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in AppConstants.suggestedTopics)
                ActionChip(
                  avatar: const Icon(Icons.trending_up_rounded, size: 18),
                  label: Text(topic),
                  onPressed: () => onSelected(topic),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
