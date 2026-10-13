import 'package:flutter/material.dart';

import '../utils/date_formatter.dart';

/// Shown above a list when cached (offline) data is being displayed.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.cachedAt, this.onRetry});

  final DateTime? cachedAt;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = cachedAt != null ? ' from ${DateFormatter.relative(cachedAt)}' : '';

    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Offline — showing saved headlines$when',
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
