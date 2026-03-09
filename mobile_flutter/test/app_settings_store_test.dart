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

    test('faz fallback de locale e theme inválidos para padrões seguros',
        () async {
      await database.into(database.appSettings).insert(
            AppSettingsCompanion.insert(
              id: Value(1),
              language: Value('fr-FR'),
              themeMode: Value('sepia'),
              accentColorKey: Value('invalid'),
            ),
          );

      final locale = await store.loadLocale();
      final visual = await store.loadVisualSettings();

      expect(locale.languageCode, 'pt');
      expect(locale.countryCode, 'BR');
      expect(visual.themeMode, ThemeMode.system);
      expect(visual.accentColorKey, AppSettingsStore.defaultAccentColorKey);
    });

    test('persiste ThemeMode em visual settings', () async {
      await store.saveVisualSettings(
        const AppVisualSettings(
          highContrastEnabled: true,
          solarLargeFontEnabled: true,
          themeMode: ThemeMode.dark,
          accentColorKey: 'green_dark',
        ),
      );

      final loaded = await store.loadVisualSettings();
      expect(loaded.highContrastEnabled, isTrue);
      expect(loaded.solarLargeFontEnabled, isTrue);
      expect(loaded.themeMode, ThemeMode.dark);
      expect(loaded.accentColorKey, 'green_mid');
    });

    test('persiste e ordena combos de fotos', () async {
      await store.savePictureCombos(
        const [
          PictureComboPricing(
            id: 'combo_2',
            name: 'Combo 10',
            minimumPhotos: 10,
            unitPriceCents: 300,
          ),
          PictureComboPricing(
            id: 'combo_1',
            name: 'Combo 5',
            minimumPhotos: 5,
            unitPriceCents: 500,
          ),
        ],
      );

      final loaded = await store.loadPictureCombos();

      expect(loaded, hasLength(2));
      expect(loaded.first.minimumPhotos, 5);
      expect(loaded.last.minimumPhotos, 10);
    });

    test('persiste ultimo combo selecionado', () async {
      await store.saveLastSelectedPictureComboId('combo_2');
      final loaded = await store.loadLastSelectedPictureComboId();
      expect(loaded, 'combo_2');
    });

    test('persiste dados de perfil com paypal', () async {
      await store.saveBusinessProfile(
        const BusinessProfileSettings(
          photographerName: 'Ramon',
          photographerWhatsapp: '+5511999999999',
          photographerEmail: 'ramon@email.com',
          photographerPixKey: '11999999999',
          photographerPaypal: 'ramon@paypal.com',
        ),
      );

      final loaded = await store.loadBusinessProfile();
      expect(loaded.photographerName, 'Ramon');
      expect(loaded.photographerPaypal, 'ramon@paypal.com');
    });

    test('persiste configuração de integração de pagamentos', () async {
      await store.savePaymentIntegrationSettings(
        const PaymentIntegrationSettings(
          provider: PaymentProvider.itau,
          apiBaseUrl: 'https://api.exemplo.com',
          apiToken: 'token_123',
        ),
      );

      final loaded = await store.loadPaymentIntegrationSettings();
      expect(loaded.provider, PaymentProvider.itau);
      expect(loaded.apiBaseUrl, 'https://api.exemplo.com');
      expect(loaded.apiToken, 'token_123');
      expect(loaded.isApiEnabled, isTrue);
    });
  });
}
