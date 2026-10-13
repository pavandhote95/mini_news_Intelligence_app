import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../shared/domain/entities/article.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final Article article;

  /// NewsAPI only ships a snippet of the body, so the complete story is
  /// opened in an in-app browser tab (Custom Tabs / SFSafariViewController).
  Future<void> _openFullArticle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(article.url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        if (!opened) opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not open the article link.')));
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: article.url));
    messenger.showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(isFavoriteProvider(article.url));
    final body = article.cleanContent;
    final hasImage = article.imageUrl != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: hasImage ? 280 : null,
            actions: [
              IconButton(
                tooltip: 'Copy link',
                icon: const Icon(Icons.link_rounded),
                onPressed: () => _copyLink(context),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: hasImage
                ? FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(url: article.imageUrl),
                        // Scrim keeps the back/action icons legible over bright photos.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SourceBadge(name: article.sourceName),
                  const SizedBox(height: 12),
                  SelectableText(
                    article.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.25),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      if (article.author != null)
                        _Meta(icon: Icons.person_outline_rounded, text: article.author!),
                      if (article.publishedAt != null)
                        _Meta(
                          icon: Icons.schedule_rounded,
                          text: DateFormatter.fullWithTime(article.publishedAt!),
                        ),
                      _Meta(icon: Icons.menu_book_outlined, text: '${article.readingMinutes} min read'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  if (article.description != null) ...[
                    SelectableText(
                      article.description!,
                      style: theme.textTheme.titleMedium?.copyWith(height: 1.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (body != null && body != article.description)
                    SelectableText(
                      article.isContentTruncated ? '$body…' : body,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                  if (body == null && article.description == null)
                    Text(
                      'No preview is available for this story.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 28),
                  _ReadFullCard(onPressed: () => _openFullArticle(context)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => toggleFavoriteWithFeedback(context, ref, article),
        icon: Icon(isFavorite ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined),
        label: Text(isFavorite ? 'Saved' : 'Save'),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _ReadFullCard extends StatelessWidget {
  const _ReadFullCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Continue reading', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Open the complete story from the publisher.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Read full article'),
          ),
        ],
      ),
    );
  }
}
