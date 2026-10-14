import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with disk caching, a placeholder and a graceful fallback.
/// Cached images keep favourites looking right while offline.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.article_outlined, color: scheme.outline),
    );

    final imageUrl = url;
    if (imageUrl == null || Uri.tryParse(imageUrl)?.hasScheme != true) {
      return ClipRRect(borderRadius: borderRadius, child: fallback);
    }
 
    return ClipRRect(
      borderRadius: borderRadius, 
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width, 
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, _) => Container(
          width: width,
          height: height,
          color: scheme.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}
