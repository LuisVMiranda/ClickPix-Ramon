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
  String get delivery => 'Delivery';

  @override
  String get accessibilityTitle => 'Accessibility';

  @override
  String get accessibilitySubtitle =>
      'Contrast and readability for outdoor usage';

  @override
  String get highContrast => 'High contrast';

  @override
  String get highContrastDescription =>
      'Increases difference between text and background.';

  @override
  String get solarMode => 'Sun Mode';

  @override
  String get solarModeDescription =>
      'Visual preset with larger fonts, larger buttons, and stronger contrast.';

  @override
  String get themeModeLabel => 'Theme';

  @override
  String get themeModeDescription =>
      'Choose light, dark, or system automatic mode.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get deliveryActionsTitle => 'Client sharing actions';

  @override
  String get deliveryActionsSubtitle =>
      'Share gallery via WhatsApp or e-mail in one tap.';

  @override
  String deliveryTemplate(Object link, Object code) {
    return 'Hello! Your gallery is ready: $link | Code: $code';
  }

  @override
  String get openWhatsApp => 'Open WhatsApp';

  @override
  String get openEmail => 'Open e-mail';

  @override
  String get copyLink => 'Copy link';

  @override
  String get copyCode => 'Copy code';

  @override
  String get copiedLink => 'Link copied.';

  @override
  String get copiedCode => 'Code copied.';

  @override
  String get latestPhotos => 'Latest photos';

  @override
  String minutesFilter(int minutes) {
    return '$minutes min';
  }

  @override
  String get noPhotosInSelectedPeriod => 'No photos in selected period.';

  @override
  String quickSelection(int count) {
    return 'Quick selection ($count)';
  }

  @override
  String photoCapturedMinutesAgo(int minutes) {
    return 'captured $minutes min ago';
  }

  @override
  String get refreshGallery => 'Refresh gallery';

  @override
  String get galleryPermissionRequired =>
      'Photo permission is required to load the gallery.';

  @override
  String createOrderWithSelection(int count) {
    return 'Create order ($count)';
  }

  @override
  String orderCreatedOffline(int count) {
    return 'Offline order saved with $count photos.';
  }

  @override
  String get selectOrCreateClient => 'Select or create client';

  @override
  String get newClient => 'New client';

  @override
  String get clientNameLabel => 'Client name';

  @override
  String get clientWhatsAppLabel => 'WhatsApp';

  @override
  String get clientEmailLabel => 'Email (optional)';

  @override
  String get createClientAndContinue => 'Create client and continue';

  @override
  String get deliveryLinkLabel => 'Gallery link';

  @override
  String get deliveryCodeLabel => 'Access code';

  @override
  String get clientPhoneLabel => 'WhatsApp phone';

  @override
  String get deliveryReadyMessage =>
      'Delivery package ready to share with the client.';

  @override
  String get openWhatsAppTemplate => 'Open WhatsApp with template';

  @override
  String get missingDeliveryData =>
      'Fill link, code and phone to share on WhatsApp.';

  @override
  String get cannotOpenWhatsApp => 'Could not open WhatsApp on this device.';
}
