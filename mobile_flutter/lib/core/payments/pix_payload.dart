class PixPayload {
  const PixPayload._();

  static String build({
    required String pixKey,
    required int amountCents,
    required String merchantName,
    required String merchantCity,
    String txid = '',
    String description = '',
  }) {
    final key = pixKey.trim();
    if (key.isEmpty || amountCents <= 0) {
      return '';
    }

    final amount = (amountCents / 100).toStringAsFixed(2);
    final normalizedName = _normalize(merchantName, maxLength: 25);
    final normalizedCity = _normalize(merchantCity, maxLength: 15);
    final normalizedDescription = description.trim().isEmpty
        ? ''
        : _normalize(description, maxLength: 72);
    final normalizedTxid = _normalizeTxid(txid);

    final guiField = _field('00', 'BR.GOV.BCB.PIX');
    final keyField = _field('01', key);
    final descriptionField = normalizedDescription.isEmpty
        ? ''
        : _field('02', normalizedDescription);
    final merchantAccountInfo =
        _field('26', '$guiField$keyField$descriptionField');

    final additionalData = _field(
      '62',
      _field('05', normalizedTxid),
    );

    final payload = '${_field('00', '01')}' // Payload Format Indicator
        '$merchantAccountInfo'
        '${_field('52', '0000')}' // Merchant Category Code
        '${_field('53', '986')}' // BRL
        '${_field('54', amount)}'
        '${_field('58', 'BR')}'
        '${_field('59', normalizedName.isEmpty ? 'CLICKPIX' : normalizedName)}'
        '${_field('60', normalizedCity.isEmpty ? 'SAO PAULO' : normalizedCity)}'
        '$additionalData';

    final payloadForCrc = '${payload}6304';
    final crc = _crc16Ccitt(payloadForCrc);
    return '$payloadForCrc$crc';
  }

  static String _field(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  static String _normalize(String value, {required int maxLength}) {
    const map = {
      'Á': 'A',
      'À': 'A',
      'Ã': 'A',
      'Â': 'A',
      'Ä': 'A',
      'á': 'A',
      'à': 'A',
      'ã': 'A',
      'â': 'A',
      'ä': 'A',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'é': 'E',
      'è': 'E',
      'ê': 'E',
      'ë': 'E',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'í': 'I',
      'ì': 'I',
      'î': 'I',
      'ï': 'I',
      'Ó': 'O',
      'Ò': 'O',
      'Õ': 'O',
      'Ô': 'O',
      'Ö': 'O',
      'ó': 'O',
      'ò': 'O',
      'õ': 'O',
      'ô': 'O',
      'ö': 'O',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'ú': 'U',
      'ù': 'U',
      'û': 'U',
      'ü': 'U',
      'Ç': 'C',
      'ç': 'C',
      'Ñ': 'N',
      'ñ': 'N',
    };

    final upper = value.toUpperCase().trim();
    final normalized = StringBuffer();
    for (final char in upper.split('')) {
      final replaced = map[char] ?? char;
      if (RegExp(r'[A-Z0-9 .,\-_/]').hasMatch(replaced)) {
        normalized.write(replaced);
      }
    }
    final result = normalized.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (result.length <= maxLength) {
      return result;
    }
    return result.substring(0, maxLength);
  }

  static String _normalizeTxid(String txid) {
    final cleaned =
        txid.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').trim();
    if (cleaned.isEmpty) {
      final fallback =
          'CPX${DateTime.now().millisecondsSinceEpoch.toString()}';
      return fallback.substring(0, fallback.length > 25 ? 25 : fallback.length);
    }
    return cleaned.substring(0, cleaned.length > 25 ? 25 : cleaned.length);
  }

  static String _crc16Ccitt(String payload) {
    var crc = 0xFFFF;
    for (final codeUnit in payload.codeUnits) {
      crc ^= (codeUnit << 8);
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
