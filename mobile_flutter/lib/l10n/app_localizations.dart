import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'ClickPix Ramon'**
  String get appTitle;

  /// No description provided for @quickService.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento Rápido'**
  String get quickService;

  /// No description provided for @delivery.
  ///
  /// In pt, this message translates to:
  /// **'Entrega'**
  String get delivery;

  /// No description provided for @accessibilityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acessibilidade'**
  String get accessibilityTitle;

  /// No description provided for @accessibilitySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Contraste e leitura para uso em ambiente externo'**
  String get accessibilitySubtitle;

  /// No description provided for @highContrast.
  ///
  /// In pt, this message translates to:
  /// **'Alto contraste'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In pt, this message translates to:
  /// **'Aumenta diferença entre texto e fundo.'**
  String get highContrastDescription;

  /// No description provided for @solarMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Sol'**
  String get solarMode;

  /// No description provided for @solarModeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Preset visual com fonte maior, botões maiores e contraste reforçado.'**
  String get solarModeDescription;

  /// No description provided for @themeModeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get themeModeLabel;

  /// No description provided for @themeModeDescription.
  ///
  /// In pt, this message translates to:
  /// **'Escolha claro, escuro ou automático do sistema.'**
  String get themeModeDescription;

  /// No description provided for @themeModeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeModeDark;

  /// No description provided for @deliveryActionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Envio para cliente'**
  String get deliveryActionsTitle;

  /// No description provided for @deliveryActionsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe galeria por WhatsApp ou e-mail com 1 toque.'**
  String get deliveryActionsSubtitle;

  /// No description provided for @deliveryTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Sua galeria está pronta: {link} | Código: {code}'**
  String deliveryTemplate(Object link, Object code);

  /// No description provided for @openWhatsApp.
  ///
  /// In pt, this message translates to:
  /// **'Abrir WhatsApp'**
  String get openWhatsApp;

  /// No description provided for @openEmail.
  ///
  /// In pt, this message translates to:
  /// **'Abrir e-mail'**
  String get openEmail;

  /// No description provided for @copyLink.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link'**
  String get copyLink;

  /// No description provided for @copyCode.
  ///
  /// In pt, this message translates to:
  /// **'Copiar código'**
  String get copyCode;

  /// No description provided for @copiedLink.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado com sucesso.'**
  String get copiedLink;

  /// No description provided for @copiedCode.
  ///
  /// In pt, this message translates to:
  /// **'Código copiado com sucesso.'**
  String get copiedCode;

  /// No description provided for @latestPhotos.
  ///
  /// In pt, this message translates to:
  /// **'Últimas fotos'**
  String get latestPhotos;

  /// No description provided for @minutesFilter.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min'**
  String minutesFilter(int minutes);

  /// No description provided for @noPhotosInSelectedPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma foto no período selecionado.'**
  String get noPhotosInSelectedPeriod;

  /// No description provided for @quickSelection.
  ///
  /// In pt, this message translates to:
  /// **'Seleção rápida ({count})'**
  String quickSelection(int count);

  /// No description provided for @photoCapturedMinutesAgo.
  ///
  /// In pt, this message translates to:
  /// **'capturada há {minutes} min'**
  String photoCapturedMinutesAgo(int minutes);

  /// No description provided for @refreshGallery.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar galeria'**
  String get refreshGallery;

  /// No description provided for @galleryPermissionRequired.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de fotos necessária para carregar a galeria.'**
  String get galleryPermissionRequired;

  /// No description provided for @createOrderWithSelection.
  ///
  /// In pt, this message translates to:
  /// **'Criar pedido ({count})'**
  String createOrderWithSelection(int count);

  /// No description provided for @orderCreatedOffline.
  ///
  /// In pt, this message translates to:
  /// **'Pedido salvo offline com {count} fotos.'**
  String orderCreatedOffline(int count);

  /// No description provided for @selectOrCreateClient.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar ou criar cliente'**
  String get selectOrCreateClient;

  /// No description provided for @newClient.
  ///
  /// In pt, this message translates to:
  /// **'Novo cliente'**
  String get newClient;

  /// No description provided for @clientNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do cliente'**
  String get clientNameLabel;

  /// No description provided for @clientWhatsAppLabel.
  ///
  /// In pt, this message translates to:
  /// **'WhatsApp'**
  String get clientWhatsAppLabel;

  /// No description provided for @clientEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail (opcional)'**
  String get clientEmailLabel;

  /// No description provided for @createClientAndContinue.
  ///
  /// In pt, this message translates to:
  /// **'Criar cliente e continuar'**
  String get createClientAndContinue;

  /// No description provided for @deliveryLinkLabel.
  ///
  /// In pt, this message translates to:
  /// **'Link da galeria'**
  String get deliveryLinkLabel;

  /// No description provided for @deliveryCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de acesso'**
  String get deliveryCodeLabel;

  /// No description provided for @clientPhoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Telefone WhatsApp'**
  String get clientPhoneLabel;

  /// No description provided for @deliveryReadyMessage.
  ///
  /// In pt, this message translates to:
  /// **'Entrega pronta para envio ao cliente.'**
  String get deliveryReadyMessage;

  /// No description provided for @openWhatsAppTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Abrir WhatsApp com mensagem'**
  String get openWhatsAppTemplate;

  /// No description provided for @missingDeliveryData.
  ///
  /// In pt, this message translates to:
  /// **'Preencha link, código e telefone para compartilhar no WhatsApp.'**
  String get missingDeliveryData;

  /// No description provided for @cannotOpenWhatsApp.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o WhatsApp no dispositivo.'**
  String get cannotOpenWhatsApp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
