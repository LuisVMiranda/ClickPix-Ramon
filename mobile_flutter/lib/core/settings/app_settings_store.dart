import 'dart:ui';

import 'package:clickpix_ramon/core/settings/watermark_config.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

class AppSettingsStore {
  AppSettingsStore(this._database);

  final AppDatabase _database;

  static const Locale defaultLocale = Locale('pt', 'BR');

  Future<Locale> loadLocale() async {
    final row = await _loadSettingsRow();

    final rawLanguage = row?.language;
    if (rawLanguage == null || rawLanguage.isEmpty) {
      return defaultLocale;
    }

    return _localeFromStorage(rawLanguage);
  }

  Future<void> saveLocale(Locale locale) async {
    final languageValue = _localeToStorage(locale);
    await _database.into(_database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            language: languageValue,
          ),
        );
  }

  Future<AppVisualSettings> loadVisualSettings() async {
    final row = await _loadSettingsRow();
    return AppVisualSettings(
      highContrastEnabled: row?.highContrastEnabled ?? false,
      solarLargeFontEnabled: row?.solarLargeFontEnabled ?? false,
      themeMode: _themeModeFromStorage(row?.themeMode),
    );
  }

  Future<void> saveVisualSettings(AppVisualSettings settings) async {
    await _database.into(_database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            highContrastEnabled: Value(settings.highContrastEnabled),
            solarLargeFontEnabled: Value(settings.solarLargeFontEnabled),
            themeMode: Value(_themeModeToStorage(settings.themeMode)),
          ),
        );
  }

  Future<AppDeliverySettings> loadDeliverySettings() async {
    final row = await _loadSettingsRow();
    return AppDeliverySettings(
      wifiOnly: row?.wifiOnly ?? false,
      accessCodeValidityDays: row?.accessCodeValidityDays ?? 7,
    );
  }

  Future<void> saveDeliverySettings(AppDeliverySettings settings) async {
    await _database.into(_database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            wifiOnly: Value(settings.wifiOnly),
            accessCodeValidityDays: Value(settings.accessCodeValidityDays),
          ),
        );
  }

  Future<WatermarkConfig> loadWatermarkConfig() async {
    final row = await _loadSettingsRow();
    final rawValue = row?.watermarkConfigJson ?? '{}';
    return WatermarkConfig.fromJson(rawValue);
  }

  Future<void> saveWatermarkConfig(WatermarkConfig config) async {
    config.validate();
    await _database.into(_database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            watermarkConfigJson: config.toJson(),
          ),
        );
  }

  Future<AppSetting?> _loadSettingsRow() {
    return (_database.select(
      _database.appSettings,
    )..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
  }

  Locale _localeFromStorage(String value) {
    final normalized = value.replaceAll('_', '-');
    if (normalized.toLowerCase() == 'pt-br') {
      return defaultLocale;
    }
    if (normalized == 'en') {
      return const Locale('en');
    }
    if (normalized == 'es') {
      return const Locale('es');
    }

    return defaultLocale;
  }

  String _localeToStorage(Locale locale) {
    if (locale.languageCode == 'pt') {
      return 'pt-BR';
    }
    if (locale.languageCode == 'en') {
      return 'en';
    }
    if (locale.languageCode == 'es') {
      return 'es';
    }

    return 'pt-BR';
  }

  ThemeMode _themeModeFromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

class AppVisualSettings {
  const AppVisualSettings({
    this.highContrastEnabled = false,
    this.solarLargeFontEnabled = false,
    this.themeMode = ThemeMode.system,
  });

  final bool highContrastEnabled;
  final bool solarLargeFontEnabled;
  final ThemeMode themeMode;

  AppVisualSettings copyWith({
    bool? highContrastEnabled,
    bool? solarLargeFontEnabled,
    ThemeMode? themeMode,
  }) {
    return AppVisualSettings(
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      solarLargeFontEnabled: solarLargeFontEnabled ?? this.solarLargeFontEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppDeliverySettings {
  const AppDeliverySettings({
    required this.wifiOnly,
    required this.accessCodeValidityDays,
  });

  final bool wifiOnly;
  final int accessCodeValidityDays;

  AppDeliverySettings copyWith({
    bool? wifiOnly,
    int? accessCodeValidityDays,
  }) {
    return AppDeliverySettings(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      accessCodeValidityDays: accessCodeValidityDays ?? this.accessCodeValidityDays,
    );
  }
}
