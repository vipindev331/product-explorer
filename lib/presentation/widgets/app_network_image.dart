import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with a fade-in and a consistent fallback for missing or
/// broken images.
///
/// Images are stored on disk the first time they are downloaded
/// (`cached_network_image`), so they are still shown offline and after the app
/// restarts.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  });

  /// Creates the image provider for a URL. Defaults to a disk-cached provider;
  /// tests replace it so they never touch the network or the file system.
  static ImageProvider Function(String url) providerFactory = defaultProvider;

  /// The provider used by the app: downloads once, then serves from disk.
  static ImageProvider defaultProvider(String url) => CachedNetworkImageProvider(url);

  final String url;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const ImagePlaceholder();

    return Padding(
      padding: padding,
      child: Image(
        image: providerFactory(url),
        fit: fit,
        semanticLabel: semanticLabel,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (_, __, ___) =>
            const ImagePlaceholder(icon: Icons.broken_image_outlined),
      ),
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, this.icon = Icons.image_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        icon,
        size: 40,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    );
  }
}
