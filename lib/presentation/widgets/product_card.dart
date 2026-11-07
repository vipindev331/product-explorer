import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import 'app_network_image.dart';
import 'discount_badge.dart';
import 'price_tag.dart';

/// Shared Hero tag so the image flies from the card to the details gallery.
String productHeroTag(int productId) => 'product-image-$productId';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedLabel = theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);

    return Semantics(
      button: true,
      label: '${product.title}, ${formatPrice(product.discountedPrice)}, '
          'rated ${product.rating.toStringAsFixed(1)} out of 5',
      excludeSemantics: true,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                        child: Hero(
                          tag: productHeroTag(product.id),
                          child: AppNetworkImage(
                            url: product.thumbnail,
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ),
                    if (product.hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: DiscountBadge(
                          label: '-${formatPercent(product.discountPercentage)}',
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      humanize(product.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.rating),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (product.brand != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              product.brand!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mutedLabel,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    PriceTag(
                      price: product.discountedPrice,
                      originalPrice: product.hasDiscount ? product.price : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
