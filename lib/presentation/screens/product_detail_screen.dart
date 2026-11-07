import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../providers/product_detail_provider.dart';
import '../widgets/app_network_image.dart';
import '../widgets/discount_badge.dart';
import '../widgets/info_grid.dart';
import '../widgets/info_pill.dart';
import '../widgets/offline_banner.dart';
import '../widgets/price_tag.dart';
import '../widgets/product_card.dart' show productHeroTag;
import '../widgets/product_image_gallery.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_tile.dart';
import '../widgets/section_card.dart';
import '../widgets/stock_badge.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductDetailProvider(
        repository: context.read<ProductRepository>(),
        initialProduct: product,
      )..refresh(),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductDetailProvider>();
    final product = provider.product;
    final colors = Theme.of(context).colorScheme;
    final galleryHeight =
        (MediaQuery.sizeOf(context).height * 0.48).clamp(280.0, 480.0).toDouble();

    String? staleNote;
    if (provider.isOffline) {
      staleNote = 'You’re offline. These details may be out of date.';
    } else if (provider.isShowingStaleData) {
      staleNote = 'Latest details didn’t load. Showing the last known version.';
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: galleryHeight,
            backgroundColor: colors.surface,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton.filledTonal(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            actions: [
              if (provider.isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: productHeroTag(product.id),
                flightShuttleBuilder: (_, __, ___, ____, _____) => AppNetworkImage(
                  url: product.thumbnail,
                  padding: const EdgeInsets.all(14),
                ),
                child: ProductImageGallery(
                  images: product.galleryImages,
                  semanticLabel: product.title,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    32 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: _ProductDetailBody(product: product, staleNote: staleNote),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.product, this.staleNote});

  final Product product;
  final String? staleNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;

    final details = <InfoItem>[
      if (product.brand != null)
        InfoItem(icon: Icons.storefront_outlined, label: 'Brand', value: product.brand!),
      InfoItem(
        icon: Icons.category_outlined,
        label: 'Category',
        value: humanize(product.category),
      ),
      if (product.sku != null)
        InfoItem(icon: Icons.qr_code_2_rounded, label: 'SKU', value: product.sku!),
      InfoItem(
        icon: Icons.inventory_2_outlined,
        label: 'Stock',
        value: '${product.stock} units',
      ),
      if (product.minimumOrderQuantity != null)
        InfoItem(
          icon: Icons.shopping_basket_outlined,
          label: 'Minimum order',
          value: '${product.minimumOrderQuantity} units',
        ),
      if (product.weight != null)
        InfoItem(
          icon: Icons.scale_outlined,
          label: 'Weight',
          value: formatNumber(product.weight!),
        ),
      if (product.dimensions != null)
        InfoItem(
          icon: Icons.straighten_rounded,
          label: 'Size (W × H × D)',
          value: product.dimensions!.formatted,
        ),
    ];

    final policies = <(IconData, String, String)>[
      if (product.shippingInformation != null)
        (Icons.local_shipping_outlined, 'Shipping', product.shippingInformation!),
      if (product.warrantyInformation != null)
        (Icons.verified_user_outlined, 'Warranty', product.warrantyInformation!),
      if (product.returnPolicy != null)
        (Icons.assignment_return_outlined, 'Returns', product.returnPolicy!),
      if (product.availabilityStatus != null)
        (Icons.inventory_outlined, 'Availability', product.availabilityStatus!),
    ];

    final meta = product.meta;
    final metaRows = <(String, String)>[
      if (meta?.barcode != null) ('Barcode', meta!.barcode!),
      if (meta?.createdAt != null) ('Listed on', formatDate(meta!.createdAt!)),
      if (meta?.updatedAt != null) ('Last updated', formatDate(meta!.updatedAt!)),
    ];

    final reviewAverage = product.averageReviewRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoPill(icon: Icons.category_outlined, label: humanize(product.category)),
            if (product.brand != null)
              InfoPill(icon: Icons.storefront_outlined, label: product.brand!),
          ],
        ),
        const SizedBox(height: 14),
        Text(product.title, style: text.headlineSmall?.copyWith(height: 1.2)),
        const SizedBox(height: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            RatingStars(rating: product.rating, size: 20),
            Text(
              product.rating.toStringAsFixed(2),
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (product.reviews.isNotEmpty)
              Text(
                '(${product.reviews.length} ${product.reviews.length == 1 ? 'review' : 'reviews'})',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _PriceCard(product: product),
        if (staleNote != null) ...[
          const SizedBox(height: 12),
          OfflineBanner(key: const Key('offline_note'), message: staleNote!),
        ],
        if (product.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'About this product',
            child: Text(product.description, style: text.bodyLarge?.copyWith(height: 1.5)),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(title: 'Specifications', child: InfoGrid(items: details)),
        if (policies.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Shipping and returns',
            child: Column(
              children: [
                for (final (index, policy) in policies.indexed) ...[
                  if (index > 0) const SizedBox(height: 14),
                  _PolicyRow(icon: policy.$1, title: policy.$2, value: policy.$3),
                ],
              ],
            ),
          ),
        ],
        if (product.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Tags',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in product.tags)
                  Chip(
                    label: Text(humanize(tag)),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: colors.outlineVariant),
                  ),
              ],
            ),
          ),
        ],
        if (product.reviews.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Customer reviews',
            trailing: reviewAverage == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: AppColors.rating),
                      const SizedBox(width: 4),
                      Text(
                        formatNumber(reviewAverage, maxDecimals: 1),
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
            child: Column(
              children: [
                for (final (index, review) in product.reviews.indexed) ...[
                  if (index > 0)
                    Divider(height: 28, color: colors.outlineVariant.withValues(alpha: 0.6)),
                  ReviewTile(review: review),
                ],
              ],
            ),
          ),
        ],
        if (metaRows.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'More information',
            child: Column(
              children: [
                for (final (index, row) in metaRows.indexed) ...[
                  if (index > 0) const SizedBox(height: 10),
                  _KeyValueRow(label: row.$1, value: row.$2),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: theme.textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                PriceTag(
                  price: product.discountedPrice,
                  originalPrice: product.hasDiscount ? product.price : null,
                  large: true,
                ),
                if (product.hasDiscount) ...[
                  const SizedBox(height: 8),
                  DiscountBadge(label: 'Save ${formatPercent(product.discountPercentage)}'),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          StockBadge(stock: product.stock),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
