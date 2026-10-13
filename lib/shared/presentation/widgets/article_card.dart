import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../domain/entities/article.dart';

/// Compact list tile for an article. The trailing [action] slot is filled by
/// the caller (e.g. a favourite toggle) so this widget stays feature-agnostic.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap, this.action});

  final Article article;
  final VoidCallback onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              url: article.imageUrl,
              width: 96,
              height: 96,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.sourceName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      if (article.publishedAt != null) DateFormatter.relative(article.publishedAt),
                      '${article.readingMinutes} min read',
                    ].join('  •  '),
                    style: muted,
                  ),
                ],
              ),
            ),
            if (action != null) action! else const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
