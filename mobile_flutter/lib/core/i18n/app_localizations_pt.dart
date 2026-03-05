// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ClickPix Ramon';

  @override
  String get quickService => 'Atendimento Rápido';

  @override
  String get gallery => 'Galeria';

  @override
  String get order => 'Pedido';

  @override
  String get payment => 'Pagamento';

  @override
  String get delivery => 'Entrega';

  @override
  String get mockPaid => 'Pagamento confirmado (mock)';

  @override
  String get continueLabel => 'Continuar';
}
