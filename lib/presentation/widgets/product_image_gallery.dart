import 'package:flutter/material.dart';

import 'app_network_image.dart';

/// Swipeable image gallery with page dots. Tapping opens a zoomable viewer.
class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({super.key, required this.images, this.semanticLabel});

  final List<String> images;
  final String? semanticLabel;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullscreenImageViewer(images: widget.images, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final images = widget.images;
    final topInset = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
      child: images.isEmpty
          ? const ImagePlaceholder()
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  key: const Key('product_gallery'),
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openViewer(index),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(32, topInset + 56, 32, 48),
                      child: AppNetworkImage(
                        url: images[index],
                        semanticLabel: widget.semanticLabel == null
                            ? null
                            : '${widget.semanticLabel}, image ${index + 1} of ${images.length}',
                      ),
                    ),
                  ),
                ),
                if (images.length > 1) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 22,
                    child: Center(child: PageDots(count: images.length, index: _index)),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 14,
                    child: _CounterPill(text: '${_index + 1}/${images.length}'),
                  ),
                ],
              ],
            ),
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? colors.primary : colors.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

/// Full-screen, pinch-to-zoom image viewer.
class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({super.key, required this.images, this.initialIndex = 0});

  final List<String> images;
  final int initialIndex;

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${_index + 1} of ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(child: AppNetworkImage(url: widget.images[index])),
        ),
      ),
    );
  }
}
