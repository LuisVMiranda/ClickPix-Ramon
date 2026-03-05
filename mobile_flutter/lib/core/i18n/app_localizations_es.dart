// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ClickPix Ramon';

  @override
  String get quickService => 'Atención Rápida';

  @override
  String get gallery => 'Galería';

  @override
  String get order => 'Pedido';

  @override
  String get payment => 'Pago';

  @override
  String get delivery => 'Entrega';

  @override
  String get mockPaid => 'Pago confirmado (mock)';

  @override
  String get continueLabel => 'Continuar';
}
