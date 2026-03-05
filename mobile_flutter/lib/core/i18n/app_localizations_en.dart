// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ClickPix Ramon';

  @override
  String get quickService => 'Quick Service';

  @override
  String get gallery => 'Gallery';

  @override
  String get order => 'Order';

  @override
  String get payment => 'Payment';

  @override
  String get delivery => 'Delivery';

  @override
  String get mockPaid => 'Payment confirmed (mock)';

  @override
  String get continueLabel => 'Continue';
}
