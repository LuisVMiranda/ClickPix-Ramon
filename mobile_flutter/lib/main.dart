import 'dart:io';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/presentation/recent_photos_page.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    this.initialVisualSettings = const AppVisualSettings(),
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
    return MaterialApp(
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      themeMode: _visualSettings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: QuickFlowPage(
        locale: _locale,
        visualSettings: _visualSettings,
        onLocaleChanged: _onLocaleChanged,
        onVisualSettingsChanged: _onVisualSettingsChanged,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    );

    final scheme = _visualSettings.highContrastEnabled
        ? (brightness == Brightness.dark
              ? const ColorScheme.highContrastDark()
              : const ColorScheme.highContrastLight())
        : baseScheme;

    final isSolar = _visualSettings.solarLargeFontEnabled;
    final textScale = isSolar ? 1.15 : 1.0;

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: isSolar ? VisualDensity.comfortable : VisualDensity.standard,
    );

    final radius = isSolar ? 16.0 : 12.0;
    final outlineWidth = isSolar ? 2.2 : 1.1;
    final minHeight = isSolar ? 72.0 : 60.0;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: scheme.outline, width: outlineWidth),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: textScale),
      cardTheme: base.cardTheme.copyWith(
        shape: shape,
        elevation: isSolar ? 2 : 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          textStyle: TextStyle(fontSize: isSolar ? 20 : 18, fontWeight: FontWeight.w700),
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          textStyle: TextStyle(fontSize: isSolar ? 20 : 18, fontWeight: FontWeight.w700),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          textStyle: TextStyle(fontSize: isSolar ? 20 : 18, fontWeight: FontWeight.w700),
          side: BorderSide(color: scheme.outline, width: outlineWidth),
          shape: shape,
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
}

class QuickFlowPage extends StatelessWidget {
  const QuickFlowPage({
    required this.locale,
    required this.visualSettings,
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    super.key,
  });

  final Locale locale;
  final AppVisualSettings visualSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings) onVisualSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickService),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: locale.languageCode == 'pt' ? const Locale('pt', 'BR') : Locale(locale.languageCode),
              onChanged: (value) {
                if (value != null) {
                  onLocaleChanged(value);
                }
              },
              items: const [
                DropdownMenuItem(value: Locale('pt', 'BR'), child: Text('PT-BR')),
                DropdownMenuItem(value: Locale('en'), child: Text('EN')),
                DropdownMenuItem(value: Locale('es'), child: Text('ES')),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SettingsCard(
                title: l10n.accessibilityTitle,
                subtitle: l10n.accessibilitySubtitle,
                children: [
                  SwitchListTile(
                    value: visualSettings.highContrastEnabled,
                    title: Text(l10n.highContrast),
                    subtitle: Text(l10n.highContrastDescription),
                    onChanged: (value) {
                      onVisualSettingsChanged(visualSettings.copyWith(highContrastEnabled: value));
                    },
                  ),
                  SwitchListTile(
                    value: visualSettings.solarLargeFontEnabled,
                    title: Text(l10n.solarMode),
                    subtitle: Text(l10n.solarModeDescription),
                    onChanged: (value) {
                      onVisualSettingsChanged(visualSettings.copyWith(solarLargeFontEnabled: value));
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.themeModeLabel),
                    subtitle: Text(l10n.themeModeDescription),
                    trailing: DropdownButton<ThemeMode>(
                      value: visualSettings.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          onVisualSettingsChanged(visualSettings.copyWith(themeMode: value));
                        }
                      },
                      items: [
                        DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.themeModeSystem)),
                        DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.themeModeLight)),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.themeModeDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DeliveryActionsCard(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(child: RecentPhotosPage()),
          ),
        ],
      ),
    );
  }
}

class DeliveryActionsCard extends StatelessWidget {
  const DeliveryActionsCard({super.key});

  static const _samplePhone = '5511999999999';
  static const _sampleEmail = 'cliente@clickpix.app';
  static const _sampleLink = 'https://clickpix.app/gallery/order-123';
  static const _sampleCode = '483920';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = l10n.deliveryTemplate(_sampleLink, _sampleCode);

    return _SettingsCard(
      title: l10n.deliveryActionsTitle,
      subtitle: l10n.deliveryActionsSubtitle,
      children: [
        FilledButton.icon(
          onPressed: () => _openWhatsApp(message),
          icon: const Icon(Icons.chat),
          label: Text(l10n.openWhatsApp),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _openEmail(l10n, message),
          icon: const Icon(Icons.email),
          label: Text(l10n.openEmail),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, _sampleLink, l10n.copiedLink),
          icon: const Icon(Icons.link),
          label: Text(l10n.copyLink),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, _sampleCode, l10n.copiedCode),
          icon: const Icon(Icons.pin),
          label: Text(l10n.copyCode),
        ),
      ],
    );
  }

  Future<void> _openWhatsApp(String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$_samplePhone?text=$encodedMessage');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail(AppLocalizations l10n, String message) async {
    final encodedSubject = Uri.encodeComponent('ClickPix - ${l10n.delivery}');
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
