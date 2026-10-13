import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/list_footer.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../shared/presentation/widgets/article_card.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../domain/entities/news_category.dart';
import '../providers/feed_provider.dart';
import '../widgets/category_ui.dart';
import '../widgets/top_story_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              _greeting(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: const [_ProfileMenu(), SizedBox(width: 8)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: CategoryChips(
            selected: category,
            onSelected: ref.read(selectedCategoryProvider.notifier).select,
          ),
        ),
      ),
      // Keyed by category so each one gets its own scroll position/controller.
      body: _FeedList(key: ValueKey(category), category: category),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning — here are today\'s headlines';
    if (hour < 17) return 'Good afternoon — markets in motion';
    return 'Good evening — catch up on the day';
  }
}

class _FeedList extends ConsumerStatefulWidget {
  const _FeedList({super.key, required this.category});

  final NewsCategory category;

  @override
  ConsumerState<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<_FeedList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - AppConstants.paginationThreshold) {
      ref.read(feedProvider(widget.category).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = feedProvider(widget.category);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    // A failed refresh keeps the existing list and reports via snackbar.
    ref.listen<Failure?>(provider.select((s) => s.failure), (previous, next) {
      if (next != null && ref.read(provider).articles.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    if (state.articles.isEmpty) {
      if (state.isLoading) return const ArticleListSkeleton();
      if (state.failure != null) return ErrorView(failure: state.failure!, onRetry: notifier.refresh);
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyView(icon: Icons.newspaper_rounded, title: 'No headlines right now', message: 'Pull down to refresh.'),
          ],
        ),
      );
    }

    final lead = state.articles.first;
    final rest = state.articles.skip(1).toList();

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (state.isFromCache)
            SliverToBoxAdapter(child: OfflineBanner(cachedAt: state.cachedAt, onRetry: notifier.refresh)),
          SliverToBoxAdapter(
            child: TopStoryCard(
              article: lead,
              onTap: () => context.push(AppRoutes.article, extra: lead),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Latest in ${widget.category.label}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SliverList.separated(
            itemCount: rest.length,
            separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final article = rest[index];
              return ArticleCard(
                article: article,
                onTap: () => context.push(AppRoutes.article, extra: article),
                action: FavoriteButton(article: article),
              );
            },
          ),
          SliverToBoxAdapter(
            child: PaginationFooter(
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
              failure: state.loadMoreFailure,
              onRetry: () => notifier.loadMore(retry: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      onSelected: (value) async {
        if (value != 'logout') return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text('Your favourites stay saved on this device.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
            ],
          ),
        );
        if (confirmed == true) await ref.read(authControllerProvider.notifier).logout();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(user?.name ?? 'Reader'),
            subtitle: Text(user?.email ?? ''),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text('Log out'),
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          user?.initials ?? '?',
          style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
