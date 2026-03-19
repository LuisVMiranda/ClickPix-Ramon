import 'dart:convert';
import 'dart:io';

import 'package:clickpix_ramon/core/payments/payment_integration_client.dart';
import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/services/upload_queue_service.dart';
import 'package:clickpix_ramon/domain/entities/order.dart' as domain;
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

class RemoteUploadSyncGateway implements UploadSyncGateway {
  RemoteUploadSyncGateway({
    required AppDatabase database,
    required AppSettingsStore settingsStore,
    http.Client? client,
    PaymentIntegrationClient? paymentClient,
  })  : _database = database,
        _settingsStore = settingsStore,
        _client = client ?? http.Client(),
        _paymentClient = paymentClient ?? PaymentIntegrationClient();

  final AppDatabase _database;
  final AppSettingsStore _settingsStore;
  final http.Client _client;
  final PaymentIntegrationClient _paymentClient;

  @override
  Future<void> uploadOrder({required String orderId}) async {
    final orderRow = await _loadOrder(orderId);
    if (orderRow == null) {
      throw StateError('Order $orderId was not found locally.');
    }

    final remoteConfig = await _loadRemoteConfig();
    if (remoteConfig.baseUrl == null) {
      throw StateError('Configure a backend base URL before syncing orders.');
    }

    final clientRow = await _loadClient(orderRow.clientId);
    if (clientRow == null) {
      throw StateError('Client ${orderRow.clientId} was not found locally.');
    }

    final deliverySettings = await _settingsStore.loadDeliverySettings();
    final orderItems = await (_database.select(_database.orderItems)
          ..where((tbl) => tbl.orderId.equals(orderId)))
        .get();
    final assetIds = orderItems.map((item) => item.photoAssetId).toSet();
    final assetRows = await (_database.select(_database.photoAssets)
          ..where((tbl) => tbl.id.isIn(assetIds)))
        .get();
    final assetsById = <String, PhotoAsset>{
      for (final asset in assetRows) asset.id: asset,
    };

    final uploadAssets = <Map<String, dynamic>>[];
    for (final item in orderItems) {
      final assetRow = assetsById[item.photoAssetId];
      if (assetRow == null) {
        continue;
      }
      uploadAssets.add(await _buildUploadAssetPayload(assetRow));
    }

    if (uploadAssets.isEmpty) {
      throw StateError('No local assets were available to sync for $orderId.');
    }

    final response = await _client.post(
      Uri.parse('${remoteConfig.baseUrl}/orders/sync'),
      headers: remoteConfig.headers,
      body: jsonEncode({
        'expirationDays': deliverySettings.accessCodeValidityDays,
        'order': {
          'id': orderRow.id,
          'clientId': orderRow.clientId,
          'totalAmountCents': orderRow.totalAmountCents,
          'currency': orderRow.currency,
          'status': orderRow.status,
          'paymentMethod': orderRow.paymentMethod,
          'externalReference': orderRow.externalReference,
          'createdAt': orderRow.createdAt.toIso8601String(),
        },
        'client': {
          'id': clientRow.id,
          'name': clientRow.name,
          'whatsapp': clientRow.whatsapp,
          'email': clientRow.email ?? '',
        },
        'items': orderItems
            .map(
              (item) => {
                'photoAssetId': item.photoAssetId,
                'unitPriceCents': item.unitPriceCents,
              },
            )
            .toList(growable: false),
        'assets': uploadAssets,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Remote order sync failed with status ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Remote order sync returned an invalid body.');
    }

    final delivery = _asStringKeyedMap(decoded['delivery']) ?? <String, dynamic>{};
    final uploadedAssetsResponse = _assetMapsFromResponse(delivery['assets']);
    await _applyUploadedAssetPaths(
      requestedAssets: uploadAssets,
      uploadedAssets: uploadedAssetsResponse,
    );

    final existingState = OrderRemoteState.fromStorage(orderRow.providerDataJson);
    final nextState = existingState.copyWith(
      deliveryState: SyncedDeliveryState(
        accessCode: _nullableString(
              _firstString(decoded, ['accessCode', 'deliveryCode']),
            ) ??
            existingState.deliveryState?.accessCode,
        expiresAt: _nullableString(_firstString(delivery, ['expiresAt'])) ??
            existingState.deliveryState?.expiresAt,
        lockedUntilPaid: delivery['lockedUntilPaid'] == true,
      ),
    );

    await (_database.update(_database.orders)
          ..where((tbl) => tbl.id.equals(orderId)))
        .write(
      OrdersCompanion(
        providerDataJson: Value(nextState.toStorageJson()),
      ),
    );
  }

  @override
  Future<void> startPaymentIfApplicable({required String orderId}) async {
    final orderRow = await _loadOrder(orderId);
    if (orderRow == null || orderRow.totalAmountCents <= 0) {
      return;
    }

    final paymentMethod = _paymentMethodFromStorage(orderRow.paymentMethod);
    if (paymentMethod == null) {
      return;
    }

    final paymentSettings = await _settingsStore.loadPaymentIntegrationSettings();
    final canCreateRemoteSession = switch (paymentMethod) {
      domain.PaymentMethod.pix => paymentSettings.isPixApiEnabled,
      domain.PaymentMethod.paypal => paymentSettings.isPayPalApiEnabled,
      domain.PaymentMethod.card => paymentSettings.hasBackendContract,
    };
    if (!canCreateRemoteSession) {
      return;
    }

    final existingState = OrderRemoteState.fromStorage(orderRow.providerDataJson);
    if (existingState.paymentSession?.providerIntentId.trim().isNotEmpty ==
        true) {
      return;
    }

    final clientRow = await _loadClient(orderRow.clientId);
    if (clientRow == null) {
      throw StateError('Client ${orderRow.clientId} was not found locally.');
    }

    final session = await _paymentClient.createCheckoutSession(
      settings: paymentSettings,
      orderId: orderId,
      paymentMethod: paymentMethod,
      payerName: clientRow.name,
      payerWhatsapp: clientRow.whatsapp,
      payerEmail: clientRow.email ?? '',
    );
    if (session == null) {
      throw StateError('Remote checkout could not be created for $orderId.');
    }

    final nextState = existingState.copyWith(paymentSession: session);
    await (_database.update(_database.orders)
          ..where((tbl) => tbl.id.equals(orderId)))
        .write(
      OrdersCompanion(
        status: const Value('AwaitingPayment'),
        externalReference: Value(
          session.externalReference.trim().isEmpty
              ? orderRow.externalReference
              : session.externalReference,
        ),
        providerDataJson: Value(nextState.toStorageJson()),
      ),
    );
  }

  Future<Order?> _loadOrder(String orderId) {
    return (_database.select(_database.orders)
          ..where((tbl) => tbl.id.equals(orderId)))
        .getSingleOrNull();
  }

  Future<Client?> _loadClient(String clientId) {
    return (_database.select(_database.clients)
          ..where((tbl) => tbl.id.equals(clientId)))
        .getSingleOrNull();
  }

  Future<Map<String, dynamic>> _buildUploadAssetPayload(
    PhotoAsset assetRow,
  ) async {
    final file = await _resolveAssetFile(assetRow);
    if (!await file.exists()) {
      throw StateError('Local file for ${assetRow.id} is no longer available.');
    }

    final bytes = await file.readAsBytes();
    return {
      'sourceId': assetRow.id,
      'fileName': _fileNameForAsset(assetRow, file),
      'contentType': _contentTypeForPath(file.path),
      'base64Data': base64Encode(bytes),
    };
  }

  Future<File> _resolveAssetFile(PhotoAsset assetRow) async {
    final localPath = assetRow.localPath.trim();
    if (!localPath.startsWith('asset://')) {
      return File(localPath);
    }

    final assetId = localPath.substring('asset://'.length).trim();
    final entity = await AssetEntity.fromId(assetId);
    if (entity == null) {
      throw StateError('Gallery asset $assetId could not be resolved.');
    }

    try {
      final file = await entity.file;
      if (file == null) {
        throw StateError('Gallery asset $assetId has no local file.');
      }
      return file;
    } on MissingPluginException {
      throw StateError(
        'Gallery asset $assetId needs foreground access before it can sync.',
      );
    }
  }

  String _fileNameForAsset(PhotoAsset assetRow, File file) {
    final fileName = p.basename(file.path).trim();
    if (fileName.isNotEmpty) {
      return fileName;
    }

    final extension = p.extension(file.path).trim();
    final normalizedExtension = extension.isEmpty ? '.jpg' : extension;
    return '${assetRow.id}$normalizedExtension';
  }

  String _contentTypeForPath(String path) {
    final extension = p.extension(path).trim().toLowerCase();
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _applyUploadedAssetPaths({
    required List<Map<String, dynamic>> requestedAssets,
    required List<Map<String, dynamic>> uploadedAssets,
  }) async {
    final storagePathBySourceId = <String, String>{};
    for (var index = 0; index < uploadedAssets.length; index += 1) {
      final uploaded = uploadedAssets[index];
      final sourceId = _nullableString(_firstString(uploaded, ['sourceId']));
      final storagePath = _nullableString(_firstString(uploaded, ['path']));
      if (storagePath == null) {
        continue;
      }

      if (sourceId != null) {
        storagePathBySourceId[sourceId] = storagePath;
        continue;
      }

      if (index < requestedAssets.length) {
        final fallbackSourceId =
            _nullableString(_firstString(requestedAssets[index], ['sourceId']));
        if (fallbackSourceId != null) {
          storagePathBySourceId[fallbackSourceId] = storagePath;
        }
      }
    }

    for (final entry in storagePathBySourceId.entries) {
      await (_database.update(_database.photoAssets)
            ..where((tbl) => tbl.id.equals(entry.key)))
          .write(
        PhotoAssetsCompanion(
          uploadStatus: const Value('synced'),
          storagePath: Value(entry.value),
        ),
      );
    }
  }

  Future<_RemoteBackendConfig> _loadRemoteConfig() async {
    final paymentSettings = await _settingsStore.loadPaymentIntegrationSettings();
    final webAccessSettings =
        await _settingsStore.loadDeliveryWebAccessSettings();
    final baseUrl = _normalizedBaseUrl(paymentSettings.apiBaseUrl) ??
        _normalizedBaseUrl(webAccessSettings.baseDomainUrl);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (paymentSettings.apiToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${paymentSettings.apiToken.trim()}';
    } else if (webAccessSettings.dbUsername.trim().isNotEmpty &&
        webAccessSettings.dbPassword.trim().isNotEmpty) {
      final credentials = base64Encode(
        utf8.encode(
          '${webAccessSettings.dbUsername.trim()}:${webAccessSettings.dbPassword.trim()}',
        ),
      );
      headers['Authorization'] = 'Basic $credentials';
    }

    return _RemoteBackendConfig(
      baseUrl: baseUrl,
      headers: headers,
    );
  }

  String? _normalizedBaseUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized =
        trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.trim().isEmpty) {
      return null;
    }

    return normalized.replaceFirst(RegExp(r'/+$'), '');
  }

  domain.PaymentMethod? _paymentMethodFromStorage(String value) {
    for (final method in domain.PaymentMethod.values) {
      if (method.name == value.trim()) {
        return method;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _assetMapsFromResponse(Object? rawValue) {
    if (rawValue is! List) {
      return const [];
    }

    return rawValue
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }
}

class _RemoteBackendConfig {
  const _RemoteBackendConfig({
    required this.baseUrl,
    required this.headers,
  });

  final String? baseUrl;
  final Map<String, String> headers;
}

Map<String, dynamic>? _asStringKeyedMap(Object? rawValue) {
  if (rawValue is! Map) {
    return null;
  }

  return rawValue.map(
    (key, value) => MapEntry(key.toString(), value),
  );
}

String _firstString(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

String? _nullableString(String value) {
  return value.trim().isEmpty ? null : value.trim();
}
