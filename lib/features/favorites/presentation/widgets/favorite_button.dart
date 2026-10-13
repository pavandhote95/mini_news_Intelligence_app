import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/article.dart';
import '../providers/favorites_provider.dart';

/// Bookmark toggle used on article cards and the detail screen.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.article, this.showFeedback = true});

  final Article article;
  final bool showFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(article.url));
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: isFavorite ? 'Remove from favourites' : 'Save to favourites',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: Icon(
          isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(isFavorite),
          color: isFavorite ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
      onPressed: () => toggleFavoriteWithFeedback(context, ref, article, showFeedback: showFeedback),
    );
  }
}

/// Shared toggle logic so every entry point shows the same feedback.
Future<void> toggleFavoriteWithFeedback(
  BuildContext context,
  WidgetRef ref,
  Article article, {
  bool showFeedback = true,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final result = await ref.read(favoritesProvider.notifier).toggle(article);
  if (!showFeedback || messenger == null) return;

  messenger.hideCurrentSnackBar();
  result.fold<void>(
    onSuccess: (saved) => messenger.showSnackBar(
      SnackBar(
        content: Text(saved ? 'Saved to favourites' : 'Removed from favourites'),
        duration: const Duration(seconds: 2),
      ),
    ),
    onFailure: (failure) => messenger.showSnackBar(SnackBar(content: Text(failure.message))),
  );
}
