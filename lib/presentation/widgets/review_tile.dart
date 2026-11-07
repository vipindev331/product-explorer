import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import 'rating_stars.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = review.reviewerName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colors.secondaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (review.date != null)
                    Text(
                      formatDate(review.date!),
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              RatingStars(rating: review.rating, size: 14),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(review.comment, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
