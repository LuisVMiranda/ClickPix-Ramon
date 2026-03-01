import 'package:clickpix_ramon/domain/entities/photo_package.dart';
import 'package:clickpix_ramon/domain/use_cases/build_order_pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildOrderPricing', () {
    const useCase = BuildOrderPricing();
    const package = PhotoPackage(
      quantity: 5,
      priceCents: 5000,
      discountRule: DiscountRule(minimumQuantity: 10, percentage: 10),
    );

    test('calculates total for 1 photo without discount', () {
      final pricing = useCase(photoCount: 1, package: package);

      expect(pricing.subtotalCents, 5000);
      expect(pricing.discountAmountCents, 0);
      expect(pricing.totalCents, 5000);
      expect(pricing.hasAutomaticDiscount, isFalse);
    });

    test('calculates total for 5 photos without discount', () {
      final pricing = useCase(photoCount: 5, package: package);

      expect(pricing.subtotalCents, 5000);
      expect(pricing.discountAmountCents, 0);
      expect(pricing.totalCents, 5000);
      expect(pricing.hasAutomaticDiscount, isFalse);
    });

    test('calculates total for 10 photos with automatic discount', () {
      final pricing = useCase(photoCount: 10, package: package);

      expect(pricing.subtotalCents, 10000);
      expect(pricing.discountAmountCents, 1000);
      expect(pricing.totalCents, 9000);
      expect(pricing.hasAutomaticDiscount, isTrue);
    });
  });
}
