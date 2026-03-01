import 'dart:convert';

class WatermarkConfig {
  const WatermarkConfig({
    required this.enabled,
    this.fileName,
  });

  static const Set<String> allowedFormats = {'jpg', 'jpeg', 'png', 'svg', 'bmp'};

  final bool enabled;
  final String? fileName;

  factory WatermarkConfig.fromJson(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const WatermarkConfig(enabled: false);
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('watermark config must be a JSON object');
    }

    final enabled = decoded['enabled'] == true;
    final fileName = decoded['fileName'] as String?;
    final config = WatermarkConfig(enabled: enabled, fileName: fileName);
    config.validate();
    return config;
  }

  String toJson() {
    validate();
    return jsonEncode({
      'enabled': enabled,
      if (fileName != null && fileName!.trim().isNotEmpty) 'fileName': fileName,
    });
  }

  void validate() {
    if (!enabled) {
      return;
    }

    final normalized = fileName?.trim();
    if (normalized == null || normalized.isEmpty) {
      throw const FormatException('fileName is required when watermark is enabled');
    }

    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == normalized.length - 1) {
      throw const FormatException('watermark fileName must include an extension');
    }

    final extension = normalized.substring(dotIndex + 1).toLowerCase();
    if (!allowedFormats.contains(extension)) {
      throw const FormatException('watermark format is not supported');
    }
  }
}
