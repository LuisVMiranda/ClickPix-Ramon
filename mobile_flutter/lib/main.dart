import 'dart:io';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/presentation/recent_photos_page.dart';
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
          const Expanded(child: RecentPhotosPage()),
        ],
      ),
    );
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
  },
  'en': {
    'title': 'ClickPix Ramon',
    'quickService': 'Quick Service',
  },
  'es': {
    'title': 'ClickPix Ramon',
    'quickService': 'Atención Rápida',
  },
};
