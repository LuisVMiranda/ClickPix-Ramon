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
  String get delivery => 'Entrega';

  @override
  String get accessibilityTitle => 'Acessibilidade';

  @override
  String get accessibilitySubtitle =>
      'Contraste e leitura para uso em ambiente externo';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get highContrastDescription =>
      'Aumenta diferença entre texto e fundo.';

  @override
  String get solarMode => 'Modo Sol';

  @override
  String get solarModeDescription =>
      'Preset visual com fonte maior, botões maiores e contraste reforçado.';

  @override
  String get themeModeLabel => 'Tema';

  @override
  String get themeModeDescription =>
      'Escolha claro, escuro ou automático do sistema.';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Escuro';

  @override
  String get deliveryActionsTitle => 'Envio para cliente';

  @override
  String get deliveryActionsSubtitle =>
      'Compartilhe galeria por WhatsApp ou e-mail com 1 toque.';

  @override
  String deliveryTemplate(Object link, Object code) {
    return 'Olá! Sua galeria está pronta: $link | Código: $code';
  }

  @override
  String get openWhatsApp => 'Abrir WhatsApp';

  @override
  String get openEmail => 'Abrir e-mail';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get copiedLink => 'Link copiado com sucesso.';

  @override
  String get copiedCode => 'Código copiado com sucesso.';

  @override
  String get latestPhotos => 'Últimas fotos';

  @override
  String minutesFilter(int minutes) {
    return '$minutes min';
  }

  @override
  String get noPhotosInSelectedPeriod => 'Nenhuma foto no período selecionado.';

  @override
  String quickSelection(int count) {
    return 'Seleção rápida ($count)';
  }

  @override
  String photoCapturedMinutesAgo(int minutes) {
    return 'capturada há $minutes min';
  }

  @override
  String get refreshGallery => 'Atualizar galeria';

  @override
  String get galleryPermissionRequired =>
      'Permissão de fotos necessária para carregar a galeria.';

  @override
  String createOrderWithSelection(int count) {
    return 'Criar pedido ($count)';
  }

  @override
  String orderCreatedOffline(int count) {
    return 'Pedido salvo offline com $count fotos.';
  }

  @override
  String get selectOrCreateClient => 'Selecionar ou criar cliente';

  @override
  String get newClient => 'Novo cliente';

  @override
  String get clientNameLabel => 'Nome do cliente';

  @override
  String get clientWhatsAppLabel => 'WhatsApp';

  @override
  String get clientEmailLabel => 'E-mail (opcional)';

  @override
  String get createClientAndContinue => 'Criar cliente e continuar';

  @override
  String get deliveryLinkLabel => 'Link da galeria';

  @override
  String get deliveryCodeLabel => 'Código de acesso';

  @override
  String get clientPhoneLabel => 'Telefone WhatsApp';

  @override
  String get deliveryReadyMessage => 'Entrega pronta para envio ao cliente.';

  @override
  String get openWhatsAppTemplate => 'Abrir WhatsApp com mensagem';

  @override
  String get missingDeliveryData =>
      'Preencha link, código e telefone para compartilhar no WhatsApp.';

  @override
  String get cannotOpenWhatsApp =>
      'Não foi possível abrir o WhatsApp no dispositivo.';
}
