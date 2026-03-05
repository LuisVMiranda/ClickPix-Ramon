import 'dart:io';

import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/services/upload_worker.dart';
import 'package:clickpix_ramon/presentation/recent_photos_page.dart';
import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clickpix_ramon/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await _bootstrapDatabase();
  final appSettingsStore = AppSettingsStore(database);
  final uploadWorkerScheduler = UploadWorkerScheduler(database);
  final locale = await appSettingsStore.loadLocale();
  final visualSettings = await appSettingsStore.loadVisualSettings();
  await uploadWorkerScheduler.initialize();

  runApp(
    ClickPixApp(
      appSettingsStore: appSettingsStore,
      database: database,
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
    required this.database,
    this.initialLocale = AppSettingsStore.defaultLocale,
    this.initialVisualSettings = const AppVisualSettings(),
    super.key,
  });

  final AppSettingsStore appSettingsStore;
  final AppDatabase database;
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
        database: widget.database,
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
    required this.database,
    required this.locale,
    required this.visualSettings,
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    super.key,
  });

  final AppDatabase database;
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
            sliver: SliverToBoxAdapter(child: RecentPhotosPage(database: database)),
          ),
        ],
      ),
    );
  }
}

class DeliveryActionsCard extends StatefulWidget {
  const DeliveryActionsCard({super.key});

  @override
  State<DeliveryActionsCard> createState() => _DeliveryActionsCardState();
}

class _DeliveryActionsCardState extends State<DeliveryActionsCard> {
  final _phoneController = TextEditingController(text: '5511999999999');
  final _linkController = TextEditingController(text: 'https://clickpix.app/gallery/order-123');
  final _codeController = TextEditingController(text: '483920');

  @override
  void dispose() {
    _phoneController.dispose();
    _linkController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = l10n.deliveryTemplate(_linkController.text.trim(), _codeController.text.trim());

    return _SettingsCard(
      title: l10n.deliveryActionsTitle,
      subtitle: l10n.deliveryActionsSubtitle,
      children: [
        Text(l10n.deliveryReadyMessage),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.clientPhoneLabel,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _linkController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.deliveryLinkLabel,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: l10n.deliveryCodeLabel,
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _openWhatsApp(context, message),
          icon: const Icon(Icons.chat),
          label: Text(l10n.openWhatsAppTemplate),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, _linkController.text.trim(), l10n.copiedLink),
          icon: const Icon(Icons.link),
          label: Text(l10n.copyLink),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context, _codeController.text.trim(), l10n.copiedCode),
          icon: const Icon(Icons.pin),
          label: Text(l10n.copyCode),
        ),
      ],
    );
  }

  Future<void> _openWhatsApp(BuildContext context, String message) async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final link = _linkController.text.trim();
    final code = _codeController.text.trim();

    if (phone.isEmpty || link.isEmpty || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _showSnackBar(context, l10n.missingDeliveryData);
      return;
    }

    final encodedMessage = Uri.encodeComponent(l10n.deliveryTemplate(link, code));
    final uri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showSnackBar(context, l10n.cannotOpenWhatsApp);
    }
  }

  Future<void> _copy(BuildContext context, String value, String successText) async {
    if (value.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    _showSnackBar(context, successText);
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

