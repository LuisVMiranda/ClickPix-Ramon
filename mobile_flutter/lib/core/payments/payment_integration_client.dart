import 'dart:convert';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/domain/entities/order.dart' as domain;
import 'package:http/http.dart' as http;

class PaymentCheckoutSession {
  const PaymentCheckoutSession({
    required this.provider,
    required this.providerIntentId,
    required this.externalReference,
    required this.status,
    this.checkoutUrl,
    this.pixCode,
    this.qrCodeBase64,
  });

  final String provider;
  final String providerIntentId;
  final String externalReference;
  final String status;
  final String? checkoutUrl;
  final String? pixCode;
  final String? qrCodeBase64;

  bool get isPayPal => provider.trim().toLowerCase() == 'paypal';

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'providerIntentId': providerIntentId,
      'externalReference': externalReference,
      'status': status,
      'checkoutUrl': checkoutUrl,
      'qrCodeText': pixCode,
      'qrCodeBase64': qrCodeBase64,
    };
  }

  factory PaymentCheckoutSession.fromJson(Map<String, dynamic> json) {
    final source = _asStringKeyedMap(json['paymentIntent']) ?? json;
    final providerIntentId = _firstString(source, [
      'providerIntentId',
      'chargeId',
      'id',
    ]);
    return PaymentCheckoutSession(
      provider: _firstString(source, ['provider'], fallback: 'unknown'),
      providerIntentId: providerIntentId,
      externalReference: _firstString(
        source,
        ['externalReference', 'external_reference'],
      ),
      status: _firstString(source, ['status'], fallback: 'pending'),
      checkoutUrl: _nullableString(
        _firstString(source, ['checkoutUrl', 'approvalUrl']),
      ),
      pixCode: _nullableString(
        _firstString(source, ['qrCodeText', 'pixCode', 'brCode', 'copyPaste']),
      ),
      qrCodeBase64: _nullableString(
        _firstString(source, ['qrCodeBase64', 'pixCodeBase64']),
      ),
    );
  }
}

class PaymentCheckoutStatus {
  const PaymentCheckoutStatus({
    required this.status,
    required this.orderStatus,
    required this.paid,
    this.provider,
    this.checkoutUrl,
    this.pixCode,
    this.qrCodeBase64,
  });

  final String status;
  final String orderStatus;
  final bool paid;
  final String? provider;
  final String? checkoutUrl;
  final String? pixCode;
  final String? qrCodeBase64;
}

class SyncedDeliveryState {
  const SyncedDeliveryState({
    this.accessCode,
    this.expiresAt,
    this.lockedUntilPaid = false,
  });

  final String? accessCode;
  final String? expiresAt;
  final bool lockedUntilPaid;

  bool get hasAccessCode =>
      accessCode != null && accessCode!.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      if (accessCode != null) 'accessCode': accessCode,
      if (expiresAt != null) 'expiresAt': expiresAt,
      'lockedUntilPaid': lockedUntilPaid,
    };
  }

  factory SyncedDeliveryState.fromJson(Map<String, dynamic> json) {
    return SyncedDeliveryState(
      accessCode: _nullableString(
        _firstString(json, ['accessCode', 'code', 'deliveryCode']),
      ),
      expiresAt: _nullableString(
        _firstString(json, ['expiresAt', 'deliveryExpiresAt']),
      ),
      lockedUntilPaid: json['lockedUntilPaid'] == true,
    );
  }
}

class OrderRemoteState {
  const OrderRemoteState({
    this.paymentSession,
    this.deliveryState,
  });

  final PaymentCheckoutSession? paymentSession;
  final SyncedDeliveryState? deliveryState;

  OrderRemoteState copyWith({
    PaymentCheckoutSession? paymentSession,
    bool clearPaymentSession = false,
    SyncedDeliveryState? deliveryState,
    bool clearDeliveryState = false,
  }) {
    return OrderRemoteState(
      paymentSession:
          clearPaymentSession ? null : (paymentSession ?? this.paymentSession),
      deliveryState:
          clearDeliveryState ? null : (deliveryState ?? this.deliveryState),
    );
  }

  String toStorageJson() {
    return jsonEncode({
      if (paymentSession != null) 'paymentIntent': paymentSession!.toJson(),
      if (deliveryState != null) 'delivery': deliveryState!.toJson(),
    });
  }

  static OrderRemoteState fromStorage(String? rawJson) {
    final trimmed = rawJson?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const OrderRemoteState();
    }

    final decoded = jsonDecode(trimmed);
    if (decoded is! Map) {
      return const OrderRemoteState();
    }

    final map = decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final paymentMap = _asStringKeyedMap(map['paymentIntent']) ??
        (_looksLikePaymentIntent(map) ? map : null);
    final deliveryMap = _asStringKeyedMap(map['delivery']);

    return OrderRemoteState(
      paymentSession:
          paymentMap == null ? null : PaymentCheckoutSession.fromJson(paymentMap),
      deliveryState:
          deliveryMap == null ? null : SyncedDeliveryState.fromJson(deliveryMap),
    );
  }
}

class PaymentIntegrationClient {
  PaymentIntegrationClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<PaymentCheckoutSession?> createCheckoutSession({
    required PaymentIntegrationSettings settings,
    required String orderId,
    required domain.PaymentMethod paymentMethod,
    required String payerName,
    required String payerWhatsapp,
    required String payerEmail,
  }) async {
    if (!settings.hasBackendContract) {
      return null;
    }

    final provider = _providerForPaymentMethod(paymentMethod);
    if (provider == null) {
      return null;
    }

    final response = await _client.post(
      _uriForPath(settings.apiBaseUrl, '/orders/$orderId/payment-intents'),
      headers: _headers(settings),
      body: jsonEncode({
        'provider': provider,
        'payer': {
          'name': payerName,
          'firstName': _firstNameFromFullName(payerName),
          'lastName': _lastNameFromFullName(payerName),
          'whatsapp': payerWhatsapp,
          'email': payerEmail,
        },
        'methodData': paymentMethod == domain.PaymentMethod.pix
            ? const {'method': 'pix'}
            : const <String, String>{},
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return PaymentCheckoutSession.fromJson(decoded);
  }

  Future<PaymentCheckoutStatus?> fetchCheckoutStatus({
    required PaymentIntegrationSettings settings,
    required String orderId,
  }) async {
    if (!settings.hasBackendContract) {
      return null;
    }

    final response = await _client.get(
      _uriForPath(settings.apiBaseUrl, '/orders/$orderId/payment-status'),
      headers: _headers(settings),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return PaymentCheckoutStatus(
      status: _firstString(decoded, ['status'], fallback: 'pending'),
      orderStatus: _firstString(decoded, ['orderStatus'], fallback: 'Created'),
      paid: decoded['paid'] == true ||
          _paidStatuses.contains(
            _firstString(decoded, ['status']).trim().toLowerCase(),
          ) ||
          _paidStatuses.contains(
            _firstString(decoded, ['orderStatus']).trim().toLowerCase(),
          ),
      provider: _nullableString(_firstString(decoded, ['provider'])),
      checkoutUrl:
          _nullableString(_firstString(decoded, ['checkoutUrl', 'approvalUrl'])),
      pixCode: _nullableString(
        _firstString(decoded, ['qrCodeText', 'pixCode']),
      ),
      qrCodeBase64: _nullableString(
        _firstString(decoded, ['qrCodeBase64']),
      ),
    );
  }

  Map<String, String> _headers(PaymentIntegrationSettings settings) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (settings.apiToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${settings.apiToken.trim()}';
    }
    return headers;
  }

  Uri _uriForPath(String baseUrl, String path) {
    final normalizedBase = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  String? _providerForPaymentMethod(domain.PaymentMethod paymentMethod) {
    switch (paymentMethod) {
      case domain.PaymentMethod.pix:
      case domain.PaymentMethod.card:
        return 'mercadopago';
      case domain.PaymentMethod.paypal:
        return 'paypal';
    }
  }

  String _firstNameFromFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.trim().isEmpty) {
      return 'ClickPix';
    }
    return parts.first.trim();
  }

  String _lastNameFromFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) {
      return 'Customer';
    }
    return parts.skip(1).join(' ').trim();
  }

  static const Set<String> _paidStatuses = {
    'paid',
    'approved',
    'completed',
    'settled',
    'succeeded',
    'delivering',
    'delivered',
  };
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

bool _looksLikePaymentIntent(Map<String, dynamic> json) {
  return json.containsKey('provider') &&
      (json.containsKey('providerIntentId') ||
          json.containsKey('chargeId') ||
          json.containsKey('checkoutUrl') ||
          json.containsKey('qrCodeText'));
}
