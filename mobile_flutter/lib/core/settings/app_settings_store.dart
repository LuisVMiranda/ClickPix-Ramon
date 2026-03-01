import 'dart:ui';

import 'package:clickpix_ramon/core/settings/watermark_config.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/drift.dart';

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
    );
  }

  Future<void> saveVisualSettings(AppVisualSettings settings) async {
    await _database.into(_database.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            id: const Value(1),
            highContrastEnabled: Value(settings.highContrastEnabled),
            solarLargeFontEnabled: Value(settings.solarLargeFontEnabled),
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
}

class AppVisualSettings {
  const AppVisualSettings({
    required this.highContrastEnabled,
    required this.solarLargeFontEnabled,
  });

  final bool highContrastEnabled;
  final bool solarLargeFontEnabled;

  AppVisualSettings copyWith({
    bool? highContrastEnabled,
    bool? solarLargeFontEnabled,
  }) {
    return AppVisualSettings(
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      solarLargeFontEnabled: solarLargeFontEnabled ?? this.solarLargeFontEnabled,
    );
  }
}
