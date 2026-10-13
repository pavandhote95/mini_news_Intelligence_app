import 'package:flutter/material.dart';

import '../error/failures.dart';

/// Footer for paginated lists: loader, inline retry, or end-of-list marker.
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    this.failure,
    this.onRetry,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final Failure? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
    }

    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              failure!.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Load more'),
            ),
          ],
        ),
      );
    }

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text(
            "You're all caught up",
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}
