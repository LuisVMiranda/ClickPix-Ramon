import 'dart:convert';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:http/http.dart' as http;

class PaymentChargeSession {
  const PaymentChargeSession({
    required this.chargeId,
    required this.pixCode,
    required this.status,
    this.statusUrl,
  });

  final String chargeId;
  final String pixCode;
  final String status;
  final String? statusUrl;
}

class PaymentChargeStatus {
  const PaymentChargeStatus({
    required this.status,
    required this.paid,
  });

  final String status;
  final bool paid;
}

class PaymentIntegrationClient {
  PaymentIntegrationClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<PaymentChargeSession?> createPixCharge({
    required PaymentIntegrationSettings settings,
    required String orderId,
    required String txid,
    required int amountCents,
    required String pixKey,
    required String payerName,
    required String payerWhatsapp,
    required String payerEmail,
    required String description,
  }) async {
    if (!settings.isApiEnabled) {
      return null;
    }

    final url = Uri.parse('${settings.apiBaseUrl}/pix/charges');
    final response = await _client.post(
      url,
      headers: _headers(settings),
      body: jsonEncode({
        'provider': settings.provider.toStorage(),
        'orderId': orderId,
        'txid': txid,
        'amountCents': amountCents,
        'pixKey': pixKey,
        'description': description,
        'payer': {
          'name': payerName,
          'whatsapp': payerWhatsapp,
          'email': payerEmail,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final chargeId = _firstString(decoded, ['chargeId', 'id', 'txid']);
    final pixCode = _firstString(decoded, [
      'pixCode',
      'brCode',
      'copyPaste',
      'payload'
    ]);
    if (chargeId.isEmpty || pixCode.isEmpty) {
      return null;
    }

    return PaymentChargeSession(
      chargeId: chargeId,
      pixCode: pixCode,
      status: _firstString(decoded, ['status'], fallback: 'pending'),
      statusUrl: _firstString(decoded, ['statusUrl', 'pollUrl']).isEmpty
          ? null
          : _firstString(decoded, ['statusUrl', 'pollUrl']),
    );
  }

  Future<PaymentChargeStatus?> fetchPixStatus({
    required PaymentIntegrationSettings settings,
    required PaymentChargeSession session,
  }) async {
    if (!settings.isApiEnabled) {
      return null;
    }

    final statusUri = session.statusUrl != null && session.statusUrl!.isNotEmpty
        ? Uri.tryParse(session.statusUrl!)
        : Uri.parse('${settings.apiBaseUrl}/pix/charges/${session.chargeId}');
    if (statusUri == null) {
      return null;
    }

    final response = await _client.get(
      statusUri,
      headers: _headers(settings),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final status = _firstString(decoded, ['status'], fallback: 'unknown');
    final paidFlag = decoded['paid'] == true ||
        decoded['isPaid'] == true ||
        _paidStatuses.contains(status.toLowerCase());

    return PaymentChargeStatus(
      status: status,
      paid: paidFlag,
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

  static const Set<String> _paidStatuses = {
    'paid',
    'approved',
    'completed',
    'settled',
    'succeeded',
  };
}
