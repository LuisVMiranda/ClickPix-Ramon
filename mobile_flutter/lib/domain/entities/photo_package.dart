class PhotoPackage {
  const PhotoPackage({
    required this.quantity,
    required this.priceCents,
    this.discountRule,
  }) : assert(quantity > 0, 'quantity must be greater than zero'),
       assert(priceCents >= 0, 'priceCents cannot be negative');

  final int quantity;
  final int priceCents;
  final DiscountRule? discountRule;
}

class DiscountRule {
  const DiscountRule({
    required this.minimumQuantity,
    required this.percentage,
  }) : assert(minimumQuantity > 0, 'minimumQuantity must be greater than zero'),
       assert(percentage >= 0 && percentage <= 100, 'percentage must be between 0 and 100');

  final int minimumQuantity;
  final double percentage;
}
