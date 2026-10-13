import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../shared/domain/entities/article.dart';
import '../../../../shared/presentation/widgets/article_card.dart';
import '../providers/favorites_provider.dart';
import '../widgets/favorite_button.dart';

/// Saved articles. Served entirely from Hive, so it works offline.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  /// Instant local filtering over title, source and description.
  List<Article> _applyFilter(List<Article> items) {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (a) =>
              a.title.toLowerCase().contains(q) ||
              a.sourceName.toLowerCase().contains(q) ||
              (a.description?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  Future<void> _remove(Article article) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(favoritesProvider.notifier);
    final failure = await notifier.remove(article.url);

    messenger.hideCurrentSnackBar();
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Removed from favourites'),
        action: SnackBarAction(label: 'Undo', onPressed: () => notifier.restore(article)),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all favourites?'),
        content: const Text('This removes every saved article from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref.read(favoritesProvider.notifier).clearAll();
    if (failure != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final visible = _applyFilter(favorites);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          favorites.isEmpty ? 'Favourites' : 'Favourites (${favorites.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: favorites.isEmpty
          ? const EmptyView(
              icon: Icons.bookmarks_outlined,
              title: 'No saved articles yet',
              message: 'Tap the bookmark on any story to read it later — even offline.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _filterController,
                    onChanged: (v) => setState(() => _filter = v),
                    textInputAction: TextInputAction.search,
                    decoration: AppTheme.inputDecoration(
                      context,
                      label: 'Filter saved articles',
                      prefixIcon: const Icon(Icons.filter_list_rounded),
                      suffixIcon: _filter.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _filterController.clear();
                                setState(() => _filter = '');
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyView(
                          icon: Icons.search_off_rounded,
                          title: 'No matches for "$_filter"',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: visible.length,
                          separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
                          itemBuilder: (context, index) {
                            final article = visible[index];
                            return Dismissible(
                              key: ValueKey(article.url),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                color: theme.colorScheme.errorContainer,
                                child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
                              ),
                              onDismissed: (_) => _remove(article),
                              child: ArticleCard(
                                article: article,
                                onTap: () => context.push(AppRoutes.article, extra: article),
                                action: FavoriteButton(article: article),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
