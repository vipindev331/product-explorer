import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (stock) {
      <= 0 => (AppColors.danger, 'Out of stock', Icons.remove_shopping_cart_outlined),
      < 10 => (AppColors.warning, 'Only $stock left', Icons.hourglass_bottom_rounded),
      _ => (AppColors.success, 'In stock', Icons.check_circle_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
