import 'dart:io';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await _bootstrapDatabase();
  final appSettingsStore = AppSettingsStore(database);
  final locale = await appSettingsStore.loadLocale();

  runApp(
    ClickPixApp(
      appSettingsStore: appSettingsStore,
      initialLocale: locale,
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
    super.key,
  });

  final AppSettingsStore appSettingsStore;
  final Locale initialLocale;

  @override
  State<ClickPixApp> createState() => _ClickPixAppState();
}

class _ClickPixAppState extends State<ClickPixApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = _normalizeLocale(widget.initialLocale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      supportedLocales: const [Locale('pt', 'BR'), Locale('en'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: _tr('title'),
      home: QuickFlowPage(
        locale: _locale,
        onLocaleChanged: _onLocaleChanged,
        translate: _tr,
      ),
    );
  }

  Future<void> _onLocaleChanged(Locale locale) async {
    final normalized = _normalizeLocale(locale);
    setState(() => _locale = normalized);
    await widget.appSettingsStore.saveLocale(normalized);
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

class QuickFlowPage extends StatefulWidget {
  const QuickFlowPage({
    required this.locale,
    required this.onLocaleChanged,
    required this.translate,
    super.key,
  });

  final Locale locale;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final String Function(String key) translate;

  @override
  State<QuickFlowPage> createState() => _QuickFlowPageState();
}

class _QuickFlowPageState extends State<QuickFlowPage> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final labels = [
      widget.translate('stepGallery'),
      widget.translate('stepOrder'),
      widget.translate('stepPayment'),
      widget.translate('stepDelivery'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.translate('quickService')),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: widget.locale.languageCode == 'pt'
                  ? const Locale('pt', 'BR')
                  : Locale(widget.locale.languageCode),
              onChanged: (value) {
                if (value != null) {
                  widget.onLocaleChanged(value);
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
      body: Center(child: Text('${widget.translate('currentStep')}: ${labels[step]}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => step = (step + 1) % labels.length),
        label: Text(widget.translate('continue')),
      ),
    );
  }
}

const Map<String, Map<String, String>> _translations = {
  'pt-BR': {
    'title': 'ClickPix Ramon',
    'quickService': 'Atendimento Rápido',
    'currentStep': 'Etapa atual',
    'continue': 'Continuar',
    'stepGallery': 'Galeria',
    'stepOrder': 'Pedido',
    'stepPayment': 'Pagamento',
    'stepDelivery': 'Entrega',
  },
  'en': {
    'title': 'ClickPix Ramon',
    'quickService': 'Quick Service',
    'currentStep': 'Current step',
    'continue': 'Continue',
    'stepGallery': 'Gallery',
    'stepOrder': 'Order',
    'stepPayment': 'Payment',
  },
  'es': {
    'title': 'ClickPix Ramon',
    'quickService': 'Atención Rápida',
    'currentStep': 'Paso actual',
    'continue': 'Continuar',
    'stepGallery': 'Galería',
    'stepOrder': 'Pedido',
    'stepPayment': 'Pago',
  },
};
