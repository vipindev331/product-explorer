import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Five stars with half-star precision.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = rating.clamp(0, 5).toDouble();
    return Semantics(
      label: 'Rated ${value.toStringAsFixed(1)} out of 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final IconData icon;
            if (value >= index + 1) {
              icon = Icons.star_rounded;
            } else if (value >= index + 0.5) {
              icon = Icons.star_half_rounded;
            } else {
              icon = Icons.star_outline_rounded;
            }
            return Icon(icon, size: size, color: AppColors.rating);
          }),
        ),
      ),
    );
  }
}
