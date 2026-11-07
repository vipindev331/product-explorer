import 'package:flutter/material.dart';

/// Grid layout shared by the product list and its loading skeleton:
/// two columns on phones, more on tablets.
const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 240,
  mainAxisExtent: 300,
  mainAxisSpacing: 14,
  crossAxisSpacing: 14,
);

const productGridPadding = EdgeInsets.fromLTRB(16, 4, 16, 8);

/// Pulsing placeholder grid shown while the first page loads.
class ProductGridSkeleton extends StatefulWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  State<ProductGridSkeleton> createState() => _ProductGridSkeletonState();
}

class _ProductGridSkeletonState extends State<ProductGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.45, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: productGridPadding.add(const EdgeInsets.only(top: 12)),
      sliver: SliverFadeTransition(
        opacity: _opacity,
        sliver: SliverGrid(
          gridDelegate: productGridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _SkeletonCard(),
            childCount: widget.itemCount,
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

    return Semantics(
      label: 'Loading product',
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Container(color: colors.surfaceContainerHighest)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(0.4, 10),
                  const SizedBox(height: 10),
                  bar(0.9, 14),
                  const SizedBox(height: 6),
                  bar(0.6, 14),
                  const SizedBox(height: 12),
                  bar(0.45, 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
