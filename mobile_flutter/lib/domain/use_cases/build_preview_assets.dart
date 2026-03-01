import 'package:clickpix_ramon/core/settings/watermark_config.dart';
import 'package:clickpix_ramon/domain/entities/order.dart';

class BuildPreviewAssets {
  const BuildPreviewAssets();

  PreviewAsset call({
    required String previewPath,
    required OrderStatus orderStatus,
    required WatermarkConfig watermarkConfig,
  }) {
    final shouldApplyWatermark =
        orderStatus != OrderStatus.paid &&
        orderStatus != OrderStatus.delivering &&
        orderStatus != OrderStatus.delivered &&
        watermarkConfig.enabled;

    return PreviewAsset(
      originalPath: previewPath,
      shouldApplyWatermark: shouldApplyWatermark,
      watermarkFileName: shouldApplyWatermark ? watermarkConfig.fileName : null,
    );
  }
}

class PreviewAsset {
  const PreviewAsset({
    required this.originalPath,
    required this.shouldApplyWatermark,
    required this.watermarkFileName,
  });

  final String originalPath;
  final bool shouldApplyWatermark;
  final String? watermarkFileName;
}
