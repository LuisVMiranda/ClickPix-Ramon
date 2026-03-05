import 'dart:math';

import 'package:clickpix_ramon/domain/entities/photo_package.dart';

class BuildOrderPricing {
  const BuildOrderPricing();

  OrderPricingBreakdown call({
    required int photoCount,
    required PhotoPackage package,
  }) {
    if (photoCount <= 0) {
      throw ArgumentError.value(photoCount, 'photoCount', 'must be greater than zero');
    }

    final packageMultiplier = (photoCount / package.quantity).ceil();
    final subtotalCents = packageMultiplier * package.priceCents;

    final discount = package.discountRule;
    final hasAutomaticDiscount =
        discount != null && photoCount >= discount.minimumQuantity && discount.percentage > 0;

    final discountAmountCents = hasAutomaticDiscount
        ? (subtotalCents * discount.percentage / 100).round()
        : 0;
    final totalCents = max(0, subtotalCents - discountAmountCents);

    return OrderPricingBreakdown(
      photoCount: photoCount,
      packageQuantity: package.quantity,
      subtotalCents: subtotalCents,
      discountAmountCents: discountAmountCents,
      totalCents: totalCents,
      hasAutomaticDiscount: hasAutomaticDiscount,
    );
  }
}

class OrderPricingBreakdown {
  const OrderPricingBreakdown({
    required this.photoCount,
    required this.packageQuantity,
    required this.subtotalCents,
    required this.discountAmountCents,
    required this.totalCents,
    required this.hasAutomaticDiscount,
  });

  final int photoCount;
  final int packageQuantity;
  final int subtotalCents;
  final int discountAmountCents;
  final int totalCents;
  final bool hasAutomaticDiscount;
}
