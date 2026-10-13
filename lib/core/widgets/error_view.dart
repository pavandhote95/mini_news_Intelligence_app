import 'package:flutter/material.dart';

import '../error/failures.dart';

/// Full-area error state with a contextual icon and a retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  ({IconData icon, String title}) get _visuals => switch (failure) {
        NetworkFailure() => (icon: Icons.wifi_off_rounded, title: "You're offline"),
        TimeoutFailure() => (icon: Icons.hourglass_empty_rounded, title: 'Taking too long'),
        ApiKeyFailure() => (icon: Icons.key_off_rounded, title: 'API key problem'),
        RateLimitFailure() => (icon: Icons.speed_rounded, title: 'Too many requests'),
        ServerFailure() => (icon: Icons.cloud_off_rounded, title: 'Service unavailable'),
        CacheFailure() => (icon: Icons.sd_card_alert_outlined, title: 'Storage error'),
        EndOfResultsFailure() => (icon: Icons.done_all_rounded, title: 'All caught up'),
        ValidationFailure() => (icon: Icons.info_outline_rounded, title: 'Check your input'),
        UnknownFailure() => (icon: Icons.error_outline_rounded, title: 'Something went wrong'),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = _visuals;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.errorContainer,
              child: Icon(visuals.icon, size: 36, color: theme.colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 20),
            Text(
              visuals.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
