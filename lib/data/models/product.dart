import '../../core/utils/formatters.dart';
import '../../core/utils/json_parsing.dart';

/// A product as returned by `GET /products` and `GET /products/{id}`.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    this.images = const [],
    this.tags = const [],
    this.reviews = const [],
    this.brand,
    this.sku,
    this.weight,
    this.dimensions,
    this.warrantyInformation,
    this.shippingInformation,
    this.availabilityStatus,
    this.returnPolicy,
    this.minimumOrderQuantity,
    this.meta,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final dimensions = asMapOrNull(json['dimensions']);
    final meta = asMapOrNull(json['meta']);
    return Product(
      id: asInt(json['id']),
      title: asString(json['title'], fallback: 'Untitled product'),
      description: asString(json['description']),
      category: asString(json['category'], fallback: 'uncategorised'),
      price: asDouble(json['price']),
      discountPercentage: asDouble(json['discountPercentage']),
      rating: asDouble(json['rating']),
      stock: asInt(json['stock']),
      thumbnail: asString(json['thumbnail']),
      images: asStringList(json['images']),
      tags: asStringList(json['tags']),
      reviews: asMapList(json['reviews']).map(ProductReview.fromJson).toList(),
      brand: asStringOrNull(json['brand']),
      sku: asStringOrNull(json['sku']),
      weight: asDoubleOrNull(json['weight']),
      dimensions: dimensions == null ? null : ProductDimensions.fromJson(dimensions),
      warrantyInformation: asStringOrNull(json['warrantyInformation']),
      shippingInformation: asStringOrNull(json['shippingInformation']),
      availabilityStatus: asStringOrNull(json['availabilityStatus']),
      returnPolicy: asStringOrNull(json['returnPolicy']),
      minimumOrderQuantity: asIntOrNull(json['minimumOrderQuantity']),
      meta: meta == null ? null : ProductMeta.fromJson(meta),
    );
  }

  final int id;
  final String title;
  final String description;
  final String category;

  /// List price before discount.
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final List<String> tags;
  final List<ProductReview> reviews;
  final String? brand;
  final String? sku;
  final double? weight;
  final ProductDimensions? dimensions;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? availabilityStatus;
  final String? returnPolicy;
  final int? minimumOrderQuantity;
  final ProductMeta? meta;

  bool get hasDiscount => discountPercentage > 0;

  /// Price the customer pays after the discount is applied.
  double get discountedPrice => price * (1 - discountPercentage / 100);

  /// Images for the gallery, falling back to the thumbnail.
  List<String> get galleryImages {
    if (images.isNotEmpty) return images;
    return thumbnail.isEmpty ? const [] : [thumbnail];
  }

  double? get averageReviewRating {
    if (reviews.isEmpty) return null;
    final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }
}

class ProductDimensions {
  const ProductDimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  factory ProductDimensions.fromJson(Map<String, dynamic> json) =>
      ProductDimensions(
        width: asDouble(json['width']),
        height: asDouble(json['height']),
        depth: asDouble(json['depth']),
      );

  final double width;
  final double height;
  final double depth;

  String get formatted =>
      '${formatNumber(width)} × ${formatNumber(height)} × ${formatNumber(depth)}';
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.reviewerEmail,
    this.date,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
        rating: asDouble(json['rating']),
        comment: asString(json['comment']),
        reviewerName: asString(json['reviewerName'], fallback: 'Anonymous'),
        reviewerEmail: asStringOrNull(json['reviewerEmail']),
        date: asDateTimeOrNull(json['date']),
      );

  final double rating;
  final String comment;
  final String reviewerName;
  final String? reviewerEmail;
  final DateTime? date;
}

class ProductMeta {
  const ProductMeta({this.createdAt, this.updatedAt, this.barcode, this.qrCode});

  factory ProductMeta.fromJson(Map<String, dynamic> json) => ProductMeta(
        createdAt: asDateTimeOrNull(json['createdAt']),
        updatedAt: asDateTimeOrNull(json['updatedAt']),
        barcode: asStringOrNull(json['barcode']),
        qrCode: asStringOrNull(json['qrCode']),
      );

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? barcode;
  final String? qrCode;
}
