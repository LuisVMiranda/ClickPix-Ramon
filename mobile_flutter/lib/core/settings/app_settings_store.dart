import 'dart:convert';

import 'package:clickpix_ramon/core/settings/watermark_config.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

class AppSettingsStore {
  AppSettingsStore(this._database);

  final AppDatabase _database;

  static const Locale defaultLocale = Locale('pt', 'BR');
  static const String defaultAdminUsername = 'admin';
  static const String defaultAccentColorKey = 'blue_mid';
  static const Set<String> supportedAccentColorKeys = {
    'blue_light',
    'blue_mid',
    'blue_dark',
    'green_light',
    'green_mid',
    'green_dark',
    'orange_light',
    'orange_mid',
    'orange_dark',
    'gray_light',
    'gray_mid',
    'gray_dark',
    'red_light',
    'red_mid',
    'red_dark',
    'brown_light',
    'brown_mid',
    'brown_dark',
  };
  static const String _defaultAdminPasswordHash =
      '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9';

  Future<Locale> loadLocale() async {
    final row = await _loadSettingsRow();
    final rawLanguage = row?.language;
    if (rawLanguage == null || rawLanguage.isEmpty) {
      return defaultLocale;
    }

    return _localeFromStorage(rawLanguage);
  }

  Future<void> saveLocale(Locale locale) async {
    await _saveSettings(
      AppSettingsCompanion(
        language: Value(_localeToStorage(locale)),
      ),
    );
  }

  Future<AppVisualSettings> loadVisualSettings() async {
    final row = await _loadSettingsRow();
    return AppVisualSettings(
      highContrastEnabled: row?.highContrastEnabled ?? false,
      solarLargeFontEnabled: row?.solarLargeFontEnabled ?? false,
      themeMode: _themeModeFromStorage(row?.themeMode),
      accentColorKey: _accentColorKeyFromStorage(row?.accentColorKey),
    );
  }

  Future<void> saveVisualSettings(AppVisualSettings settings) async {
    await _saveSettings(
      AppSettingsCompanion(
        highContrastEnabled: Value(settings.highContrastEnabled),
        solarLargeFontEnabled: Value(settings.solarLargeFontEnabled),
        themeMode: Value(_themeModeToStorage(settings.themeMode)),
        accentColorKey:
            Value(_accentColorKeyFromStorage(settings.accentColorKey)),
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
    await _saveSettings(
      AppSettingsCompanion(
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
    await _saveSettings(
      AppSettingsCompanion(
        watermarkConfigJson: Value(config.toJson()),
      ),
    );
  }

  Future<AdminCredentialsSettings> loadAdminCredentials() async {
    final row = await _loadSettingsRow();
    return AdminCredentialsSettings(
      username: row?.adminUsername ?? defaultAdminUsername,
      passwordHash: row?.adminPasswordHash ?? _defaultAdminPasswordHash,
    );
  }

  Future<bool> verifyAdminLogin({
    required String username,
    required String password,
  }) async {
    final credentials = await loadAdminCredentials();
    final sanitizedUsername = username.trim();
    if (sanitizedUsername.isEmpty) {
      return false;
    }

    return credentials.username == sanitizedUsername &&
        credentials.passwordHash == _hashPassword(password);
  }

  Future<bool> resetAdminPasswordWithEmail({
    required String username,
    required String recoveryEmail,
    required String newPassword,
  }) async {
    final credentials = await loadAdminCredentials();
    final profile = await loadBusinessProfile();
    final normalizedUsername = username.trim();
    final normalizedEmail = recoveryEmail.trim().toLowerCase();
    final registeredEmail = profile.photographerEmail.trim().toLowerCase();
    final normalizedPassword = newPassword.trim();

    if (normalizedUsername.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty ||
        registeredEmail.isEmpty) {
      return false;
    }

    if (credentials.username != normalizedUsername ||
        normalizedEmail != registeredEmail) {
      return false;
    }

    await saveAdminCredentials(
      username: credentials.username,
      newPassword: newPassword,
    );
    return true;
  }

  Future<void> saveAdminCredentials({
    required String username,
    required String newPassword,
  }) async {
    final sanitizedUsername = username.trim();
    if (sanitizedUsername.isEmpty || newPassword.trim().isEmpty) {
      throw ArgumentError('Credenciais de administrador inválidas.');
    }

    await _saveSettings(
      AppSettingsCompanion(
        adminUsername: Value(sanitizedUsername),
        adminPasswordHash: Value(_hashPassword(newPassword)),
      ),
    );
  }

  Future<BusinessProfileSettings> loadBusinessProfile() async {
    final row = await _loadSettingsRow();
    return BusinessProfileSettings(
      photographerName: row?.photographerName ?? 'Fotógrafo',
      photographerWhatsapp: row?.photographerWhatsapp ?? '',
      photographerEmail: row?.photographerEmail ?? '',
      photographerPixKey: row?.photographerPixKey ?? '',
      photographerPaypal: row?.photographerPaypal ?? '',
    );
  }

  Future<void> saveBusinessProfile(BusinessProfileSettings profile) async {
    await _saveSettings(
      AppSettingsCompanion(
        photographerName: Value(profile.photographerName.trim()),
        photographerWhatsapp: Value(profile.photographerWhatsapp.trim()),
        photographerEmail: Value(profile.photographerEmail.trim()),
        photographerPixKey: Value(profile.photographerPixKey.trim()),
        photographerPaypal: Value(profile.photographerPaypal.trim()),
      ),
    );
  }

  Future<PaymentIntegrationSettings> loadPaymentIntegrationSettings() async {
    final row = await _loadSettingsRow();
    return PaymentIntegrationSettings(
      provider: PaymentProviderX.fromStorage(row?.paymentProvider),
      apiBaseUrl: row?.paymentApiBaseUrl ?? '',
      apiToken: row?.paymentApiToken ?? '',
    );
  }

  Future<void> savePaymentIntegrationSettings(
    PaymentIntegrationSettings settings,
  ) async {
    await _saveSettings(
      AppSettingsCompanion(
        paymentProvider: Value(settings.provider.toStorage()),
        paymentApiBaseUrl: Value(settings.apiBaseUrl.trim()),
        paymentApiToken: Value(settings.apiToken.trim()),
      ),
    );
  }

  Future<String> loadPreferredInputFolder() async {
    final row = await _loadSettingsRow();
    return row?.preferredInputFolder ?? '';
  }

  Future<void> savePreferredInputFolder(String folderPath) async {
    await _saveSettings(
      AppSettingsCompanion(
        preferredInputFolder: Value(folderPath.trim()),
      ),
    );
  }

  Future<List<PictureComboPricing>> loadPictureCombos() async {
    final row = await _loadSettingsRow();
    final rawJson = row?.pictureCombosJson ?? '[]';
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      return const [];
    }

    final combos = decoded
        .whereType<Map>()
        .map(
          (raw) => raw.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .map(PictureComboPricing.fromJson)
        .where(
          (combo) =>
              combo.name.trim().isNotEmpty &&
              combo.minimumPhotos > 0 &&
              combo.unitPriceCents > 0,
        )
        .toList(growable: false);

    final sorted = [...combos]
      ..sort((a, b) => a.minimumPhotos.compareTo(b.minimumPhotos));
    return sorted;
  }

  Future<void> savePictureCombos(List<PictureComboPricing> combos) async {
    final cleaned = combos
        .where(
          (combo) =>
              combo.name.trim().isNotEmpty &&
              combo.minimumPhotos > 0 &&
              combo.unitPriceCents > 0,
        )
        .toList(growable: false);
    final rawJson = jsonEncode(
      cleaned.map((combo) => combo.toJson()).toList(growable: false),
    );
    await _saveSettings(
      AppSettingsCompanion(
        pictureCombosJson: Value(rawJson),
      ),
    );
  }

  Future<String> loadLastSelectedPictureComboId() async {
    final row = await _loadSettingsRow();
    return row?.lastSelectedPictureComboId ?? '';
  }

  Future<void> saveLastSelectedPictureComboId(String comboId) async {
    await _saveSettings(
      AppSettingsCompanion(
        lastSelectedPictureComboId: Value(comboId.trim()),
      ),
    );
  }

  Future<List<DeliveryHistoryEntry>> loadDeliveryHistory() async {
    final row = await _loadSettingsRow();
    final rawJson = row?.deliveryHistoryJson ?? '[]';
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      return const [];
    }

    final entries = decoded
        .whereType<Map<String, dynamic>>()
        .map(DeliveryHistoryEntry.fromJson)
        .toList(growable: false);

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> appendDeliveryHistory(DeliveryHistoryEntry entry) async {
    final current = await loadDeliveryHistory();
    final next = <DeliveryHistoryEntry>[entry, ...current]
        .take(100)
        .toList(growable: false);
    final rawJson =
        jsonEncode(next.map((item) => item.toJson()).toList(growable: false));

    await _saveSettings(
      AppSettingsCompanion(
        deliveryHistoryJson: Value(rawJson),
      ),
    );
  }

  Future<void> clearDeliveryHistory() async {
    await _saveSettings(
      const AppSettingsCompanion(
        deliveryHistoryJson: Value('[]'),
      ),
    );
  }

  Future<void> _saveSettings(AppSettingsCompanion changes) async {
    final rows = await (_database.update(_database.appSettings)
          ..where((tbl) => tbl.id.equals(1)))
        .write(changes);
    if (rows > 0) {
      return;
    }

    await _database.into(_database.appSettings).insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            language: changes.language,
            wifiOnly: changes.wifiOnly,
            accessCodeValidityDays: changes.accessCodeValidityDays,
            watermarkConfigJson: changes.watermarkConfigJson,
            highContrastEnabled: changes.highContrastEnabled,
            solarLargeFontEnabled: changes.solarLargeFontEnabled,
            themeMode: changes.themeMode,
            accentColorKey: changes.accentColorKey,
            adminUsername: changes.adminUsername,
            adminPasswordHash: changes.adminPasswordHash,
            photographerName: changes.photographerName,
            photographerWhatsapp: changes.photographerWhatsapp,
            photographerEmail: changes.photographerEmail,
            photographerPixKey: changes.photographerPixKey,
            photographerPaypal: changes.photographerPaypal,
            paymentProvider: changes.paymentProvider,
            paymentApiBaseUrl: changes.paymentApiBaseUrl,
            paymentApiToken: changes.paymentApiToken,
            deliveryHistoryJson: changes.deliveryHistoryJson,
            preferredInputFolder: changes.preferredInputFolder,
            pictureCombosJson: changes.pictureCombosJson,
            lastSelectedPictureComboId: changes.lastSelectedPictureComboId,
          ),
        );
  }

  Future<AppSetting?> _loadSettingsRow() {
    return (_database.select(
      _database.appSettings,
    )..where((tbl) => tbl.id.equals(1)))
        .getSingleOrNull();
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

  String _accentColorKeyFromStorage(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.startsWith('teal_')) {
      return defaultAccentColorKey;
    }
    if (supportedAccentColorKeys.contains(normalized)) {
      final parts = normalized.split('_');
      if (parts.length == 2) {
        return '${parts.first}_mid';
      }
      return normalized;
    }
    return defaultAccentColorKey;
  }

  String _hashPassword(String rawPassword) {
    return sha256.convert(utf8.encode(rawPassword.trim())).toString();
  }
}

enum PaymentProvider {
  manual,
  bancoDoBrasil,
  itau,
  bradesco,
  santander,
  caixa,
  inter,
  nubank,
  sicredi,
  sicoob,
  c6Bank,
  mercadoPago,
  outro,
}

extension PaymentProviderX on PaymentProvider {
  static PaymentProvider fromStorage(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'banco_do_brasil':
        return PaymentProvider.bancoDoBrasil;
      case 'itau':
        return PaymentProvider.itau;
      case 'bradesco':
        return PaymentProvider.bradesco;
      case 'santander':
        return PaymentProvider.santander;
      case 'caixa':
        return PaymentProvider.caixa;
      case 'inter':
        return PaymentProvider.inter;
      case 'nubank':
        return PaymentProvider.nubank;
      case 'sicredi':
        return PaymentProvider.sicredi;
      case 'sicoob':
        return PaymentProvider.sicoob;
      case 'c6_bank':
        return PaymentProvider.c6Bank;
      case 'mercado_pago':
        return PaymentProvider.mercadoPago;
      case 'outro':
      case 'custom':
        return PaymentProvider.outro;
      case 'manual':
      default:
        return PaymentProvider.manual;
    }
  }

  String toStorage() {
    switch (this) {
      case PaymentProvider.bancoDoBrasil:
        return 'banco_do_brasil';
      case PaymentProvider.itau:
        return 'itau';
      case PaymentProvider.bradesco:
        return 'bradesco';
      case PaymentProvider.santander:
        return 'santander';
      case PaymentProvider.caixa:
        return 'caixa';
      case PaymentProvider.inter:
        return 'inter';
      case PaymentProvider.nubank:
        return 'nubank';
      case PaymentProvider.sicredi:
        return 'sicredi';
      case PaymentProvider.sicoob:
        return 'sicoob';
      case PaymentProvider.c6Bank:
        return 'c6_bank';
      case PaymentProvider.mercadoPago:
        return 'mercado_pago';
      case PaymentProvider.outro:
        return 'outro';
      case PaymentProvider.manual:
        return 'manual';
    }
  }
}

class PaymentIntegrationSettings {
  const PaymentIntegrationSettings({
    this.provider = PaymentProvider.manual,
    this.apiBaseUrl = '',
    this.apiToken = '',
  });

  final PaymentProvider provider;
  final String apiBaseUrl;
  final String apiToken;

  bool get isApiEnabled =>
      provider != PaymentProvider.manual && apiBaseUrl.trim().isNotEmpty;

  PaymentIntegrationSettings copyWith({
    PaymentProvider? provider,
    String? apiBaseUrl,
    String? apiToken,
  }) {
    return PaymentIntegrationSettings(
      provider: provider ?? this.provider,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiToken: apiToken ?? this.apiToken,
    );
  }
}

class AppVisualSettings {
  const AppVisualSettings({
    this.highContrastEnabled = false,
    this.solarLargeFontEnabled = false,
    this.themeMode = ThemeMode.system,
    this.accentColorKey = AppSettingsStore.defaultAccentColorKey,
  });

  final bool highContrastEnabled;
  final bool solarLargeFontEnabled;
  final ThemeMode themeMode;
  final String accentColorKey;

  AppVisualSettings copyWith({
    bool? highContrastEnabled,
    bool? solarLargeFontEnabled,
    ThemeMode? themeMode,
    String? accentColorKey,
  }) {
    return AppVisualSettings(
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      solarLargeFontEnabled:
          solarLargeFontEnabled ?? this.solarLargeFontEnabled,
      themeMode: themeMode ?? this.themeMode,
      accentColorKey: accentColorKey ?? this.accentColorKey,
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
      accessCodeValidityDays:
          accessCodeValidityDays ?? this.accessCodeValidityDays,
    );
  }
}

class AdminCredentialsSettings {
  const AdminCredentialsSettings({
    required this.username,
    required this.passwordHash,
  });

  final String username;
  final String passwordHash;
}

class BusinessProfileSettings {
  const BusinessProfileSettings({
    required this.photographerName,
    required this.photographerWhatsapp,
    required this.photographerEmail,
    required this.photographerPixKey,
    required this.photographerPaypal,
  });

  final String photographerName;
  final String photographerWhatsapp;
  final String photographerEmail;
  final String photographerPixKey;
  final String photographerPaypal;

  BusinessProfileSettings copyWith({
    String? photographerName,
    String? photographerWhatsapp,
    String? photographerEmail,
    String? photographerPixKey,
    String? photographerPaypal,
  }) {
    return BusinessProfileSettings(
      photographerName: photographerName ?? this.photographerName,
      photographerWhatsapp: photographerWhatsapp ?? this.photographerWhatsapp,
      photographerEmail: photographerEmail ?? this.photographerEmail,
      photographerPixKey: photographerPixKey ?? this.photographerPixKey,
      photographerPaypal: photographerPaypal ?? this.photographerPaypal,
    );
  }
}

class DeliveryHistoryEntry {
  const DeliveryHistoryEntry({
    required this.id,
    required this.orderId,
    required this.clientName,
    required this.clientWhatsapp,
    required this.clientEmail,
    required this.channel,
    required this.paymentRequired,
    required this.paymentMethodLabel,
    required this.photoCount,
    required this.totalAmountCents,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String clientName;
  final String clientWhatsapp;
  final String clientEmail;
  final String channel;
  final bool paymentRequired;
  final String paymentMethodLabel;
  final int photoCount;
  final int totalAmountCents;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'clientName': clientName,
      'clientWhatsapp': clientWhatsapp,
      'clientEmail': clientEmail,
      'channel': channel,
      'paymentRequired': paymentRequired,
      'paymentMethodLabel': paymentMethodLabel,
      'photoCount': photoCount,
      'totalAmountCents': totalAmountCents,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeliveryHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] as String?;
    return DeliveryHistoryEntry(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientWhatsapp: json['clientWhatsapp'] as String? ?? '',
      clientEmail: json['clientEmail'] as String? ?? '',
      channel: json['channel'] as String? ?? 'desconhecido',
      paymentRequired: json['paymentRequired'] == true,
      paymentMethodLabel:
          json['paymentMethodLabel'] as String? ?? 'Não informado',
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
      totalAmountCents: (json['totalAmountCents'] as num?)?.toInt() ?? 0,
      createdAt: rawCreatedAt == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(rawCreatedAt) ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class PictureComboPricing {
  const PictureComboPricing({
    required this.id,
    required this.name,
    required this.minimumPhotos,
    required this.unitPriceCents,
  });

  final String id;
  final String name;
  final int minimumPhotos;
  final int unitPriceCents;

  PictureComboPricing copyWith({
    String? id,
    String? name,
    int? minimumPhotos,
    int? unitPriceCents,
  }) {
    return PictureComboPricing(
      id: id ?? this.id,
      name: name ?? this.name,
      minimumPhotos: minimumPhotos ?? this.minimumPhotos,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'minimumPhotos': minimumPhotos,
      'unitPriceCents': unitPriceCents,
    };
  }

  factory PictureComboPricing.fromJson(Map<String, dynamic> json) {
    return PictureComboPricing(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      minimumPhotos: (json['minimumPhotos'] as num?)?.toInt() ?? 0,
      unitPriceCents: (json['unitPriceCents'] as num?)?.toInt() ?? 0,
    );
  }
}

