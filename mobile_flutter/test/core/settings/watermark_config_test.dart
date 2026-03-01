import 'package:clickpix_ramon/core/settings/watermark_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WatermarkConfig', () {
    test('accepts supported format when enabled', () {
      const config = WatermarkConfig(enabled: true, fileName: 'brand_logo.PNG');

      expect(() => config.validate(), returnsNormally);
    });

    test('throws for unsupported format when enabled', () {
      const config = WatermarkConfig(enabled: true, fileName: 'brand_logo.gif');

      expect(() => config.validate(), throwsFormatException);
    });
  });
}
