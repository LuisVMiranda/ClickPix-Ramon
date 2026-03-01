import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettingsStore', () {
    late AppDatabase database;
    late AppSettingsStore store;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      store = AppSettingsStore(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('persiste wifiOnly e accessCodeValidityDays', () async {
      await store.saveDeliverySettings(
        const AppDeliverySettings(wifiOnly: true, accessCodeValidityDays: 14),
      );

      final loaded = await store.loadDeliverySettings();
      expect(loaded.wifiOnly, isTrue);
      expect(loaded.accessCodeValidityDays, 14);
    });



    test('faz fallback de locale e theme inválidos para padrões seguros', () async {
      await database.into(database.appSettings).insert(
            const AppSettingsCompanion.insert(
              id: Value(1),
              language: 'fr-FR',
              themeMode: Value('sepia'),
            ),
          );

      final locale = await store.loadLocale();
      final visual = await store.loadVisualSettings();

      expect(locale.languageCode, 'pt');
      expect(locale.countryCode, 'BR');
      expect(visual.themeMode, ThemeMode.system);
    });

    test('persiste ThemeMode em visual settings', () async {
      await store.saveVisualSettings(
        const AppVisualSettings(
          highContrastEnabled: true,
          solarLargeFontEnabled: true,
          themeMode: ThemeMode.dark,
        ),
      );

      final loaded = await store.loadVisualSettings();
      expect(loaded.highContrastEnabled, isTrue);
      expect(loaded.solarLargeFontEnabled, isTrue);
      expect(loaded.themeMode, ThemeMode.dark);
    });
  });
}
