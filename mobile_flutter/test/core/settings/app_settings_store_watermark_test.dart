import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/core/settings/watermark_config.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettingsStore watermark config', () {
    late AppDatabase database;
    late AppSettingsStore store;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      store = AppSettingsStore(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('persists and loads watermark config with supported format', () async {
      const config = WatermarkConfig(enabled: true, fileName: 'logo.svg');

      await store.saveWatermarkConfig(config);
      final loaded = await store.loadWatermarkConfig();

      expect(loaded.enabled, isTrue);
      expect(loaded.fileName, 'logo.svg');
    });

    test('throws when trying to persist unsupported format', () async {
      const config = WatermarkConfig(enabled: true, fileName: 'logo.gif');

      expect(() => store.saveWatermarkConfig(config), throwsFormatException);
    });
  });
}
