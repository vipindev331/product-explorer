import 'package:flutter/material.dart';

/// Network image with a fade-in and a consistent fallback for missing or
/// broken images.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  });

  final String url;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const ImagePlaceholder();

    return Padding(
      padding: padding,
      child: Image.network(
        url,
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
