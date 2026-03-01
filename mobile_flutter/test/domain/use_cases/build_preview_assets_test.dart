import 'package:clickpix_ramon/core/settings/watermark_config.dart';
import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/use_cases/build_preview_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildPreviewAssets', () {
    const useCase = BuildPreviewAssets();
    const config = WatermarkConfig(enabled: true, fileName: 'brand.png');

    test('applies watermark to pre-payment preview', () {
      final result = useCase(
        previewPath: '/tmp/preview_1.jpg',
        orderStatus: OrderStatus.awaitingPayment,
        watermarkConfig: config,
      );

      expect(result.shouldApplyWatermark, isTrue);
      expect(result.watermarkFileName, 'brand.png');
    });

    test('does not apply watermark after payment', () {
      final result = useCase(
        previewPath: '/tmp/preview_1.jpg',
        orderStatus: OrderStatus.paid,
        watermarkConfig: config,
      );

      expect(result.shouldApplyWatermark, isFalse);
      expect(result.watermarkFileName, isNull);
    });
  });
}
