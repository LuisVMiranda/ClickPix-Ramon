import 'dart:io';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/presentation/recent_photos_page.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await _bootstrapDatabase();
  final appSettingsStore = AppSettingsStore(database);
  final locale = await appSettingsStore.loadLocale();
  final visualSettings = await appSettingsStore.loadVisualSettings();

  runApp(
    ClickPixApp(
      appSettingsStore: appSettingsStore,
      initialLocale: locale,
      initialVisualSettings: visualSettings,
    ),
  );
}

Future<AppDatabase> _bootstrapDatabase() async {
  final docsDirectory = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(docsDirectory.path, 'clickpix.sqlite'));

  final executor = LazyDatabase(() async => NativeDatabase(dbFile));
  return AppDatabase(executor);
}

class ClickPixApp extends StatefulWidget {
  const ClickPixApp({
    required this.appSettingsStore,
    this.initialLocale = AppSettingsStore.defaultLocale,
    this.initialVisualSettings =
        const AppVisualSettings(highContrastEnabled: false, solarLargeFontEnabled: false),
    super.key,
  });

  final AppSettingsStore appSettingsStore;
  final Locale initialLocale;
  final AppVisualSettings initialVisualSettings;

  @override
  State<ClickPixApp> createState() => _ClickPixAppState();
}

class _ClickPixAppState extends State<ClickPixApp> {
  late Locale _locale;
  late AppVisualSettings _visualSettings;

  @override
  void initState() {
    super.initState();
    _locale = _normalizeLocale(widget.initialLocale);
    _visualSettings = widget.initialVisualSettings;
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    return MaterialApp(
      locale: _locale,
      supportedLocales: const [Locale('pt', 'BR'), Locale('en'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: _tr('title'),
      theme: _buildTheme(baseTheme),
      home: QuickFlowPage(
        locale: _locale,
        visualSettings: _visualSettings,
        onLocaleChanged: _onLocaleChanged,
        onVisualSettingsChanged: _onVisualSettingsChanged,
        translate: _tr,
      ),
    );
  }

  ThemeData _buildTheme(ThemeData baseTheme) {
    var theme = baseTheme;

    if (_visualSettings.highContrastEnabled) {
      theme = theme.copyWith(
        colorScheme: const ColorScheme.highContrastLight(),
      );
    }

    final textScale = _visualSettings.solarLargeFontEnabled ? 1.2 : 1.0;
    final textTheme = theme.textTheme.apply(
      bodyColor: theme.colorScheme.onSurface,
      displayColor: theme.colorScheme.onSurface,
      fontSizeFactor: textScale,
    );

    return theme.copyWith(
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _onLocaleChanged(Locale locale) async {
    final normalized = _normalizeLocale(locale);
    setState(() => _locale = normalized);
    await widget.appSettingsStore.saveLocale(normalized);
  }

  Future<void> _onVisualSettingsChanged(AppVisualSettings settings) async {
    setState(() => _visualSettings = settings);
    await widget.appSettingsStore.saveVisualSettings(settings);
  }

  Locale _normalizeLocale(Locale locale) {
    if (locale.languageCode == 'pt') {
      return const Locale('pt', 'BR');
    }
    if (locale.languageCode == 'en') {
      return const Locale('en');
    }
    if (locale.languageCode == 'es') {
      return const Locale('es');
    }
    return AppSettingsStore.defaultLocale;
  }

  String _tr(String key) {
    final localeKey = _locale.languageCode == 'pt' ? 'pt-BR' : _locale.languageCode;
    final localeMap = _translations[localeKey] ?? const <String, String>{};
    return localeMap[key] ?? _translations['pt-BR']![key] ?? key;
  }
}

class QuickFlowPage extends StatelessWidget {
  const QuickFlowPage({
    required this.locale,
    required this.visualSettings,
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    required this.translate,
    super.key,
  });

  final Locale locale;
  final AppVisualSettings visualSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings) onVisualSettingsChanged;
  final String Function(String key) translate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate('quickService')),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: locale.languageCode == 'pt'
                  ? const Locale('pt', 'BR')
                  : Locale(locale.languageCode),
              onChanged: (value) {
                if (value != null) {
                  onLocaleChanged(value);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: Locale('pt', 'BR'),
                  child: Text('PT-BR'),
                ),
                DropdownMenuItem(value: Locale('en'), child: Text('EN')),
                DropdownMenuItem(value: Locale('es'), child: Text('ES')),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SettingsCard(
              title: 'Acessibilidade',
              subtitle: 'Contraste e leitura para uso em ambiente externo',
              children: [
                SwitchListTile(
                  value: visualSettings.highContrastEnabled,
                  title: const Text('Alto contraste'),
                  subtitle: const Text('Aumenta diferença entre texto e fundo.'),
                  onChanged: (value) {
                    onVisualSettingsChanged(
                      visualSettings.copyWith(highContrastEnabled: value),
                    );
                  },
                ),
                SwitchListTile(
                  value: visualSettings.solarLargeFontEnabled,
                  title: const Text('Modo Sol (fonte ampliada)'),
                  subtitle: const Text('Melhora leitura com botões e textos maiores.'),
                  onChanged: (value) {
                    onVisualSettingsChanged(
                      visualSettings.copyWith(solarLargeFontEnabled: value),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DeliveryActionsCard(translate: translate),
          ),
          const Expanded(child: RecentPhotosPage()),
        ],
      ),
    );
  }
}

class DeliveryActionsCard extends StatelessWidget {
  const DeliveryActionsCard({required this.translate, super.key});

  final String Function(String key) translate;

  static const _samplePhone = '5511999999999';
  static const _sampleEmail = 'cliente@clickpix.app';
  static const _sampleLink = 'https://clickpix.app/gallery/order-123';
  static const _sampleCode = '483920';

  @override
  Widget build(BuildContext context) {
    final message = translate('deliveryTemplate')
        .replaceAll('{link}', _sampleLink)
        .replaceAll('{code}', _sampleCode);

    return _SettingsCard(
      title: translate('deliveryActionsTitle'),
      subtitle: translate('deliveryActionsSubtitle'),
      children: [
        FilledButton.icon(
          onPressed: () => _openWhatsApp(message),
          icon: const Icon(Icons.chat),
          label: Text(translate('openWhatsApp')),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _openEmail(message),
          icon: const Icon(Icons.email),
          label: Text(translate('openEmail')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, _sampleLink, translate('copiedLink')),
          icon: const Icon(Icons.link),
          label: Text(translate('copyLink')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, _sampleCode, translate('copiedCode')),
          icon: const Icon(Icons.pin),
          label: Text(translate('copyCode')),
        ),
      ],
    );
  }

  Future<void> _openWhatsApp(String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$_samplePhone?text=$encodedMessage');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail(String message) async {
    final encodedSubject = Uri.encodeComponent('ClickPix - ${translate('delivery')}');
    final encodedBody = Uri.encodeComponent(message);
    final uri = Uri.parse('mailto:$_sampleEmail?subject=$encodedSubject&body=$encodedBody');
    await launchUrl(uri);
  }

  Future<void> _copy(BuildContext context, String value, String successText) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successText)));
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

const Map<String, Map<String, String>> _translations = {
  'pt-BR': {
    'title': 'ClickPix Ramon',
    'quickService': 'Atendimento Rápido',
    'delivery': 'Entrega',
    'deliveryActionsTitle': 'Envio para cliente',
    'deliveryActionsSubtitle': 'Compartilhe galeria por WhatsApp ou e-mail com 1 toque.',
    'deliveryTemplate': 'Olá! Sua galeria está pronta: {link} | Código: {code}',
    'openWhatsApp': 'Abrir WhatsApp',
    'openEmail': 'Abrir e-mail',
    'copyLink': 'Copiar link',
    'copyCode': 'Copiar código',
    'copiedLink': 'Link copiado com sucesso.',
    'copiedCode': 'Código copiado com sucesso.',
  },
  'en': {
    'title': 'ClickPix Ramon',
    'quickService': 'Quick Service',
    'delivery': 'Delivery',
    'deliveryActionsTitle': 'Client sharing actions',
    'deliveryActionsSubtitle': 'Share gallery via WhatsApp or e-mail in one tap.',
    'deliveryTemplate': 'Hello! Your gallery is ready: {link} | Code: {code}',
    'openWhatsApp': 'Open WhatsApp',
    'openEmail': 'Open e-mail',
    'copyLink': 'Copy link',
    'copyCode': 'Copy code',
    'copiedLink': 'Link copied.',
    'copiedCode': 'Code copied.',
  },
  'es': {
    'title': 'ClickPix Ramon',
    'quickService': 'Atención Rápida',
    'delivery': 'Entrega',
    'deliveryActionsTitle': 'Acciones para el cliente',
    'deliveryActionsSubtitle': 'Comparte la galería por WhatsApp o correo con un toque.',
    'deliveryTemplate': '¡Hola! Tu galería está lista: {link} | Código: {code}',
    'openWhatsApp': 'Abrir WhatsApp',
    'openEmail': 'Abrir correo',
    'copyLink': 'Copiar enlace',
    'copyCode': 'Copiar código',
    'copiedLink': 'Enlace copiado.',
    'copiedCode': 'Código copiado.',
  },
};
