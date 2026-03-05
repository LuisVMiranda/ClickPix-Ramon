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
  String get delivery => 'Entrega';

  @override
  String get accessibilityTitle => 'Accesibilidad';

  @override
  String get accessibilitySubtitle =>
      'Contraste y lectura para uso en exteriores';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get highContrastDescription =>
      'Aumenta la diferencia entre texto y fondo.';

  @override
  String get solarMode => 'Modo Sol';

  @override
  String get solarModeDescription =>
      'Preset visual con tipografía mayor, botones más grandes y contraste reforzado.';

  @override
  String get themeModeLabel => 'Tema';

  @override
  String get themeModeDescription =>
      'Elige modo claro, oscuro o automático del sistema.';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get deliveryActionsTitle => 'Acciones para el cliente';

  @override
  String get deliveryActionsSubtitle =>
      'Comparte la galería por WhatsApp o correo con un toque.';

  @override
  String deliveryTemplate(Object link, Object code) {
    return '¡Hola! Tu galería está lista: $link | Código: $code';
  }

  @override
  String get openWhatsApp => 'Abrir WhatsApp';

  @override
  String get openEmail => 'Abrir correo';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get copiedLink => 'Enlace copiado.';

  @override
  String get copiedCode => 'Código copiado.';

  @override
  String get latestPhotos => 'Últimas fotos';

  @override
  String minutesFilter(int minutes) {
    return '$minutes min';
  }

  @override
  String get noPhotosInSelectedPeriod =>
      'No hay fotos en el período seleccionado.';

  @override
  String quickSelection(int count) {
    return 'Selección rápida ($count)';
  }

  @override
  String photoCapturedMinutesAgo(int minutes) {
    return 'capturada hace $minutes min';
  }

  @override
  String get refreshGallery => 'Actualizar galería';

  @override
  String get galleryPermissionRequired =>
      'Se requiere permiso de fotos para cargar la galería.';

  @override
  String createOrderWithSelection(int count) {
    return 'Crear pedido ($count)';
  }

  @override
  String orderCreatedOffline(int count) {
    return 'Pedido guardado sin conexión con $count fotos.';
  }

  @override
  String get selectOrCreateClient => 'Seleccionar o crear cliente';

  @override
  String get newClient => 'Nuevo cliente';

  @override
  String get clientNameLabel => 'Nombre del cliente';

  @override
  String get clientWhatsAppLabel => 'WhatsApp';

  @override
  String get clientEmailLabel => 'Correo (opcional)';

  @override
  String get createClientAndContinue => 'Crear cliente y continuar';

  @override
  String get deliveryLinkLabel => 'Enlace de galería';

  @override
  String get deliveryCodeLabel => 'Código de acceso';

  @override
  String get clientPhoneLabel => 'Teléfono de WhatsApp';

  @override
  String get deliveryReadyMessage =>
      'Entrega lista para compartir con el cliente.';

  @override
  String get openWhatsAppTemplate => 'Abrir WhatsApp con plantilla';

  @override
  String get missingDeliveryData =>
      'Completa enlace, código y teléfono para compartir por WhatsApp.';

  @override
  String get cannotOpenWhatsApp =>
      'No se pudo abrir WhatsApp en este dispositivo.';
}
