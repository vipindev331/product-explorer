import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

/// Final price, plus the struck-through original price when discounted.
class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.price,
    this.originalPrice,
    this.large = false,
  });

  final double price;
  final double? originalPrice;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;

    final priceStyle = (large ? text.headlineMedium : text.titleMedium)?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
      letterSpacing: -0.3,
    );
    final originalStyle = (large ? text.titleMedium : text.bodySmall)?.copyWith(
      color: colors.onSurfaceVariant,
      decoration: TextDecoration.lineThrough,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            formatPrice(price),
            style: priceStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (originalPrice != null) ...[
          SizedBox(width: large ? 10 : 6),
          Flexible(
            child: Text(
              formatPrice(originalPrice!),
              key: const Key('original_price'),
              style: originalStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
