import 'dart:io';

import 'package:clickpix_ramon/core/i18n/app_localizations.dart';
import 'package:clickpix_ramon/core/i18n/ui_text.dart';
import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/services/photo_ingestion_service.dart';
import 'package:clickpix_ramon/data/services/upload_worker.dart';
import 'package:clickpix_ramon/presentation/manage_contacts_page.dart';
import 'package:clickpix_ramon/presentation/recent_photos_page.dart';
import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const List<String> _accentFamilies = [
  'blue',
  'green',
  'orange',
  'gray',
  'red',
  'brown',
];

const Map<String, Color> _accentTokenToColor = {
  'blue_light': Color(0xFF93C5FD),
  'blue_mid': Color(0xFF1D4ED8),
  'blue_dark': Color(0xFF1E3A8A),
  'green_light': Color(0xFF86EFAC),
  'green_mid': Color(0xFF15803D),
  'green_dark': Color(0xFF14532D),
  'orange_light': Color(0xFFFDBA74),
  'orange_mid': Color(0xFFEA580C),
  'orange_dark': Color(0xFF9A3412),
  'gray_light': Color(0xFFE5E7EB),
  'gray_mid': Color(0xFF4B5563),
  'gray_dark': Color(0xFF1F2937),
  'red_light': Color(0xFFFCA5A5),
  'red_mid': Color(0xFFDC2626),
  'red_dark': Color(0xFF7F1D1D),
  'brown_light': Color(0xFFD2B48C),
  'brown_mid': Color(0xFF8B5E3C),
  'brown_dark': Color(0xFF4E342E),
};

const double _paypalBusinessFeeRate = 0.0479;
const double _paypalCurrencyConversionRate = 0.035;
const int _paypalFixedFeeCents = 60;

String _accentFamilyFromKey(String key) {
  final parts = key.split('_');
  final family = parts.isNotEmpty ? parts.first : '';
  return _accentFamilies.contains(family) ? family : 'blue';
}

String _accentToken(String family) {
  final normalizedFamily = _accentFamilies.contains(family) ? family : 'blue';
  return '${normalizedFamily}_mid';
}

Color _accentColorFromKey(String key) {
  return _accentTokenToColor[key] ??
      _accentTokenToColor[AppSettingsStore.defaultAccentColorKey]!;
}

String _accentFamilyLabel(
  BuildContext context,
  String family,
) {
  switch (family) {
    case 'gray':
      return tr(context, pt: 'Cinza', es: 'Gris', en: 'Gray');
    case 'red':
      return tr(context, pt: 'Vermelho', es: 'Rojo', en: 'Red');
    case 'brown':
      return tr(context, pt: 'Marrom', es: 'Marron', en: 'Brown');
    case 'blue':
      return tr(context, pt: 'Azul', es: 'Azul', en: 'Blue');
    case 'green':
      return tr(context, pt: 'Verde', es: 'Verde', en: 'Green');
    case 'orange':
      return tr(context, pt: 'Laranja', es: 'Naranja', en: 'Orange');
    default:
      return tr(context, pt: 'Azul', es: 'Azul', en: 'Blue');
  }
}

const Map<PaymentProvider, String> _paymentProviderDefaultApiBaseUrls = {
  PaymentProvider.bancoDoBrasil: 'https://seu-backend-pix.example.com/bb',
  PaymentProvider.itau: 'https://seu-backend-pix.example.com/itau',
  PaymentProvider.bradesco: 'https://seu-backend-pix.example.com/bradesco',
  PaymentProvider.santander: 'https://seu-backend-pix.example.com/santander',
  PaymentProvider.caixa: 'https://seu-backend-pix.example.com/caixa',
  PaymentProvider.inter: 'https://seu-backend-pix.example.com/inter',
  PaymentProvider.nubank: 'https://seu-backend-pix.example.com/nubank',
  PaymentProvider.sicredi: 'https://seu-backend-pix.example.com/sicredi',
  PaymentProvider.sicoob: 'https://seu-backend-pix.example.com/sicoob',
  PaymentProvider.c6Bank: 'https://seu-backend-pix.example.com/c6',
  PaymentProvider.mercadoPago:
      'https://seu-backend-pix.example.com/mercado-pago',
  PaymentProvider.outro: 'https://seu-backend-pix.example.com/outro',
};

String _paymentProviderLabel(BuildContext context, PaymentProvider provider) {
  switch (provider) {
    case PaymentProvider.manual:
      return tr(
        context,
        pt: 'Manual (QR local)',
        es: 'Manual (QR local)',
        en: 'Manual (local QR)',
      );
    case PaymentProvider.bancoDoBrasil:
      return 'Banco do Brasil';
    case PaymentProvider.itau:
      return 'Itaú';
    case PaymentProvider.bradesco:
      return 'Bradesco';
    case PaymentProvider.santander:
      return 'Santander';
    case PaymentProvider.caixa:
      return 'Caixa';
    case PaymentProvider.inter:
      return 'Inter';
    case PaymentProvider.nubank:
      return 'Nubank';
    case PaymentProvider.sicredi:
      return 'Sicredi';
    case PaymentProvider.sicoob:
      return 'Sicoob';
    case PaymentProvider.c6Bank:
      return 'C6 Bank';
    case PaymentProvider.mercadoPago:
      return 'Mercado Pago';
    case PaymentProvider.outro:
      return tr(
        context,
        pt: 'Outro',
        es: 'Otro',
        en: 'Other',
      );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await _bootstrapDatabase();
  final appSettingsStore = AppSettingsStore(database);
  final uploadWorkerScheduler = UploadWorkerScheduler(database);
  final locale = await appSettingsStore.loadLocale();
  final visualSettings = await appSettingsStore.loadVisualSettings();
  final backgroundSettings = await appSettingsStore.loadBackgroundSettings();
  await uploadWorkerScheduler.initialize();

  runApp(
    ClickPixApp(
      appSettingsStore: appSettingsStore,
      database: database,
      initialLocale: locale,
      initialVisualSettings: visualSettings,
      initialBackgroundSettings: backgroundSettings,
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
    this.initialBackgroundSettings = const AppBackgroundSettings(),
    super.key,
  });

  final AppSettingsStore appSettingsStore;
  final AppDatabase database;
  final Locale initialLocale;
  final AppVisualSettings initialVisualSettings;
  final AppBackgroundSettings initialBackgroundSettings;

  @override
  State<ClickPixApp> createState() => _ClickPixAppState();
}

class _ClickPixAppState extends State<ClickPixApp> {
  late Locale _locale;
  late AppVisualSettings _visualSettings;
  late AppBackgroundSettings _backgroundSettings;

  @override
  void initState() {
    super.initState();
    _locale = _normalizeLocale(widget.initialLocale);
    _visualSettings = widget.initialVisualSettings;
    _backgroundSettings = widget.initialBackgroundSettings;
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
      themeMode: _visualSettings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      builder: (context, child) {
        var content = child ?? const SizedBox.shrink();
        if (_visualSettings.solarLargeFontEnabled) {
          final mediaQuery = MediaQuery.of(context);
          content = MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: const TextScaler.linear(1.15),
            ),
            child: content,
          );
        }
        if (_backgroundSettings.hasImage) {
          final backgroundFile = File(_backgroundSettings.imagePath);
          content = Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: _backgroundSettings.opacity,
                  child: Image.file(
                    backgroundFile,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
              content,
            ],
          );
        }
        return content;
      },
      home: AdminGatePage(
        settingsStore: widget.appSettingsStore,
        database: widget.database,
        locale: _locale,
        visualSettings: _visualSettings,
        backgroundSettings: _backgroundSettings,
        onLocaleChanged: _onLocaleChanged,
        onVisualSettingsChanged: _onVisualSettingsChanged,
        onBackgroundSettingsChanged: _onBackgroundSettingsChanged,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final accentFamily = _accentFamilyFromKey(_visualSettings.accentColorKey);
    final scheme = ColorScheme.fromSeed(
      seedColor: _accentColorFromKey(_visualSettings.accentColorKey),
      brightness: brightness,
      dynamicSchemeVariant: accentFamily == 'gray'
          ? DynamicSchemeVariant.neutral
          : DynamicSchemeVariant.tonalSpot,
      // Keep the selected accent family/shade even in high-contrast mode.
      contrastLevel: _visualSettings.highContrastEnabled ? 1.0 : 0.0,
    );

    final isSolar = _visualSettings.solarLargeFontEnabled;

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity:
          isSolar ? VisualDensity.comfortable : VisualDensity.standard,
    );

    final radius = isSolar ? 16.0 : 12.0;
    final outlineWidth = isSolar ? 2.2 : 1.1;
    final minHeight = isSolar ? 72.0 : 60.0;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: scheme.outline, width: outlineWidth),
    );

    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(
        shape: shape,
        elevation: isSolar ? 2 : 1,
        color: _backgroundSettings.hasImage
            ? scheme.surface.withOpacity(
                brightness == Brightness.light ? 0.88 : 0.82,
              )
            : null,
      ),
      scaffoldBackgroundColor: _backgroundSettings.hasImage
          ? scheme.surface.withOpacity(
              brightness == Brightness.light ? 0.82 : 0.74,
            )
          : null,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          textStyle: TextStyle(
              fontSize: isSolar ? 20 : 18, fontWeight: FontWeight.w700),
          shape: shape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          textStyle: TextStyle(
              fontSize: isSolar ? 20 : 18, fontWeight: FontWeight.w700),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(minHeight),
          textStyle: TextStyle(
              fontSize: isSolar ? 20 : 18, fontWeight: FontWeight.w700),
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

  Future<void> _onBackgroundSettingsChanged(
    AppBackgroundSettings settings,
  ) async {
    setState(() => _backgroundSettings = settings);
    await widget.appSettingsStore.saveBackgroundSettings(settings);
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

class AdminGatePage extends StatefulWidget {
  const AdminGatePage({
    required this.settingsStore,
    required this.database,
    required this.locale,
    required this.visualSettings,
    required this.backgroundSettings,
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    required this.onBackgroundSettingsChanged,
    super.key,
  });

  final AppSettingsStore settingsStore;
  final AppDatabase database;
  final Locale locale;
  final AppVisualSettings visualSettings;
  final AppBackgroundSettings backgroundSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings)
      onVisualSettingsChanged;
  final Future<void> Function(AppBackgroundSettings settings)
      onBackgroundSettingsChanged;

  @override
  State<AdminGatePage> createState() => _AdminGatePageState();
}

class _AdminGatePageState extends State<AdminGatePage> {
  String _adminUser = AppSettingsStore.defaultAdminUsername;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadAdminUser();
  }

  Future<void> _loadAdminUser() async {
    final credentials = await widget.settingsStore.loadAdminCredentials();
    if (!mounted) {
      return;
    }
    setState(() => _adminUser = credentials.username);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return AdminLoginPage(
        initialUsername: _adminUser,
        onLogin: (username, password) async {
          final allowed = await widget.settingsStore.verifyAdminLogin(
            username: username,
            password: password,
          );
          if (allowed && mounted) {
            setState(() => _isAuthenticated = true);
          }
          return allowed;
        },
        onForgotPassword: (username, recoveryEmail, newPassword) {
          return widget.settingsStore.resetAdminPasswordWithEmail(
            username: username,
            recoveryEmail: recoveryEmail,
            newPassword: newPassword,
          );
        },
      );
    }

    return DashboardPage(
      settingsStore: widget.settingsStore,
      database: widget.database,
      locale: widget.locale,
      visualSettings: widget.visualSettings,
      backgroundSettings: widget.backgroundSettings,
      onLocaleChanged: widget.onLocaleChanged,
      onVisualSettingsChanged: widget.onVisualSettingsChanged,
      onBackgroundSettingsChanged: widget.onBackgroundSettingsChanged,
      onLogout: () => setState(() => _isAuthenticated = false),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({
    required this.initialUsername,
    required this.onLogin,
    required this.onForgotPassword,
    super.key,
  });

  final String initialUsername;
  final Future<bool> Function(String username, String password) onLogin;
  final Future<bool> Function(
    String username,
    String recoveryEmail,
    String newPassword,
  ) onForgotPassword;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  late final TextEditingController _userController;
  final TextEditingController _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const ClickPixBrand(),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(
                              context,
                              pt: 'Login de administrador',
                              es: 'Inicio de sesión de administrador',
                              en: 'Administrator login',
                            ),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(
                              context,
                              pt: 'Somente o dono do aplicativo pode acessar dados sensíveis.',
                              es: 'Solo el dueño de la aplicación puede acceder a datos sensibles.',
                              en: 'Only the app owner can access sensitive data.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _userController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: tr(
                                context,
                                pt: 'Usuário',
                                es: 'Usuario',
                                en: 'Username',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: tr(
                                context,
                                pt: 'Senha',
                                es: 'Contraseña',
                                en: 'Password',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: const Icon(Icons.lock_open),
                              label: Text(
                                _submitting
                                    ? tr(
                                        context,
                                        pt: 'Validando...',
                                        es: 'Validando...',
                                        en: 'Validating...',
                                      )
                                    : tr(
                                        context,
                                        pt: 'Entrar',
                                        es: 'Entrar',
                                        en: 'Sign in',
                                      ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _showForgotPasswordDialog,
                              icon: const Icon(Icons.mark_email_read_outlined),
                              label: Text(
                                tr(
                                  context,
                                  pt: 'Esqueceu a senha?',
                                  es: '¿Olvidaste la contraseña?',
                                  en: 'Forgot password?',
                                ),
                              ),
                            ),
                          ),
                          Text(
                            tr(
                              context,
                              pt: 'Primeiro acesso padrão: usuário admin e senha admin123. Altere em Configurações.',
                              es: 'Primer acceso predeterminado: usuario admin y contraseña admin123. Cámbialo en Configuración.',
                              en: 'Default first access: username admin and password admin123. Change it in Settings.',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final allowed = await widget.onLogin(
      _userController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Credenciais inválidas. Tente novamente.',
              es: 'Credenciales inválidas. Inténtalo de nuevo.',
              en: 'Invalid credentials. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final didSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            tr(
              context,
              pt: 'Recuperar senha',
              es: 'Recuperar contraseña',
              en: 'Recover password',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(
                  context,
                  pt: 'Informe o e-mail cadastrado e defina uma nova senha do administrador.',
                  es: 'Ingresa el correo registrado y define una nueva contraseña de administrador.',
                  en: 'Enter the registered email and define a new administrator password.',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'E-mail cadastrado',
                    es: 'Correo registrado',
                    en: 'Registered email',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'Nova senha',
                    es: 'Nueva contraseña',
                    en: 'New password',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'Confirmar nova senha',
                    es: 'Confirmar nueva contraseña',
                    en: 'Confirm new password',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                tr(
                  context,
                  pt: 'Cancelar',
                  es: 'Cancelar',
                  en: 'Cancel',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                tr(
                  context,
                  pt: 'Redefinir',
                  es: 'Restablecer',
                  en: 'Reset',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || didSubmit != true) {
      return;
    }

    final newPassword = newPasswordController.text;
    final confirmedPassword = confirmPasswordController.text;
    if (newPassword.trim().isEmpty || newPassword != confirmedPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'As senhas não coincidem.',
              es: 'Las contraseñas no coinciden.',
              en: 'Passwords do not match.',
            ),
          ),
        ),
      );
      return;
    }

    final success = await widget.onForgotPassword(
      _userController.text.trim(),
      emailController.text.trim(),
      newPassword,
    );
    if (!mounted) {
      return;
    }

    if (success) {
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Senha redefinida com sucesso. Faça login com a nova senha.',
              es: 'Contraseña restablecida correctamente. Inicia sesión con la nueva contraseña.',
              en: 'Password reset successfully. Sign in with the new password.',
            ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Não foi possível redefinir. Verifique o usuário e o e-mail cadastrado em Configurações.',
            es: 'No se pudo restablecer. Verifica el usuario y el correo registrado en Configuración.',
            en: 'Could not reset. Verify username and registered email in Settings.',
          ),
        ),
      ),
    );
  }
}

class ClickPixBrand extends StatelessWidget {
  const ClickPixBrand({
    this.compact = false,
    super.key,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = compact ? 20.0 : 32.0;
    final fontSize = compact ? 20.0 : 34.0;

    return Hero(
      tag: 'clickpix-brand',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
            ),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded, size: iconSize),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Click',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' Pix',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClickPixPageTitle extends StatelessWidget {
  const ClickPixPageTitle({
    required this.title,
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ClickPixBrand(compact: true),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.settingsStore,
    required this.database,
    required this.locale,
    required this.visualSettings,
    required this.backgroundSettings,
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    required this.onBackgroundSettingsChanged,
    required this.onLogout,
    super.key,
  });

  final AppSettingsStore settingsStore;
  final AppDatabase database;
  final Locale locale;
  final AppVisualSettings visualSettings;
  final AppBackgroundSettings backgroundSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings)
      onVisualSettingsChanged;
  final Future<void> Function(AppBackgroundSettings settings)
      onBackgroundSettingsChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClickPixPageTitle(
          title: tr(
            context,
            pt: 'Painel principal',
            es: 'Panel principal',
            en: 'Main dashboard',
          ),
        ),
        actions: [
          IconButton(
            onPressed: onLogout,
            tooltip: tr(
              context,
              pt: 'Sair',
              es: 'Salir',
              en: 'Sign out',
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1200
              ? 4
              : width >= 720
                  ? 2
                  : 1;
          const baseTileHeight = 210.0;
          const minTileHeight = baseTileHeight * 0.9;
          const maxTileHeight = 280.0 * 0.9;
          final scaledHeight =
              MediaQuery.textScalerOf(context).scale(baseTileHeight) * 0.9;
          final tileHeight = scaledHeight
              .clamp(
                minTileHeight,
                maxTileHeight,
              )
              .toDouble();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: tileHeight,
              ),
              children: [
                _DashboardCardButton(
                  icon: Icons.flash_on,
                  title: tr(
                    context,
                    pt: 'Atendimento rápido',
                    es: 'Atención rápida',
                    en: 'Quick service',
                  ),
                  subtitle: tr(
                    context,
                    pt: 'Entrada de fotos + pedido com pagamento + envio.',
                    es: 'Entrada de fotos + pedido con pago + envío.',
                    en: 'Photo intake + paid order + delivery.',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuickServiceModulePage(
                          database: database,
                          settingsStore: settingsStore,
                        ),
                      ),
                    );
                  },
                ),
                _DashboardCardButton(
                  icon: Icons.send,
                  title: tr(
                    context,
                    pt: 'Envio de fotos',
                    es: 'Envío de fotos',
                    en: 'Photo dispatch',
                  ),
                  subtitle: tr(
                    context,
                    pt: 'Fluxo de envio sem etapa de pagamento.',
                    es: 'Flujo de envío sin etapa de pago.',
                    en: 'Delivery flow without payment step.',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PhotoDispatchModulePage(
                          database: database,
                          settingsStore: settingsStore,
                        ),
                      ),
                    );
                  },
                ),
                _DashboardCardButton(
                  icon: Icons.settings,
                  title: tr(
                    context,
                    pt: 'Configurações',
                    es: 'Configuración',
                    en: 'Settings',
                  ),
                  subtitle: tr(
                    context,
                    pt: 'Perfil, Pix, tema, contraste e preferências.',
                    es: 'Perfil, Pix, tema, contraste y preferencias.',
                    en: 'Profile, Pix, theme, contrast and preferences.',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppConfigurationPage(
                          settingsStore: settingsStore,
                          locale: locale,
                          visualSettings: visualSettings,
                          backgroundSettings: backgroundSettings,
                          onLocaleChanged: onLocaleChanged,
                          onVisualSettingsChanged: onVisualSettingsChanged,
                          onBackgroundSettingsChanged:
                              onBackgroundSettingsChanged,
                        ),
                      ),
                    );
                  },
                ),
                _DashboardCardButton(
                  icon: Icons.contacts,
                  title: tr(
                    context,
                    pt: 'Gerir contatos',
                    es: 'Gestionar contactos',
                    en: 'Manage contacts',
                  ),
                  subtitle: tr(
                    context,
                    pt: 'Ver, editar, adicionar, remover e exportar contatos.',
                    es: 'Ver, editar, agregar, eliminar y exportar contactos.',
                    en: 'View, edit, add, delete and export contacts.',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ManageContactsPage(
                          database: database,
                        ),
                      ),
                    );
                  },
                ),
                _DashboardCardButton(
                  icon: Icons.receipt_long,
                  title: tr(
                    context,
                    pt: 'Ver vendas e envios',
                    es: 'Ver ventas y env\u00edos',
                    en: 'View sales and dispatches',
                  ),
                  subtitle: tr(
                    context,
                    pt: 'Detalhes por venda, cliente, c\u00f3digo e arquivos enviados.',
                    es: 'Detalles por venta, cliente, c\u00f3digo y archivos enviados.',
                    en: 'Sale details by client, code and delivered files.',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SalesAndDispatchesPage(
                          database: database,
                          settingsStore: settingsStore,
                        ),
                      ),
                    );
                  },
                ),
                _DashboardCardButton(
                  icon: Icons.query_stats,
                  title: tr(
                    context,
                    pt: 'Estatísticas',
                    es: 'Estadísticas',
                    en: 'Statistics',
                  ),
                  subtitle: tr(
                    context,
                    pt: 'Vendas, envios, gastos e lucros por período.',
                    es: 'Ventas, envíos, gastos y ganancias por período.',
                    en: 'Sales, deliveries, expenses and profit by period.',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatisticsPage(
                          database: database,
                          settingsStore: settingsStore,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCardButton extends StatelessWidget {
  const _DashboardCardButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickServiceModulePage extends StatefulWidget {
  const QuickServiceModulePage({
    required this.database,
    required this.settingsStore,
    super.key,
  });

  final AppDatabase database;
  final AppSettingsStore settingsStore;

  @override
  State<QuickServiceModulePage> createState() => _QuickServiceModulePageState();
}

class _QuickServiceModulePageState extends State<QuickServiceModulePage> {
  late final PhotoIngestionService _ingestionService;
  final TextEditingController _folderController = TextEditingController();
  bool _ingesting = false;
  int _recentPhotosRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _ingestionService = PhotoIngestionService(database: widget.database);
    _loadFolder();
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _loadFolder() async {
    final preferred = await widget.settingsStore.loadPreferredInputFolder();
    if (!mounted) {
      return;
    }
    _folderController.text = preferred;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClickPixPageTitle(
          title: tr(
            context,
            pt: 'Atendimento rápido',
            es: 'Atención rápida',
            en: 'Quick service',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(
                          context,
                          pt: 'Entrada de fotos',
                          es: 'Entrada de fotos',
                          en: 'Photo intake',
                        ),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        context,
                        pt: 'Leia uma pasta local para ingestão em lote e combine com envio via WhatsApp ou e-mail.',
                        es: 'Lee una carpeta local para ingesta por lote y combina con envío por WhatsApp o correo.',
                        en: 'Read a local folder for batch import and combine with WhatsApp or email delivery.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _folderController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: tr(
                          context,
                          pt: 'Pasta de entrada (ex: C:\\Fotos\\Evento)',
                          es: 'Carpeta de entrada (ej: C:\\Fotos\\Evento)',
                          en: 'Input folder (e.g.: C:\\Photos\\Event)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _ingesting ? null : _ingestFromFolder,
                        child: Text(_ingesting
                            ? tr(
                                context,
                                pt: 'Processando...',
                                es: 'Procesando...',
                                en: 'Processing...',
                              )
                            : tr(
                                context,
                                pt: 'Ler pasta de entrada',
                                es: 'Leer carpeta de entrada',
                                en: 'Read input folder',
                              )),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _ingesting ? null : _ingestManual,
                        child: Text(
                          tr(
                            context,
                            pt: 'Selecionar fotos manualmente',
                            es: 'Seleccionar fotos manualmente',
                            en: 'Select photos manually',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        context,
                        pt: 'Pagamentos suportados: Pix e PayPal.',
                        es: 'Pagos soportados: Pix y PayPal.',
                        en: 'Supported payments: Pix and PayPal.',
                      ),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            RecentPhotosPage(
              key: ValueKey('quick_recent_$_recentPhotosRefreshToken'),
              database: widget.database,
              settingsStore: widget.settingsStore,
              requirePayment: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ingestFromFolder() async {
    final folderPath = _folderController.text.trim();
    if (folderPath.isEmpty) {
      return;
    }

    if (Platform.isAndroid && RegExp(r'^[A-Za-z]:\\').hasMatch(folderPath)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Caminho do Windows detectado. No Android, use caminho local do dispositivo ou "Selecionar fotos manualmente".',
              es: 'Se detectó una ruta de Windows. En Android, usa una ruta local del dispositivo o "Seleccionar fotos manualmente".',
              en: 'Windows path detected. On Android, use a local device path or "Select photos manually".',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _ingesting = true);
    final result = await _ingestionService.ingestFromFolder(
      directory: Directory(folderPath),
    );
    await widget.settingsStore.savePreferredInputFolder(folderPath);
    if (!mounted) {
      return;
    }
    setState(() {
      _ingesting = false;
      if (result.insertedCount > 0) {
        _recentPhotosRefreshToken++;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.insertedCount > 0
              ? tr(
                  context,
                  pt: '${result.insertedCount} foto(s) importada(s) da pasta.',
                  es: '${result.insertedCount} foto(s) importada(s) desde la carpeta.',
                  en: '${result.insertedCount} photo(s) imported from the folder.',
                )
              : tr(
                  context,
                  pt: 'Nenhuma foto importada. Verifique se a pasta está no dispositivo Android e contém arquivos suportados (jpg, jpeg, png, heic, webp).',
                  es: 'No se importaron fotos. Verifica si la carpeta está en el dispositivo Android y contiene archivos soportados (jpg, jpeg, png, heic, webp).',
                  en: 'No photos were imported. Check if the folder is on the Android device and has supported files (jpg, jpeg, png, heic, webp).',
                ),
        ),
      ),
    );
  }

  Future<void> _ingestManual() async {
    setState(() => _ingesting = true);
    final result = await _ingestionService.ingestFromManualPicker();
    if (!mounted) {
      return;
    }
    setState(() {
      _ingesting = false;
      if (result.insertedCount > 0) {
        _recentPhotosRefreshToken++;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: '${result.insertedCount} foto(s) importada(s) manualmente.',
            es: '${result.insertedCount} foto(s) importada(s) manualmente.',
            en: '${result.insertedCount} photo(s) imported manually.',
          ),
        ),
      ),
    );
  }
}

class PhotoDispatchModulePage extends StatefulWidget {
  const PhotoDispatchModulePage({
    required this.database,
    required this.settingsStore,
    super.key,
  });

  final AppDatabase database;
  final AppSettingsStore settingsStore;

  @override
  State<PhotoDispatchModulePage> createState() =>
      _PhotoDispatchModulePageState();
}

class _PhotoDispatchModulePageState extends State<PhotoDispatchModulePage> {
  late final PhotoIngestionService _ingestionService;
  List<DeliveryHistoryEntry> _history = const [];
  bool _loading = true;
  bool _searchingPhotos = false;
  int _recentPhotosRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _ingestionService = PhotoIngestionService(database: widget.database);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await widget.settingsStore.loadDeliveryHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topHistory = _history.take(5).toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: ClickPixPageTitle(
          title: tr(
            context,
            pt: 'Envio de fotos',
            es: 'Envío de fotos',
            en: 'Photo dispatch',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            tooltip: tr(
              context,
              pt: 'Atualizar histórico',
              es: 'Actualizar historial',
              en: 'Refresh history',
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(
                          context,
                          pt: 'Modo sem pagamento',
                          es: 'Modo sin pago',
                          en: 'No-payment mode',
                        ),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        context,
                        pt: 'Use este modo para reenvios rápidos e novos envios livres, sem etapa de cobrança.',
                        es: 'Usa este modo para reenvíos rápidos y nuevos envíos libres, sin etapa de cobro.',
                        en: 'Use this mode for quick resends and new free deliveries, without payment step.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _searchingPhotos ? null : _searchAndImportPhotos,
                        icon: _searchingPhotos
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          tr(
                            context,
                            pt: _searchingPhotos
                                ? 'Buscando...'
                                : 'Procurar fotos',
                            es: _searchingPhotos
                                ? 'Buscando...'
                                : 'Buscar fotos',
                            en: _searchingPhotos
                                ? 'Searching...'
                                : 'Search photos',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr(
                        context,
                        pt: 'O seletor usa carregamento nativo sob demanda para evitar travamentos em bibliotecas grandes.',
                        es: 'El selector usa carga nativa bajo demanda para evitar bloqueos en bibliotecas grandes.',
                        en: 'The picker uses native on-demand loading to avoid freezes on large libraries.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const LinearProgressIndicator()
                    else if (topHistory.isEmpty)
                      Text(
                        tr(
                          context,
                          pt: 'Sem histórico recente de envio.',
                          es: 'Sin historial reciente de envíos.',
                          en: 'No recent dispatch history.',
                        ),
                      )
                    else
                      ...topHistory.map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history),
                          title: Text('${entry.clientName} - ${entry.channel}'),
                          subtitle: Text(
                            '${entry.photoCount} foto(s) - ${entry.createdAt}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openHistoryPage,
                        icon: const Icon(Icons.history_toggle_off),
                        label: Text(
                          tr(
                            context,
                            pt: 'Ver hist\u00f3rico',
                            es: 'Ver historial',
                            en: 'View history',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _confirmClearHistory,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          tr(
                            context,
                            pt: 'Apagar hist\u00f3rico',
                            es: 'Borrar historial',
                            en: 'Clear history',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            RecentPhotosPage(
              key: ValueKey('dispatch_recent_$_recentPhotosRefreshToken'),
              database: widget.database,
              settingsStore: widget.settingsStore,
              requirePayment: false,
              onDeliveryRegistered: _loadHistory,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAndImportPhotos() async {
    setState(() => _searchingPhotos = true);
    final result = await _ingestionService.ingestFromManualPicker();
    if (!mounted) {
      return;
    }
    setState(() {
      _searchingPhotos = false;
      if (result.insertedCount > 0) {
        _recentPhotosRefreshToken++;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.insertedCount > 0
              ? tr(
                  context,
                  pt: '${result.insertedCount} foto(s) encontradas e adicionadas ao feed.',
                  es: '${result.insertedCount} foto(s) encontradas y agregadas al feed.',
                  en: '${result.insertedCount} photo(s) found and added to the feed.',
                )
              : tr(
                  context,
                  pt: 'Nenhuma nova foto foi selecionada.',
                  es: 'No se seleccionaron fotos nuevas.',
                  en: 'No new photos were selected.',
                ),
        ),
      ),
    );
  }

  Future<void> _openHistoryPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryHistoryPage(
          settingsStore: widget.settingsStore,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    _loadHistory();
  }

  Future<void> _confirmClearHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          tr(
            context,
            pt: 'Apagar hist\u00f3rico',
            es: 'Borrar historial',
            en: 'Clear history',
          ),
        ),
        content: Text(
          tr(
            context,
            pt: 'Deseja apagar todo o hist\u00f3rico de envios?',
            es: '\u00bfDeseas borrar todo el historial de env\u00edos?',
            en: 'Do you want to clear all dispatch history?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              tr(
                context,
                pt: 'Cancelar',
                es: 'Cancelar',
                en: 'Cancel',
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              tr(
                context,
                pt: 'Apagar',
                es: 'Borrar',
                en: 'Clear',
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldClear != true) {
      return;
    }

    await widget.settingsStore.clearDeliveryHistory();
    if (!mounted) {
      return;
    }
    await _loadHistory();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Hist\u00f3rico apagado com sucesso.',
            es: 'Historial borrado con \u00e9xito.',
            en: 'History cleared successfully.',
          ),
        ),
      ),
    );
  }
}

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({
    required this.settingsStore,
    super.key,
  });

  final AppSettingsStore settingsStore;

  @override
  State<DeliveryHistoryPage> createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  static const List<_HistoryPeriodOption> _periods = [
    _HistoryPeriodOption('all', null),
    _HistoryPeriodOption('last_7_days', Duration(days: 7)),
    _HistoryPeriodOption('last_30_days', Duration(days: 30)),
    _HistoryPeriodOption('last_90_days', Duration(days: 90)),
    _HistoryPeriodOption('last_365_days', Duration(days: 365)),
  ];

  _HistoryPeriodOption _selectedPeriod = _periods.first;
  List<DeliveryHistoryEntry> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final history = await widget.settingsStore.loadDeliveryHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _filterHistory(_history, _selectedPeriod);
    final groupedHistory = _groupByDay(filteredHistory);
    return Scaffold(
      appBar: AppBar(
        title: ClickPixPageTitle(
          title: tr(
            context,
            pt: 'Histórico de envios',
            es: 'Historial de envíos',
            en: 'Dispatch history',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: tr(
              context,
              pt: 'Atualizar',
              es: 'Actualizar',
              en: 'Refresh',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<_HistoryPeriodOption>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Período',
                  es: 'Período',
                  en: 'Period',
                ),
              ),
              items: _periods
                  .map(
                    (period) => DropdownMenuItem(
                      value: period,
                      child: Text(_historyPeriodLabel(context, period)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (next) {
                if (next == null) {
                  return;
                }
                setState(() => _selectedPeriod = next);
              },
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (groupedHistory.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    tr(
                      context,
                      pt: 'Nenhum envio encontrado para o período.',
                      es: 'No se encontraron envíos para el período.',
                      en: 'No dispatches found for this period.',
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: groupedHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final group = groupedHistory[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDay(group.day),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ...group.entries.map(
                              (entry) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.receipt_long),
                                title: Text(entry.clientName),
                                subtitle: Text(
                                  '${entry.photoCount} foto(s) - ${entry.paymentMethodLabel} - ${_historyTime(entry.createdAt)}',
                                ),
                                trailing: Text(
                                  _historyMoney(entry.totalAmountCents),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DeliveryHistoryEntry> _filterHistory(
    List<DeliveryHistoryEntry> source,
    _HistoryPeriodOption period,
  ) {
    if (period.duration == null) {
      return source;
    }
    final minDate = DateTime.now().subtract(period.duration!);
    return source
        .where((entry) => !entry.createdAt.isBefore(minDate))
        .toList(growable: false);
  }

  List<_HistoryGroup> _groupByDay(List<DeliveryHistoryEntry> source) {
    final grouped = <DateTime, List<DeliveryHistoryEntry>>{};
    for (final entry in source) {
      final day = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      grouped.putIfAbsent(day, () => <DeliveryHistoryEntry>[]).add(entry);
    }

    final keys = grouped.keys.toList(growable: false)
      ..sort((a, b) => b.compareTo(a));
    return keys
        .map(
          (day) => _HistoryGroup(
            day: day,
            entries: grouped[day]!
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          ),
        )
        .toList(growable: false);
  }

  String _historyPeriodLabel(
      BuildContext context, _HistoryPeriodOption period) {
    switch (period.id) {
      case 'all':
        return tr(context, pt: 'Todos', es: 'Todos', en: 'All');
      case 'last_7_days':
        return tr(context,
            pt: 'Últimos 7 dias', es: 'Últimos 7 días', en: 'Last 7 days');
      case 'last_30_days':
        return tr(context,
            pt: 'Últimos 30 dias', es: 'Últimos 30 días', en: 'Last 30 days');
      case 'last_90_days':
        return tr(context,
            pt: 'Últimos 90 dias', es: 'Últimos 90 días', en: 'Last 90 days');
      case 'last_365_days':
        return tr(context,
            pt: 'Últimos 12 meses',
            es: 'Últimos 12 meses',
            en: 'Last 12 months');
      default:
        return tr(context, pt: 'Período', es: 'Período', en: 'Period');
    }
  }

  String _historyMoney(int cents) {
    final value = cents / 100.0;
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _formatDay(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = date.year.toString();
    return '$dd/$mm/$yy';
  }

  String _historyTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _HistoryPeriodOption {
  const _HistoryPeriodOption(this.id, this.duration);

  final String id;
  final Duration? duration;
}

class _HistoryGroup {
  const _HistoryGroup({
    required this.day,
    required this.entries,
  });

  final DateTime day;
  final List<DeliveryHistoryEntry> entries;
}

class SalesAndDispatchesPage extends StatefulWidget {
  const SalesAndDispatchesPage({
    required this.database,
    required this.settingsStore,
    super.key,
  });

  final AppDatabase database;
  final AppSettingsStore settingsStore;

  @override
  State<SalesAndDispatchesPage> createState() => _SalesAndDispatchesPageState();
}

class _SalesAndDispatchesPageState extends State<SalesAndDispatchesPage> {
  static const int _pageSize = 5;
  static const List<_SalesWeeksFilter> _filters = [
    _SalesWeeksFilter('all', null),
    _SalesWeeksFilter('1', 1),
    _SalesWeeksFilter('2', 2),
    _SalesWeeksFilter('4', 4),
    _SalesWeeksFilter('8', 8),
    _SalesWeeksFilter('12', 12),
  ];

  _SalesWeeksFilter _selectedFilter = _filters.first;
  List<_SaleDispatchRecord> _records = const [];
  int _visibleCount = _pageSize;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);

    final history = await widget.settingsStore.loadDeliveryHistory();
    final orders = await widget.database.select(widget.database.orders).get();
    final items =
        await widget.database.select(widget.database.orderItems).get();
    final assets =
        await widget.database.select(widget.database.photoAssets).get();
    final now = DateTime.now();
    final minDate = _selectedFilter.weeks == null
        ? null
        : now.subtract(Duration(days: _selectedFilter.weeks! * 7));

    final ordersById = <String, Order>{
      for (final order in orders) order.id: order,
    };
    final itemsByOrderId = <String, List<OrderItem>>{};
    for (final item in items) {
      itemsByOrderId.putIfAbsent(item.orderId, () => <OrderItem>[]).add(item);
    }
    final assetsById = <String, PhotoAsset>{
      for (final asset in assets) asset.id: asset,
    };

    final filtered = history
        .where((entry) =>
            minDate == null || !entry.effectiveSaleDate.isBefore(minDate))
        .toList(growable: false)
      ..sort((a, b) => b.effectiveSaleDate.compareTo(a.effectiveSaleDate));

    final records = filtered
        .map(
          (entry) => _toSaleRecord(
            entry: entry,
            order: ordersById[entry.orderId],
            orderItems: itemsByOrderId[entry.orderId] ?? const [],
            assetsById: assetsById,
          ),
        )
        .toList(growable: false);

    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _visibleCount = _pageSize;
      _loading = false;
    });
  }

  _SaleDispatchRecord _toSaleRecord({
    required DeliveryHistoryEntry entry,
    required Order? order,
    required List<OrderItem> orderItems,
    required Map<String, PhotoAsset> assetsById,
  }) {
    final paymentMethod = _paymentMethodLabel(entry: entry, order: order);
    final comboName = _comboName(entry);
    final unitPriceCents = entry.unitPriceCents > 0
        ? entry.unitPriceCents
        : _fallbackUnitPrice(entry: entry, orderItems: orderItems);
    final fileNames = entry.photoFileNames.isNotEmpty
        ? entry.photoFileNames
        : _fallbackFileNames(orderItems: orderItems, assetsById: assetsById);

    return _SaleDispatchRecord(
      clientName: entry.clientName.trim(),
      clientWhatsapp: entry.clientWhatsapp.trim(),
      clientEmail: entry.clientEmail.trim(),
      saleNumber: entry.orderId.trim().isEmpty ? entry.id : entry.orderId,
      paymentMethod: paymentMethod,
      photoCount: entry.photoCount,
      comboName: comboName,
      unitPriceCents: unitPriceCents,
      totalAmountCents: entry.totalAmountCents,
      databaseCode: entry.databaseCode.trim(),
      databaseCodeExpiresAt: entry.databaseCodeExpiresAt,
      saleDate: entry.effectiveSaleDate,
      fileNames: fileNames,
    );
  }

  String _paymentMethodLabel({
    required DeliveryHistoryEntry entry,
    required Order? order,
  }) {
    if (!entry.paymentRequired) {
      return tr(
        context,
        pt: 'Sem pagamento',
        es: 'Sin pago',
        en: 'No payment',
      );
    }

    final orderPaymentMethod = order?.paymentMethod.trim().toLowerCase() ?? '';
    if (orderPaymentMethod == 'paypal') {
      return 'PayPal';
    }
    if (orderPaymentMethod == 'pix') {
      return 'Pix';
    }

    final fromLabel = entry.paymentMethodLabel.trim().toLowerCase();
    if (fromLabel.contains('paypal')) {
      return 'PayPal';
    }
    return 'Pix';
  }

  String _comboName(DeliveryHistoryEntry entry) {
    final direct = entry.comboName.trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    final label = entry.paymentMethodLabel;
    final splitIndex = label.indexOf(' - ');
    if (splitIndex < 0 || splitIndex >= label.length - 3) {
      return '';
    }
    final raw = label.substring(splitIndex + 3).trim();
    return raw.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '').trim();
  }

  int _fallbackUnitPrice({
    required DeliveryHistoryEntry entry,
    required List<OrderItem> orderItems,
  }) {
    if (orderItems.isNotEmpty) {
      final total = orderItems.fold<int>(
        0,
        (sum, item) => sum + item.unitPriceCents,
      );
      return (total / orderItems.length).round();
    }
    if (entry.photoCount > 0) {
      return (entry.totalAmountCents / entry.photoCount).round();
    }
    return 0;
  }

  List<String> _fallbackFileNames({
    required List<OrderItem> orderItems,
    required Map<String, PhotoAsset> assetsById,
  }) {
    if (orderItems.isEmpty) {
      return const [];
    }

    final names = <String>[];
    for (final item in orderItems) {
      final photoAsset = assetsById[item.photoAssetId];
      if (photoAsset == null) {
        names.add(item.photoAssetId);
        continue;
      }
      final localPath = photoAsset.localPath.trim();
      if (localPath.isNotEmpty && !localPath.startsWith('asset://')) {
        names.add(p.basename(localPath));
      } else {
        names.add(photoAsset.id);
      }
    }
    return names.take(120).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final recordsToShow = _records.take(_visibleCount).toList(growable: false);
    final canLoadMore = _visibleCount < _records.length;

    return Scaffold(
      appBar: AppBar(
        title: ClickPixPageTitle(
          title: tr(
            context,
            pt: 'Vendas e envios',
            es: 'Ventas y env\u00edos',
            en: 'Sales and dispatches',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: tr(
              context,
              pt: 'Atualizar',
              es: 'Actualizar',
              en: 'Refresh',
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<_SalesWeeksFilter>(
              value: _selectedFilter,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Per\u00edodo semanal',
                  es: 'Per\u00edodo semanal',
                  en: 'Weekly period',
                ),
              ),
              items: _filters
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(_filterLabel(context, option)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (next) {
                if (next == null) {
                  return;
                }
                setState(() => _selectedFilter = next);
                _reload();
              },
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (recordsToShow.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    tr(
                      context,
                      pt: 'Nenhum registro encontrado para o período.',
                      es: 'No se encontraron registros para el período.',
                      en: 'No records found for this period.',
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: recordsToShow.length + (canLoadMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (canLoadMore && index == recordsToShow.length) {
                      return Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _visibleCount = (_visibleCount + _pageSize)
                                  .clamp(0, _records.length);
                            });
                          },
                          icon: const Icon(Icons.expand_more),
                          label: Text(
                            tr(
                              context,
                              pt: 'Ver mais',
                              es: 'Ver m\u00e1s',
                              en: 'View more',
                            ),
                          ),
                        ),
                      );
                    }

                    final record = recordsToShow[index];
                    final notProvided = tr(
                      context,
                      pt: 'N\u00e3o informado',
                      es: 'No informado',
                      en: 'Not provided',
                    );
                    final databaseCodeLabel = record.databaseCode.isEmpty
                        ? notProvided
                        : record.databaseCode;
                    final expiryLabel = record.databaseCodeExpiresAt == null
                        ? notProvided
                        : _formatDateTime(record.databaseCodeExpiresAt!);
                    final comboLabel = record.comboName.isEmpty
                        ? tr(
                            context,
                            pt: 'N\u00e3o aplicado',
                            es: 'No aplicado',
                            en: 'Not applied',
                          )
                        : record.comboName;
                    final filesText = record.fileNames.isEmpty
                        ? tr(
                            context,
                            pt: 'Nenhum nome de arquivo registrado.',
                            es: 'No hay nombres de archivo registrados.',
                            en: 'No file names were recorded.',
                          )
                        : record.fileNames.join(', ');
                    final photosLabel = tr(
                      context,
                      pt: 'fotos',
                      es: 'fotos',
                      en: 'photos',
                    );

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          12,
                        ),
                        leading: Icon(
                          record.paymentMethod == 'PayPal'
                              ? Icons.account_balance_wallet
                              : Icons.qr_code_2,
                        ),
                        title: Text(
                          '${record.clientName} - ${record.saleNumber}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${record.paymentMethod} \u00b7 ${record.photoCount} $photosLabel \u00b7 ${_money(record.totalAmountCents)}',
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'Data da venda', es: 'Fecha de venta', en: 'Sale date')}: ${_formatDateTime(record.saleDate)}',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Cliente: ${record.clientName}'),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('WhatsApp: ${record.clientWhatsapp}'),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'E-mail: ${record.clientEmail.isEmpty ? notProvided : record.clientEmail}',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'M\u00e9todo de pagamento', es: 'M\u00e9todo de pago', en: 'Payment method')}: ${record.paymentMethod}',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'Fotos enviadas/vendidas', es: 'Fotos enviadas/vendidas', en: 'Photos sent/sold')}: ${record.photoCount}',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'Combo usado', es: 'Combo usado', en: 'Combo used')}: $comboLabel',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'Valor por foto', es: 'Valor por foto', en: 'Price per photo')}: ${_money(record.unitPriceCents)}',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'Valor total', es: 'Valor total', en: 'Total amount')}: ${_money(record.totalAmountCents)}',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'C\u00f3digo do banco/site', es: 'C\u00f3digo banco/sitio', en: 'Website/database code')}: $databaseCodeLabel',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tr(context, pt: 'Expira em', es: 'Vence en', en: 'Expires at')}: $expiryLabel',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              tr(
                                context,
                                pt: 'Arquivos enviados:',
                                es: 'Archivos enviados:',
                                en: 'Sent files:',
                              ),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(filesText),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(BuildContext context, _SalesWeeksFilter filter) {
    if (filter.weeks == null) {
      return tr(
        context,
        pt: 'Todas as semanas',
        es: 'Todas las semanas',
        en: 'All weeks',
      );
    }
    return tr(
      context,
      pt: '\u00daltimas ${filter.weeks} semana(s)',
      es: '\u00daltimas ${filter.weeks} semana(s)',
      en: 'Last ${filter.weeks} week(s)',
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _money(int cents) {
    final value = cents / 100.0;
    return 'R\$ ${value.toStringAsFixed(2)}';
  }
}

class _SalesWeeksFilter {
  const _SalesWeeksFilter(this.id, this.weeks);

  final String id;
  final int? weeks;
}

class _SaleDispatchRecord {
  const _SaleDispatchRecord({
    required this.clientName,
    required this.clientWhatsapp,
    required this.clientEmail,
    required this.saleNumber,
    required this.paymentMethod,
    required this.photoCount,
    required this.comboName,
    required this.unitPriceCents,
    required this.totalAmountCents,
    required this.databaseCode,
    required this.databaseCodeExpiresAt,
    required this.saleDate,
    required this.fileNames,
  });

  final String clientName;
  final String clientWhatsapp;
  final String clientEmail;
  final String saleNumber;
  final String paymentMethod;
  final int photoCount;
  final String comboName;
  final int unitPriceCents;
  final int totalAmountCents;
  final String databaseCode;
  final DateTime? databaseCodeExpiresAt;
  final DateTime saleDate;
  final List<String> fileNames;
}

class AppConfigurationPage extends StatefulWidget {
  const AppConfigurationPage({
    required this.settingsStore,
    required this.locale,
    required this.visualSettings,
    required this.backgroundSettings,
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    required this.onBackgroundSettingsChanged,
    super.key,
  });

  final AppSettingsStore settingsStore;
  final Locale locale;
  final AppVisualSettings visualSettings;
  final AppBackgroundSettings backgroundSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings)
      onVisualSettingsChanged;
  final Future<void> Function(AppBackgroundSettings settings)
      onBackgroundSettingsChanged;

  @override
  State<AppConfigurationPage> createState() => _AppConfigurationPageState();
}

class _AppConfigurationPageState extends State<AppConfigurationPage> {
  static const String _sectionPhotographerProfile = 'photographer_profile';
  static const String _sectionPhotoCombos = 'photo_combos';
  static const String _sectionOperational = 'operational_parameters';
  static const String _sectionAccessibility = 'accessibility_display';
  static const String _sectionMessageBase = 'message_base';
  static const String _sectionPixIntegration = 'pix_integration';
  static const String _sectionWebAccess = 'web_access';
  static const String _sectionAdminSecurity = 'admin_security';

  final _photographerNameController = TextEditingController();
  final _photographerWhatsappController = TextEditingController();
  final _photographerEmailController = TextEditingController();
  final _profileAdminPasswordController = TextEditingController();
  final _pixKeyController = TextEditingController();
  final _paypalController = TextEditingController();
  final _paymentApiBaseUrlController = TextEditingController();
  final _paymentApiTokenController = TextEditingController();
  final _adminCurrentPasswordController = TextEditingController();
  final _adminNewPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();
  final _webBaseDomainController = TextEditingController();
  final _webPortController = TextEditingController();
  final _webDbUsernameController = TextEditingController();
  final _webDbPasswordController = TextEditingController();
  final _messageTemplateController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _wifiOnly = false;
  int _accessCodeDays = 7;
  List<PictureComboPricing> _pictureCombos = const [];
  PaymentProvider _paymentProvider = PaymentProvider.manual;
  ClientMessageTemplateSettings _messageTemplateSettings =
      const ClientMessageTemplateSettings();
  String _selectedTemplateLanguage = 'pt';
  late AppVisualSettings _visualSettings;
  late AppBackgroundSettings _backgroundSettings;
  bool _savingBackground = false;
  bool _savingBusinessProfile = false;
  bool _savingAdminCredentials = false;
  String _adminUsername = AppSettingsStore.defaultAdminUsername;
  final Map<String, bool> _expandedSections = <String, bool>{
    _sectionPhotographerProfile: true,
    _sectionPhotoCombos: false,
    _sectionOperational: false,
    _sectionAccessibility: false,
    _sectionMessageBase: false,
    _sectionPixIntegration: false,
    _sectionWebAccess: false,
    _sectionAdminSecurity: false,
  };
  String get _currentAccentFamily =>
      _accentFamilyFromKey(_visualSettings.accentColorKey);

  @override
  void initState() {
    super.initState();
    _visualSettings = widget.visualSettings;
    _backgroundSettings = widget.backgroundSettings;
    _loadSettings();
  }

  @override
  void dispose() {
    _photographerNameController.dispose();
    _photographerWhatsappController.dispose();
    _photographerEmailController.dispose();
    _profileAdminPasswordController.dispose();
    _pixKeyController.dispose();
    _paypalController.dispose();
    _paymentApiBaseUrlController.dispose();
    _paymentApiTokenController.dispose();
    _adminCurrentPasswordController.dispose();
    _adminNewPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    _webBaseDomainController.dispose();
    _webPortController.dispose();
    _webDbUsernameController.dispose();
    _webDbPasswordController.dispose();
    _messageTemplateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final businessProfile = await widget.settingsStore.loadBusinessProfile();
    final credentials = await widget.settingsStore.loadAdminCredentials();
    final delivery = await widget.settingsStore.loadDeliverySettings();
    final pictureCombos = await widget.settingsStore.loadPictureCombos();
    final paymentIntegration =
        await widget.settingsStore.loadPaymentIntegrationSettings();
    final webAccessSettings =
        await widget.settingsStore.loadDeliveryWebAccessSettings();
    final messageTemplateSettings =
        await widget.settingsStore.loadClientMessageTemplates();
    if (!mounted) {
      return;
    }
    setState(() {
      _photographerNameController.text = businessProfile.photographerName;
      _photographerWhatsappController.text =
          businessProfile.photographerWhatsapp;
      _photographerEmailController.text = businessProfile.photographerEmail;
      _pixKeyController.text = businessProfile.photographerPixKey;
      _paypalController.text = businessProfile.photographerPaypal;
      _adminUsername = credentials.username;
      _wifiOnly = delivery.wifiOnly;
      _accessCodeDays = delivery.accessCodeValidityDays;
      _pictureCombos = pictureCombos;
      _paymentProvider = paymentIntegration.provider;
      _paymentApiBaseUrlController.text = paymentIntegration.apiBaseUrl;
      _paymentApiTokenController.text = paymentIntegration.apiToken;
      _webBaseDomainController.text = webAccessSettings.baseDomainUrl;
      _webPortController.text =
          webAccessSettings.port == null ? '' : '${webAccessSettings.port}';
      _webDbUsernameController.text = webAccessSettings.dbUsername;
      _webDbPasswordController.text = webAccessSettings.dbPassword;
      _messageTemplateSettings = messageTemplateSettings;
      _messageTemplateController.text = messageTemplateSettings
          .templateForLanguage(_selectedTemplateLanguage);
    });
  }

  Future<void> _updateAccentColor({
    String? family,
  }) async {
    final nextKey = _accentToken(family ?? _currentAccentFamily);
    final next = _visualSettings.copyWith(accentColorKey: nextKey);
    setState(() => _visualSettings = next);
    await widget.onVisualSettingsChanged(next);
  }

  void _onPaymentProviderChanged(PaymentProvider provider) {
    final currentUrl = _paymentApiBaseUrlController.text.trim();
    final currentSuggestion =
        _paymentProviderDefaultApiBaseUrls[_paymentProvider];
    final nextSuggestion = _paymentProviderDefaultApiBaseUrls[provider];
    if (currentUrl.isEmpty ||
        (currentSuggestion != null && currentUrl == currentSuggestion)) {
      _paymentApiBaseUrlController.text = nextSuggestion ?? '';
    }
    setState(() => _paymentProvider = provider);
  }

  void _cacheCurrentTemplateDraft() {
    _messageTemplateSettings =
        _messageTemplateSettings.copyWithLanguageTemplate(
      languageCode: _selectedTemplateLanguage,
      template: _messageTemplateController.text,
    );
  }

  void _onTemplateLanguageChanged(String languageCode) {
    _cacheCurrentTemplateDraft();
    setState(() {
      _selectedTemplateLanguage = languageCode;
      _messageTemplateController.text =
          _messageTemplateSettings.templateForLanguage(languageCode);
    });
  }

  String _defaultTemplateForLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'es':
        return ClientMessageTemplateSettings.defaultEsTemplate;
      case 'en':
        return ClientMessageTemplateSettings.defaultEnTemplate;
      case 'pt':
      default:
        return ClientMessageTemplateSettings.defaultPtTemplate;
    }
  }

  Future<void> _saveWebAccessSettings() async {
    final rawPort = _webPortController.text.trim();
    int? parsedPort;
    if (rawPort.isNotEmpty) {
      parsedPort = int.tryParse(rawPort);
      if (parsedPort == null || parsedPort <= 0 || parsedPort > 65535) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                pt: 'Porta inválida. Use um número entre 1 e 65535.',
                es: 'Puerto inválido. Usa un número entre 1 y 65535.',
                en: 'Invalid port. Use a number between 1 and 65535.',
              ),
            ),
          ),
        );
        return;
      }
    }

    final next = DeliveryWebAccessSettings(
      baseDomainUrl: _webBaseDomainController.text.trim().isEmpty
          ? DeliveryWebAccessSettings.defaultBaseDomainUrl
          : _webBaseDomainController.text.trim(),
      port: parsedPort,
      dbUsername: _webDbUsernameController.text.trim(),
      dbPassword: _webDbPasswordController.text,
    );

    await widget.settingsStore.saveDeliveryWebAccessSettings(next);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Acesso web e credenciais salvos.',
            es: 'Acceso web y credenciales guardados.',
            en: 'Web access and credentials saved.',
          ),
        ),
      ),
    );
  }

  Future<void> _saveClientMessageTemplates() async {
    _cacheCurrentTemplateDraft();
    final sanitized = ClientMessageTemplateSettings(
      ptTemplate: _messageTemplateSettings.ptTemplate.trim().isEmpty
          ? ClientMessageTemplateSettings.defaultPtTemplate
          : _messageTemplateSettings.ptTemplate,
      esTemplate: _messageTemplateSettings.esTemplate.trim().isEmpty
          ? ClientMessageTemplateSettings.defaultEsTemplate
          : _messageTemplateSettings.esTemplate,
      enTemplate: _messageTemplateSettings.enTemplate.trim().isEmpty
          ? ClientMessageTemplateSettings.defaultEnTemplate
          : _messageTemplateSettings.enTemplate,
    );
    await widget.settingsStore.saveClientMessageTemplates(sanitized);
    if (!mounted) {
      return;
    }
    setState(() {
      _messageTemplateSettings = sanitized;
      _messageTemplateController.text =
          sanitized.templateForLanguage(_selectedTemplateLanguage);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Mensagem base atualizada.',
            es: 'Mensaje base actualizado.',
            en: 'Base message updated.',
          ),
        ),
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final backgroundDir = Directory(p.join(docsDir.path, 'theme_background'));
    if (!backgroundDir.existsSync()) {
      await backgroundDir.create(recursive: true);
    }
    final extension = p.extension(picked.path);
    final normalizedExtension = extension.isEmpty ? '.jpg' : extension;
    final targetFile = File(
      p.join(backgroundDir.path, 'background$normalizedExtension'),
    );
    await File(picked.path).copy(targetFile.path);

    if (!mounted) {
      return;
    }
    await _saveBackgroundSettings(
      _backgroundSettings.copyWith(imagePath: targetFile.path),
    );
  }

  Future<void> _clearBackgroundImage() async {
    if (_backgroundSettings.imagePath.trim().isNotEmpty) {
      final previous = File(_backgroundSettings.imagePath.trim());
      if (previous.existsSync()) {
        try {
          await previous.delete();
        } on Object {
          // Best-effort cleanup; keep app flow even if file remains.
        }
      }
    }
    await _saveBackgroundSettings(
      _backgroundSettings.copyWith(imagePath: ''),
    );
  }

  Future<void> _saveBackgroundSettings(AppBackgroundSettings next) async {
    setState(() {
      _backgroundSettings = next;
      _savingBackground = true;
    });
    await widget.onBackgroundSettingsChanged(next);
    if (!mounted) {
      return;
    }
    setState(() => _savingBackground = false);
  }

  bool _isSectionExpanded(String sectionId) {
    return _expandedSections[sectionId] ?? false;
  }

  void _toggleSection(String sectionId) {
    setState(() {
      _expandedSections[sectionId] = !_isSectionExpanded(sectionId);
    });
  }

  Widget _buildToggleableSettingsSection({
    required BuildContext context,
    required String sectionId,
    required String title,
    required Widget child,
  }) {
    final expanded = _isSectionExpanded(sectionId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            onTap: () => _toggleSection(sectionId),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClickPixPageTitle(
          title: tr(
            context,
            pt: 'Configurações',
            es: 'Configuración',
            en: 'Settings',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionPhotographerProfile,
              title: tr(
                context,
                pt: 'Perfil do Fotógrafo',
                es: 'Perfil del fotógrafo',
                en: 'Photographer profile',
              ),
              child: _buildPhotographerProfileCard(context, showTitle: false),
            ),
            const SizedBox(height: 16),
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionPhotoCombos,
              title: tr(
                context,
                pt: 'Combos de fotos',
                es: 'Combos de fotos',
                en: 'Photo combos',
              ),
              child: _buildPictureCombosCard(context, showTitle: false),
            ),
            const SizedBox(height: 16),
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionOperational,
              title: tr(
                context,
                pt: 'Parâmetros operacionais',
                es: 'Parámetros operativos',
                en: 'Operational parameters',
              ),
              child: _buildOperationalParametersCard(context, showTitle: false),
            ),
            const SizedBox(height: 16),
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionAccessibility,
              title: tr(
                context,
                pt: 'Acessibilidade e exibição',
                es: 'Accesibilidad y visualización',
                en: 'Accessibility and display',
              ),
              child:
                  _buildAccessibilityAndDisplayCard(context, showTitle: false),
            ),
            const SizedBox(height: 16),
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionMessageBase,
              title: tr(
                context,
                pt: 'Mensagem base de envio',
                es: 'Mensaje base de envío',
                en: 'Dispatch base message',
              ),
              child: _buildMessageBaseCard(context, showTitle: false),
            ),
            const SizedBox(height: 16),
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionPixIntegration,
              title: tr(
                context,
                pt: 'Integração Pix por banco',
                es: 'Integración Pix por banco',
                en: 'Bank Pix integration',
              ),
              child: _buildPixIntegrationCard(context, showTitle: false),
            ),
            const SizedBox(height: 16),
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionWebAccess,
              title: tr(
                context,
                pt: 'Acesso web e banco do site',
                es: 'Acceso web y base de datos del sitio',
                en: 'Website access and database',
              ),
              child: _buildWebAccessCard(context, showTitle: false),
            ),
            const SizedBox(height: 16),
            _buildToggleableSettingsSection(
              context: context,
              sectionId: _sectionAdminSecurity,
              title: tr(
                context,
                pt: 'Segurança do administrador',
                es: 'Seguridad del administrador',
                en: 'Administrator security',
              ),
              child: _buildAdminSecurityCard(context, showTitle: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotographerProfileCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Perfil do Fotógrafo',
                  es: 'Perfil del fotógrafo',
                  en: 'Photographer profile',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _photographerNameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Nome do fotógrafo',
                  es: 'Nombre del fotógrafo',
                  en: 'Photographer name',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _photographerWhatsappController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'WhatsApp pessoal',
                  es: 'WhatsApp personal',
                  en: 'Personal WhatsApp',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _photographerEmailController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'E-mail pessoal (recuperação de senha)',
                  es: 'Correo personal (recuperación de contraseña)',
                  en: 'Personal email (password recovery)',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pixKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Chave Pix',
                  es: 'Clave Pix',
                  en: 'Pix key',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paypalController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Conta PayPal (e-mail/usuário)',
                  es: 'Cuenta PayPal (correo/usuario)',
                  en: 'PayPal account (email/username)',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _profileAdminPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Senha do administrador (confirmação)',
                  es: 'Contraseña del administrador (confirmación)',
                  en: 'Administrator password (confirmation)',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _savingBusinessProfile ? null : _saveBusinessProfile,
                child: Text(
                  tr(
                    context,
                    pt: _savingBusinessProfile
                        ? 'Salvando...'
                        : 'Salvar perfil',
                    es: _savingBusinessProfile
                        ? 'Guardando...'
                        : 'Guardar perfil',
                    en: _savingBusinessProfile ? 'Saving...' : 'Save profile',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPictureCombosCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Combos de fotos',
                  es: 'Combos de fotos',
                  en: 'Photo combos',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              tr(
                context,
                pt: 'Configure regras de preço por quantidade. Exemplo: a partir de 5 fotos, cada foto custa R\$ 5,00.',
                es: 'Configura reglas de precio por cantidad. Ejemplo: desde 5 fotos, cada foto cuesta R\$ 5,00.',
                en: 'Configure quantity-based pricing rules. Example: from 5 photos, each photo costs R\$ 5.00.',
              ),
            ),
            const SizedBox(height: 8),
            if (_pictureCombos.isEmpty)
              Text(
                tr(
                  context,
                  pt: 'Nenhum combo cadastrado.',
                  es: 'No hay combos registrados.',
                  en: 'No combos configured.',
                ),
              )
            else
              ..._pictureCombos.map(
                (combo) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(combo.name),
                  subtitle: Text(
                    tr(
                      context,
                      pt: 'A partir de ${combo.minimumPhotos} foto(s): ${_formatCurrency(combo.unitPriceCents)} por foto',
                      es: 'Desde ${combo.minimumPhotos} foto(s): ${_formatCurrency(combo.unitPriceCents)} por foto',
                      en: 'From ${combo.minimumPhotos} photo(s): ${_formatCurrency(combo.unitPriceCents)} per photo',
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _upsertPictureCombo(combo),
                        icon: const Icon(Icons.edit),
                        tooltip: tr(
                          context,
                          pt: 'Editar',
                          es: 'Editar',
                          en: 'Edit',
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removePictureCombo(combo.id),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: tr(
                          context,
                          pt: 'Remover',
                          es: 'Eliminar',
                          en: 'Delete',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _upsertPictureCombo(),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  tr(
                    context,
                    pt: 'Adicionar combo',
                    es: 'Agregar combo',
                    en: 'Add combo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalParametersCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Parâmetros operacionais',
                  es: 'Parámetros operativos',
                  en: 'Operational parameters',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            SwitchListTile(
              value: _wifiOnly,
              title: Text(
                tr(
                  context,
                  pt: 'Enviar somente em Wi-Fi',
                  es: 'Enviar solo por Wi-Fi',
                  en: 'Send only on Wi-Fi',
                ),
              ),
              onChanged: (value) => setState(() => _wifiOnly = value),
            ),
            ListTile(
              title: Text(
                tr(
                  context,
                  pt: 'Validade do código de acesso (dias)',
                  es: 'Validez del código de acceso (días)',
                  en: 'Access code validity (days)',
                ),
              ),
              subtitle: Text(
                tr(
                  context,
                  pt: '$_accessCodeDays dia(s)',
                  es: '$_accessCodeDays día(s)',
                  en: '$_accessCodeDays day(s)',
                ),
              ),
            ),
            Slider(
              value: _accessCodeDays.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              label: '$_accessCodeDays',
              onChanged: (value) =>
                  setState(() => _accessCodeDays = value.round()),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveOperationalSettings,
                child: Text(
                  tr(
                    context,
                    pt: 'Salvar parâmetros operacionais',
                    es: 'Guardar parámetros operativos',
                    en: 'Save operational parameters',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilityAndDisplayCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Acessibilidade e exibição',
                  es: 'Accesibilidad y visualización',
                  en: 'Accessibility and display',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            SwitchListTile(
              value: _visualSettings.highContrastEnabled,
              title: Text(
                tr(
                  context,
                  pt: 'Alto contraste',
                  es: 'Alto contraste',
                  en: 'High contrast',
                ),
              ),
              onChanged: (value) async {
                final next =
                    _visualSettings.copyWith(highContrastEnabled: value);
                setState(() => _visualSettings = next);
                await widget.onVisualSettingsChanged(next);
              },
            ),
            SwitchListTile(
              value: _visualSettings.solarLargeFontEnabled,
              title: Text(
                tr(
                  context,
                  pt: 'Modo Sol (fontes grandes)',
                  es: 'Modo Sol (fuentes grandes)',
                  en: 'Sun mode (large fonts)',
                ),
              ),
              onChanged: (value) async {
                final next =
                    _visualSettings.copyWith(solarLargeFontEnabled: value);
                setState(() => _visualSettings = next);
                await widget.onVisualSettingsChanged(next);
              },
            ),
            ListTile(
              title: Text(
                tr(
                  context,
                  pt: 'Tema',
                  es: 'Tema',
                  en: 'Theme',
                ),
              ),
              trailing: DropdownButton<ThemeMode>(
                value: _visualSettings.themeMode,
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }
                  final next = _visualSettings.copyWith(themeMode: value);
                  setState(() => _visualSettings = next);
                  await widget.onVisualSettingsChanged(next);
                },
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(
                      tr(context, pt: 'Sistema', es: 'Sistema', en: 'System'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(
                      tr(context, pt: 'Claro', es: 'Claro', en: 'Light'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(
                      tr(context, pt: 'Escuro', es: 'Oscuro', en: 'Dark'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                context,
                pt: 'Cor principal',
                es: 'Color principal',
                en: 'Main color',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accentFamilies
                  .map(
                    (family) => ChoiceChip(
                      label: Text(_accentFamilyLabel(context, family)),
                      selected: _currentAccentFamily == family,
                      onSelected: (selected) {
                        if (!selected) {
                          return;
                        }
                        _updateAccentColor(family: family);
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              tr(
                context,
                pt: 'Plano de fundo do app',
                es: 'Fondo de la app',
                en: 'App background',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_backgroundSettings.hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 130,
                  width: double.infinity,
                  child: Image.file(
                    File(_backgroundSettings.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) {
                      return ColoredBox(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            tr(
                              context,
                              pt: 'Imagem não encontrada. Escolha outra.',
                              es: 'Imagen no encontrada. Elige otra.',
                              en: 'Image not found. Pick another one.',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  tr(
                    context,
                    pt: 'Nenhuma imagem aplicada.',
                    es: 'Ninguna imagen aplicada.',
                    en: 'No image applied.',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _savingBackground ? null : _pickBackgroundImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    tr(
                      context,
                      pt: 'Escolher imagem',
                      es: 'Elegir imagen',
                      en: 'Choose image',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: !_backgroundSettings.hasImage || _savingBackground
                      ? null
                      : _clearBackgroundImage,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    tr(
                      context,
                      pt: 'Remover',
                      es: 'Eliminar',
                      en: 'Remove',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                tr(
                  context,
                  pt: 'Opacidade da imagem',
                  es: 'Opacidad de la imagen',
                  en: 'Image opacity',
                ),
              ),
              subtitle: Text('${_backgroundSettings.opacityPercent.round()}%'),
            ),
            Slider(
              value: _backgroundSettings.opacityPercent,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_backgroundSettings.opacityPercent.round()}%',
              onChanged: (value) {
                setState(() {
                  _backgroundSettings =
                      _backgroundSettings.copyWith(opacityPercent: value);
                });
              },
              onChangeEnd: (value) {
                _saveBackgroundSettings(
                  _backgroundSettings.copyWith(opacityPercent: value),
                );
              },
            ),
            ListTile(
              title: Text(
                tr(
                  context,
                  pt: 'Idioma',
                  es: 'Idioma',
                  en: 'Language',
                ),
              ),
              trailing: DropdownButton<Locale>(
                value: widget.locale.languageCode == 'pt'
                    ? const Locale('pt', 'BR')
                    : Locale(widget.locale.languageCode),
                onChanged: (value) async {
                  if (value != null) {
                    await widget.onLocaleChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                      value: Locale('pt', 'BR'), child: Text('PT-BR')),
                  DropdownMenuItem(value: Locale('en'), child: Text('EN')),
                  DropdownMenuItem(value: Locale('es'), child: Text('ES')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBaseCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Mensagem base de envio',
                  es: 'Mensaje base de envío',
                  en: 'Dispatch base message',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<String>(
              value: _selectedTemplateLanguage,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Idioma da mensagem',
                  es: 'Idioma del mensaje',
                  en: 'Message language',
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'pt', child: Text('PT-BR')),
                DropdownMenuItem(value: 'es', child: Text('ES')),
                DropdownMenuItem(value: 'en', child: Text('EN')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _onTemplateLanguageChanged(value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageTemplateController,
              minLines: 6,
              maxLines: 10,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Mensagem para WhatsApp/E-mail',
                  es: 'Mensaje para WhatsApp/Correo',
                  en: 'WhatsApp/Email message',
                ),
                helperText: tr(
                  context,
                  pt: 'Tokens: {client_name}, {gallery_link}, {access_code}, {payment_details}, {photographer_name}, {amount_due}, {payment_method}, {pix_key}, {paypal_account}, {order_id}.',
                  es: 'Tokens: {client_name}, {gallery_link}, {access_code}, {payment_details}, {photographer_name}, {amount_due}, {payment_method}, {pix_key}, {paypal_account}, {order_id}.',
                  en: 'Tokens: {client_name}, {gallery_link}, {access_code}, {payment_details}, {photographer_name}, {amount_due}, {payment_method}, {pix_key}, {paypal_account}, {order_id}.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _messageTemplateController.text =
                          _defaultTemplateForLanguage(
                              _selectedTemplateLanguage);
                    });
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: Text(
                    tr(
                      context,
                      pt: 'Restaurar padrão',
                      es: 'Restaurar predeterminado',
                      en: 'Restore default',
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saveClientMessageTemplates,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    tr(
                      context,
                      pt: 'Salvar mensagem',
                      es: 'Guardar mensaje',
                      en: 'Save message',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixIntegrationCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Integração Pix por banco',
                  es: 'Integración Pix por banco',
                  en: 'Bank Pix integration',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<PaymentProvider>(
              value: _paymentProvider,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Banco/provedor',
                  es: 'Banco/proveedor',
                  en: 'Bank/provider',
                ),
              ),
              items: PaymentProvider.values
                  .map(
                    (provider) => DropdownMenuItem(
                      value: provider,
                      child: Text(_paymentProviderLabel(context, provider)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                _onPaymentProviderChanged(value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentApiBaseUrlController,
              enabled: _paymentProvider != PaymentProvider.manual,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'URL base da API Pix',
                  es: 'URL base de la API Pix',
                  en: 'Pix API base URL',
                ),
                helperText: _paymentProvider == PaymentProvider.manual
                    ? tr(
                        context,
                        pt: 'Modo manual usa QR local sem consulta de status.',
                        es: 'Modo manual usa QR local sin consulta de estado.',
                        en: 'Manual mode uses local QR without status query.',
                      )
                    : _paymentProvider == PaymentProvider.outro
                        ? tr(
                            context,
                            pt: 'Em "Outro", informe URL e token do seu backend para criar cobrança Pix e confirmar pagamento em tempo real.',
                            es: 'En "Otro", informa URL y token de tu backend para crear el cobro Pix y confirmar el pago en tiempo real.',
                            en: 'In "Other", provide backend URL and token to create Pix charges and confirm payment in real time.',
                          )
                        : tr(
                            context,
                            pt: 'Use seu backend (não exponha credenciais bancárias no app).',
                            es: 'Usa tu backend (no expongas credenciales bancarias en la app).',
                            en: 'Use your backend (do not expose banking credentials in-app).',
                          ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentApiTokenController,
              enabled: _paymentProvider != PaymentProvider.manual,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Token da API',
                  es: 'Token de la API',
                  en: 'API token',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _savePaymentIntegration,
                child: Text(
                  tr(
                    context,
                    pt: 'Salvar integração Pix',
                    es: 'Guardar integración Pix',
                    en: 'Save Pix integration',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebAccessCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Acesso web e banco do site',
                  es: 'Acceso web y base de datos del sitio',
                  en: 'Website access and database',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _webBaseDomainController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Domínio/URL base',
                  es: 'Dominio/URL base',
                  en: 'Base domain/URL',
                ),
                helperText: tr(
                  context,
                  pt: 'Exemplo: https://seu-dominio.com',
                  es: 'Ejemplo: https://tu-dominio.com',
                  en: 'Example: https://your-domain.com',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _webPortController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Porta (opcional)',
                  es: 'Puerto (opcional)',
                  en: 'Port (optional)',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _webDbUsernameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Usuário do banco',
                  es: 'Usuario de base de datos',
                  en: 'Database username',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _webDbPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Senha do banco',
                  es: 'Contraseña de base de datos',
                  en: 'Database password',
                ),
                helperText: tr(
                  context,
                  pt: 'Essas credenciais ficam locais no app e não são enviadas ao cliente.',
                  es: 'Estas credenciales se guardan localmente y no se envían al cliente.',
                  en: 'These credentials stay local in the app and are not sent to clients.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveWebAccessSettings,
                child: Text(
                  tr(
                    context,
                    pt: 'Salvar acesso web',
                    es: 'Guardar acceso web',
                    en: 'Save web access',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSecurityCard(
    BuildContext context, {
    bool showTitle = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                tr(
                  context,
                  pt: 'Segurança do administrador',
                  es: 'Seguridad del administrador',
                  en: 'Administrator security',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              tr(
                context,
                pt: 'Usuário atual: $_adminUsername',
                es: 'Usuario actual: $_adminUsername',
                en: 'Current username: $_adminUsername',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _adminCurrentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Senha atual',
                  es: 'Contraseña actual',
                  en: 'Current password',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _adminNewPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Nova Senha',
                  es: 'Nueva contraseña',
                  en: 'New password',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _adminConfirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: tr(
                  context,
                  pt: 'Nova Senha Novamente',
                  es: 'Nueva contraseña nuevamente',
                  en: 'Repeat new password',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _savingAdminCredentials ? null : _saveAdminCredentials,
                child: Text(
                  tr(
                    context,
                    pt: _savingAdminCredentials
                        ? 'Atualizando...'
                        : 'Alterar senha do administrador',
                    es: 'Cambiar contraseña del administrador',
                    en: _savingAdminCredentials
                        ? 'Updating...'
                        : 'Change administrator password',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upsertPictureCombo([PictureComboPricing? existing]) async {
    final result = await Navigator.of(context).push<PictureComboPricing>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PictureComboEditorPage(
          existing: existing,
          nextOrdinal: _pictureCombos.length + 1,
        ),
      ),
    );

    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }

    final next = [..._pictureCombos];
    final index = next.indexWhere((combo) => combo.id == result.id);
    if (index >= 0) {
      next[index] = result;
    } else {
      next.add(result);
    }

    next.sort((a, b) => a.minimumPhotos.compareTo(b.minimumPhotos));
    await _persistPictureCombos(next);
  }

  Future<void> _removePictureCombo(String comboId) async {
    final next = _pictureCombos
        .where((combo) => combo.id != comboId)
        .toList(growable: false);
    await _persistPictureCombos(next);
  }

  Future<void> _persistPictureCombos(List<PictureComboPricing> combos) async {
    await widget.settingsStore.savePictureCombos(combos);
    final preferredComboId =
        await widget.settingsStore.loadLastSelectedPictureComboId();
    if (preferredComboId.isNotEmpty &&
        !combos.any((combo) => combo.id == preferredComboId)) {
      await widget.settingsStore.saveLastSelectedPictureComboId(
        combos.isEmpty ? '' : combos.first.id,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _pictureCombos = combos;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Combos atualizados.',
            es: 'Combos actualizados.',
            en: 'Combos updated.',
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int cents) {
    return 'R\$ ${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatAuditTimestamp(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<bool> _openAdminPasswordChangeEmail() async {
    final recipient = _photographerEmailController.text.trim();
    if (recipient.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                pt: 'Cadastre um e-mail no perfil do fotógrafo antes de alterar a senha.',
                es: 'Registra un correo en el perfil del fotógrafo antes de cambiar la contraseña.',
                en: 'Set an email in photographer profile before changing password.',
              ),
            ),
          ),
        );
      }
      return false;
    }

    final when = _formatAuditTimestamp(DateTime.now());
    final where = 'App ClickPix (${Platform.operatingSystem})';
    final subject = Uri.encodeComponent('ClickPix - alteração de senha admin');
    final body = Uri.encodeComponent(
      'A senha do administrador foi alterada.\n'
      'Data/hora: $when\n'
      'Origem: $where\n'
      'Usuário: $_adminUsername',
    );
    final uri = Uri.parse('mailto:$recipient?subject=$subject&body=$body');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Não foi possível abrir o app de e-mail para notificação.',
              es: 'No se pudo abrir la app de correo para la notificación.',
              en: 'Could not open the email app for notification.',
            ),
          ),
        ),
      );
    }
    return launched;
  }

  Future<void> _saveBusinessProfile() async {
    if (_savingBusinessProfile) {
      return;
    }
    setState(() => _savingBusinessProfile = true);
    final adminPassword = _profileAdminPasswordController.text.trim();
    if (adminPassword.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                pt: 'Informe a senha do administrador para salvar o perfil.',
                es: 'Ingresa la contraseña del administrador para guardar el perfil.',
                en: 'Enter administrator password to save the profile.',
              ),
            ),
          ),
        );
        setState(() => _savingBusinessProfile = false);
      }
      return;
    }

    final passwordIsValid = await widget.settingsStore.verifyAdminLogin(
      username: _adminUsername,
      password: adminPassword,
    );
    if (!mounted) {
      return;
    }
    if (!passwordIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Senha do administrador inválida.',
              es: 'Contraseña del administrador inválida.',
              en: 'Invalid administrator password.',
            ),
          ),
        ),
      );
      setState(() => _savingBusinessProfile = false);
      return;
    }

    await widget.settingsStore.saveBusinessProfile(
      BusinessProfileSettings(
        photographerName: _photographerNameController.text.trim().isEmpty
            ? 'Fotógrafo'
            : _photographerNameController.text.trim(),
        photographerWhatsapp: _photographerWhatsappController.text.trim(),
        photographerEmail: _photographerEmailController.text.trim(),
        photographerPixKey: _pixKeyController.text.trim(),
        photographerPaypal: _paypalController.text.trim(),
      ),
    );

    if (!mounted) {
      return;
    }
    _profileAdminPasswordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Perfil salvo com sucesso.',
            es: 'Perfil guardado con éxito.',
            en: 'Profile saved successfully.',
          ),
        ),
      ),
    );
    setState(() => _savingBusinessProfile = false);
  }

  Future<void> _savePaymentIntegration() async {
    await widget.settingsStore.savePaymentIntegrationSettings(
      PaymentIntegrationSettings(
        provider: _paymentProvider,
        apiBaseUrl: _paymentApiBaseUrlController.text.trim(),
        apiToken: _paymentApiTokenController.text.trim(),
      ),
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _paymentProvider == PaymentProvider.manual
              ? tr(
                  context,
                  pt: 'Integração Pix em modo manual salva.',
                  es: 'Integración Pix en modo manual guardada.',
                  en: 'Manual Pix mode saved.',
                )
              : tr(
                  context,
                  pt: 'Integração Pix salva. O QR pode usar API e confirmação em tempo real.',
                  es: 'Integración Pix guardada. El QR puede usar API y confirmación en tiempo real.',
                  en: 'Pix integration saved. QR can use API and real-time confirmation.',
                ),
        ),
      ),
    );
  }

  Future<void> _saveAdminCredentials() async {
    if (_savingAdminCredentials) {
      return;
    }
    setState(() => _savingAdminCredentials = true);
    final currentPassword = _adminCurrentPasswordController.text.trim();
    final newPassword = _adminNewPasswordController.text.trim();
    final confirmPassword = _adminConfirmPasswordController.text.trim();
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Preencha senha atual, nova senha e confirmação.',
              es: 'Completa contraseña actual, nueva contraseña y confirmación.',
              en: 'Fill current password, new password and confirmation.',
            ),
          ),
        ),
      );
      if (mounted) {
        setState(() => _savingAdminCredentials = false);
      }
      return;
    }

    final currentPasswordIsValid = await widget.settingsStore.verifyAdminLogin(
      username: _adminUsername,
      password: currentPassword,
    );
    if (!mounted) {
      return;
    }
    if (!currentPasswordIsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Senha atual incorreta.',
              es: 'Contraseña actual incorrecta.',
              en: 'Current password is incorrect.',
            ),
          ),
        ),
      );
      if (mounted) {
        setState(() => _savingAdminCredentials = false);
      }
      return;
    }

    if (newPassword != confirmPassword) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Nova senha e confirmação não coincidem.',
              es: 'La nueva contraseña y la confirmación no coinciden.',
              en: 'New password and confirmation do not match.',
            ),
          ),
        ),
      );
      if (mounted) {
        setState(() => _savingAdminCredentials = false);
      }
      return;
    }

    if (newPassword.length < 8) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'A nova senha deve ter ao menos 8 caracteres.',
              es: 'La nueva contraseña debe tener al menos 8 caracteres.',
              en: 'The new password must have at least 8 characters.',
            ),
          ),
        ),
      );
      if (mounted) {
        setState(() => _savingAdminCredentials = false);
      }
      return;
    }

    final emailOpened = await _openAdminPasswordChangeEmail();
    if (!mounted) {
      return;
    }
    if (!emailOpened) {
      setState(() => _savingAdminCredentials = false);
      return;
    }

    await widget.settingsStore.saveAdminCredentials(
      username: _adminUsername,
      newPassword: newPassword,
    );
    _adminCurrentPasswordController.clear();
    _adminNewPasswordController.clear();
    _adminConfirmPasswordController.clear();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Senha do administrador atualizada.',
            es: 'Contraseña del administrador actualizada.',
            en: 'Administrator password updated.',
          ),
        ),
      ),
    );
    setState(() => _savingAdminCredentials = false);
  }

  Future<void> _saveOperationalSettings() async {
    await widget.settingsStore.saveDeliverySettings(
      AppDeliverySettings(
        wifiOnly: _wifiOnly,
        accessCodeValidityDays: _accessCodeDays,
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Parâmetros operacionais salvos.',
            es: 'Parámetros operativos guardados.',
            en: 'Operational parameters saved.',
          ),
        ),
      ),
    );
  }
}

class _PictureComboEditorPage extends StatefulWidget {
  const _PictureComboEditorPage({
    required this.nextOrdinal,
    this.existing,
  });

  final PictureComboPricing? existing;
  final int nextOrdinal;

  @override
  State<_PictureComboEditorPage> createState() =>
      _PictureComboEditorPageState();
}

class _PictureComboEditorPageState extends State<_PictureComboEditorPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _minimumPhotosController;
  late final TextEditingController _unitPriceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existing?.name ?? 'Combo ${widget.nextOrdinal}',
    );
    _minimumPhotosController = TextEditingController(
      text: '${widget.existing?.minimumPhotos ?? 5}',
    );
    _unitPriceController = TextEditingController(
      text: ((widget.existing?.unitPriceCents ?? 500) / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minimumPhotosController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final minimumPhotos =
        int.tryParse(_minimumPhotosController.text.trim()) ?? 0;
    final unitPriceCents =
        _parseCurrencyCentsFromInput(_unitPriceController.text);
    if (name.isEmpty || minimumPhotos <= 0 || unitPriceCents <= 0) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final result = PictureComboPricing(
      id: widget.existing?.id ??
          'combo_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      minimumPhotos: minimumPhotos,
      unitPriceCents: unitPriceCents,
    );
    Navigator.of(context).pop(result);
  }

  int _parseCurrencyCentsFromInput(String rawText) {
    final sanitized = rawText.replaceAll(',', '.').trim();
    final value = double.tryParse(sanitized);
    if (value == null || value <= 0) {
      return 0;
    }
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? tr(
                  context,
                  pt: 'Novo combo',
                  es: 'Nuevo combo',
                  en: 'New combo',
                )
              : tr(
                  context,
                  pt: 'Editar combo',
                  es: 'Editar combo',
                  en: 'Edit combo',
                ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'Nome do combo',
                    es: 'Nombre del combo',
                    en: 'Combo name',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minimumPhotosController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'Quantidade m\u00ednima de fotos',
                    es: 'Cantidad m\u00ednima de fotos',
                    en: 'Minimum photos quantity',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _unitPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: tr(
                    context,
                    pt: 'Pre\u00e7o por foto (R\$)',
                    es: 'Precio por foto (R\$)',
                    en: 'Price per photo (R\$)',
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    tr(
                      context,
                      pt: 'Salvar altera\u00e7\u00f5es',
                      es: 'Guardar cambios',
                      en: 'Save changes',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    required this.database,
    required this.settingsStore,
    super.key,
  });

  final AppDatabase database;
  final AppSettingsStore settingsStore;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const List<_StatsWindow> _windows = [
    _StatsWindow('last_hour', Duration(hours: 1)),
    _StatsWindow('last_3_hours', Duration(hours: 3)),
    _StatsWindow('last_6_hours', Duration(hours: 6)),
    _StatsWindow('last_day', Duration(days: 1)),
    _StatsWindow('last_3_days', Duration(days: 3)),
    _StatsWindow('last_week', Duration(days: 7)),
    _StatsWindow('last_15_days', Duration(days: 15)),
    _StatsWindow('last_month', Duration(days: 30)),
    _StatsWindow('last_3_months', Duration(days: 90)),
    _StatsWindow('last_6_months', Duration(days: 180)),
    _StatsWindow('last_12_months', Duration(days: 365)),
  ];

  _StatsWindow _selectedWindow = _windows.first;
  _ComputedStats _stats = const _ComputedStats.empty();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final orders = await widget.database.select(widget.database.orders).get();
    final history = await widget.settingsStore.loadDeliveryHistory();
    final now = DateTime.now();
    final minDate = now.subtract(_selectedWindow.duration);

    final historyInWindow = history
        .where((entry) => !entry.createdAt.isBefore(minDate))
        .toList(growable: false);
    final paidHistory = historyInWindow
        .where((entry) => entry.paymentRequired)
        .toList(growable: false);
    final paypalHistory =
        paidHistory.where(_isPayPalPayment).toList(growable: false);
    final pixHistory = paidHistory
        .where((entry) => !_isPayPalPayment(entry))
        .toList(growable: false);

    final ordersInWindow = orders
        .where((order) => !order.createdAt.isBefore(minDate))
        .toList(growable: false);
    final revenueFromHistory =
        paidHistory.fold<int>(0, (acc, entry) => acc + entry.totalAmountCents);
    final revenueFromOrders = ordersInWindow.fold<int>(
        0, (acc, order) => acc + order.totalAmountCents);
    final revenue = revenueFromHistory > revenueFromOrders
        ? revenueFromHistory
        : revenueFromOrders;
    final sends = historyInWindow.length;
    final sales = paidHistory.length;
    final pixSales = pixHistory.length;
    final paypalSales = paypalHistory.length;
    final photosSold =
        paidHistory.fold<int>(0, (acc, entry) => acc + entry.photoCount);
    final expenses = paypalHistory.fold<int>(
      0,
      (acc, entry) => acc + _estimatePayPalFeeCents(entry.totalAmountCents),
    );
    final profit = revenue - expenses;
    final revenueTrend = _buildRevenueTrend(
      paidHistory: paidHistory,
      minDate: minDate,
      maxDate: now,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _stats = _ComputedStats(
        salesCount: sales,
        sendCount: sends,
        pixSalesCount: pixSales,
        paypalSalesCount: paypalSales,
        photosSoldCount: photosSold,
        revenueCents: revenue,
        expenseCents: expenses,
        profitCents: profit,
        revenueTrendCents: revenueTrend,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxBarValue = [
      _stats.revenueCents.abs(),
      _stats.expenseCents.abs(),
      _stats.profitCents.abs(),
      (_stats.photosSoldCount * 100).abs(),
    ].fold<int>(1, (acc, value) => acc > value ? acc : value);

    return Scaffold(
      appBar: AppBar(
        title: ClickPixPageTitle(
          title: tr(
            context,
            pt: 'Estatísticas',
            es: 'Estadísticas',
            en: 'Statistics',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _promptResetStatistics,
            tooltip: tr(
              context,
              pt: 'Zerar estatísticas',
              es: 'Reiniciar estadísticas',
              en: 'Reset statistics',
            ),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          IconButton(
            onPressed: _reload,
            tooltip: tr(
              context,
              pt: 'Atualizar',
              es: 'Actualizar',
              en: 'Refresh',
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<_StatsWindow>(
                      value: _selectedWindow,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: tr(
                          context,
                          pt: 'Período',
                          es: 'Período',
                          en: 'Period',
                        ),
                      ),
                      items: _windows
                          .map((window) => DropdownMenuItem(
                                value: window,
                                child: Text(_windowLabel(context, window)),
                              ))
                          .toList(growable: false),
                      onChanged: (window) {
                        if (window == null) {
                          return;
                        }
                        setState(() => _selectedWindow = window);
                        _reload();
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _promptResetStatistics,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text(
                          tr(
                            context,
                            pt: 'Zerar Estatísticas',
                            es: 'Reiniciar estadísticas',
                            en: 'Reset statistics',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StatCard(
                          title: tr(
                            context,
                            pt: 'Vendas',
                            es: 'Ventas',
                            en: 'Sales',
                          ),
                          value: '${_stats.salesCount}',
                          color: Colors.blue.shade700,
                        ),
                        _StatCard(
                          title: tr(
                            context,
                            pt: 'Vendas Pix',
                            es: 'Ventas Pix',
                            en: 'Pix sales',
                          ),
                          value: '${_stats.pixSalesCount}',
                          color: Colors.indigo.shade600,
                        ),
                        _StatCard(
                          title: tr(
                            context,
                            pt: 'Vendas PayPal',
                            es: 'Ventas PayPal',
                            en: 'PayPal sales',
                          ),
                          value: '${_stats.paypalSalesCount}',
                          color: Colors.deepOrange.shade700,
                        ),
                        _StatCard(
                          title: tr(
                            context,
                            pt: 'Fotos vendidas',
                            es: 'Fotos vendidas',
                            en: 'Photos sold',
                          ),
                          value: '${_stats.photosSoldCount}',
                          color: Colors.purple.shade700,
                        ),
                        _StatCard(
                          title: tr(
                            context,
                            pt: 'Envios',
                            es: 'Envíos',
                            en: 'Deliveries',
                          ),
                          value: '${_stats.sendCount}',
                          color: Colors.orange.shade700,
                        ),
                        _StatCard(
                          title: tr(
                            context,
                            pt: 'Gastos',
                            es: 'Gastos',
                            en: 'Expenses',
                          ),
                          value: _money(_stats.expenseCents),
                          color: Colors.red.shade700,
                        ),
                        _StatCard(
                          title: tr(
                            context,
                            pt: 'Lucro',
                            es: 'Ganancia',
                            en: 'Profit',
                          ),
                          value: _money(_stats.profitCents),
                          color: Colors.green.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                        context,
                        pt: 'Gastos consideram apenas taxas PayPal (4,79% + R\$0,60 por transação, com adicional estimado de conversão de 3,5%).',
                        es: 'Los gastos consideran solo tarifas de PayPal (4,79% + R\$0,60 por transacción, con adicional estimado de conversión del 3,5%).',
                        en: 'Expenses include only PayPal fees (4.79% + R\$0.60 per transaction, with estimated 3.5% conversion surcharge).',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr(
                        context,
                        pt: 'Gráfico de performance',
                        es: 'Gráfico de rendimiento',
                        en: 'Performance chart',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _MetricBar(
                      label: tr(
                        context,
                        pt: 'Vendas (R\$)',
                        es: 'Ventas (R\$)',
                        en: 'Sales (R\$)',
                      ),
                      value: _stats.revenueCents.toDouble(),
                      maxValue: maxBarValue.toDouble(),
                      color: Colors.blue.shade700,
                    ),
                    _MetricBar(
                      label: tr(
                        context,
                        pt: 'Gastos PayPal (R\$)',
                        es: 'Gastos PayPal (R\$)',
                        en: 'PayPal fees (R\$)',
                      ),
                      value: _stats.expenseCents.toDouble(),
                      maxValue: maxBarValue.toDouble(),
                      color: Colors.red.shade700,
                    ),
                    _MetricBar(
                      label: tr(
                        context,
                        pt: 'Lucros (R\$)',
                        es: 'Ganancias (R\$)',
                        en: 'Profit (R\$)',
                      ),
                      value: _stats.profitCents.toDouble(),
                      maxValue: maxBarValue.toDouble(),
                      color: Colors.green.shade700,
                    ),
                    _MetricBar(
                      label: tr(
                        context,
                        pt: 'Volume de fotos vendidas',
                        es: 'Volumen de fotos vendidas',
                        en: 'Photos sold volume',
                      ),
                      value: (_stats.photosSoldCount * 100).toDouble(),
                      maxValue: maxBarValue.toDouble(),
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr(
                        context,
                        pt: 'Evolução de receita',
                        es: 'Evolución de ingresos',
                        en: 'Revenue trend',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _TrendLineChart(
                            values: _stats.revenueTrendCents
                                .map((value) => value.toDouble())
                                .toList(growable: false),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  int _estimatePayPalFeeCents(int amountCents) {
    if (amountCents <= 0) {
      return 0;
    }
    final variableFee = amountCents * _paypalBusinessFeeRate;
    final conversionFee = amountCents * _paypalCurrencyConversionRate;
    return (variableFee + conversionFee + _paypalFixedFeeCents).round();
  }

  bool _isPayPalPayment(DeliveryHistoryEntry entry) {
    final normalized = entry.paymentMethodLabel.trim().toLowerCase();
    return normalized.contains('paypal');
  }

  List<int> _buildRevenueTrend({
    required List<DeliveryHistoryEntry> paidHistory,
    required DateTime minDate,
    required DateTime maxDate,
  }) {
    const bucketCount = 8;
    final sorted = [...paidHistory]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final totalSeconds = maxDate.difference(minDate).inSeconds;
    final bucketStepSeconds =
        totalSeconds <= 0 ? 1 : (totalSeconds / (bucketCount - 1));

    var runningRevenue = 0;
    var index = 0;
    final trend = <int>[];
    for (var bucket = 0; bucket < bucketCount; bucket++) {
      final bucketDate = minDate.add(
        Duration(seconds: (bucketStepSeconds * bucket).round()),
      );
      while (index < sorted.length &&
          (sorted[index].createdAt.isBefore(bucketDate) ||
              sorted[index].createdAt.isAtSameMomentAs(bucketDate))) {
        runningRevenue += sorted[index].totalAmountCents;
        index++;
      }
      trend.add(runningRevenue);
    }

    return trend;
  }

  Future<void> _promptResetStatistics() async {
    var tempWindow = _selectedWindow;
    final selectedWindow = await showDialog<_StatsWindow>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                tr(
                  context,
                  pt: 'Zerar Estatísticas',
                  es: 'Reiniciar estadísticas',
                  en: 'Reset statistics',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(
                      context,
                      pt: 'Escolha o período para limpar os dados estatísticos.',
                      es: 'Elige el período para limpiar los datos estadísticos.',
                      en: 'Choose the period to clear statistical data.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<_StatsWindow>(
                    value: tempWindow,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: tr(
                        context,
                        pt: 'Período',
                        es: 'Período',
                        en: 'Period',
                      ),
                    ),
                    items: _windows
                        .map(
                          (window) => DropdownMenuItem(
                            value: window,
                            child: Text(_windowLabel(context, window)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (next) {
                      if (next == null) {
                        return;
                      }
                      setDialogState(() => tempWindow = next);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    tr(
                      context,
                      pt: 'Cancelar',
                      es: 'Cancelar',
                      en: 'Cancel',
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(tempWindow),
                  child: Text(
                    tr(
                      context,
                      pt: 'Confirmar',
                      es: 'Confirmar',
                      en: 'Confirm',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedWindow == null) {
      return;
    }

    await _clearStatisticsForWindow(selectedWindow);
  }

  Future<void> _clearStatisticsForWindow(_StatsWindow window) async {
    final now = DateTime.now();
    final minDate = now.subtract(window.duration);

    final currentHistory = await widget.settingsStore.loadDeliveryHistory();
    final remainingHistory = currentHistory
        .where((entry) => entry.createdAt.isBefore(minDate))
        .toList(growable: false);
    await widget.settingsStore.saveDeliveryHistory(remainingHistory);

    final allOrders =
        await widget.database.select(widget.database.orders).get();
    final orderIds = allOrders
        .where((order) => !order.createdAt.isBefore(minDate))
        .map((order) => order.id)
        .toList(growable: false);
    if (orderIds.isNotEmpty) {
      await (widget.database.delete(widget.database.orderItems)
            ..where((tbl) => tbl.orderId.isIn(orderIds)))
          .go();
      await (widget.database.delete(widget.database.uploadTasks)
            ..where((tbl) => tbl.orderId.isIn(orderIds)))
          .go();
      await (widget.database.delete(widget.database.orders)
            ..where((tbl) => tbl.id.isIn(orderIds)))
          .go();
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Estatísticas limpas para ${_windowLabel(context, window)}.',
            es: 'Estadísticas limpiadas para ${_windowLabel(context, window)}.',
            en: 'Statistics cleared for ${_windowLabel(context, window)}.',
          ),
        ),
      ),
    );
    await _reload();
  }

  String _money(int cents) {
    final value = cents / 100.0;
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _windowLabel(BuildContext context, _StatsWindow window) {
    switch (window.id) {
      case 'last_hour':
        return tr(
          context,
          pt: 'Última hora',
          es: 'Última hora',
          en: 'Last hour',
        );
      case 'last_3_hours':
        return tr(
          context,
          pt: 'Últimas 3 horas',
          es: 'Últimas 3 horas',
          en: 'Last 3 hours',
        );
      case 'last_6_hours':
        return tr(
          context,
          pt: 'Últimas 6 horas',
          es: 'Últimas 6 horas',
          en: 'Last 6 hours',
        );
      case 'last_day':
        return tr(
          context,
          pt: 'Último dia',
          es: 'Último día',
          en: 'Last day',
        );
      case 'last_3_days':
        return tr(
          context,
          pt: 'Últimos 3 dias',
          es: 'Últimos 3 días',
          en: 'Last 3 days',
        );
      case 'last_week':
        return tr(
          context,
          pt: 'Última semana',
          es: 'Última semana',
          en: 'Last week',
        );
      case 'last_15_days':
        return tr(
          context,
          pt: 'Últimos 15 dias',
          es: 'Últimos 15 días',
          en: 'Last 15 days',
        );
      case 'last_month':
        return tr(
          context,
          pt: 'Último mês',
          es: 'Último mes',
          en: 'Last month',
        );
      case 'last_3_months':
        return tr(
          context,
          pt: 'Últimos 3 meses',
          es: 'Últimos 3 meses',
          en: 'Last 3 months',
        );
      case 'last_6_months':
        return tr(
          context,
          pt: 'Últimos 6 meses',
          es: 'Últimos 6 meses',
          en: 'Last 6 months',
        );
      case 'last_12_months':
        return tr(
          context,
          pt: 'Últimos 12 meses',
          es: 'Últimos 12 meses',
          en: 'Last 12 months',
        );
      default:
        return tr(
          context,
          pt: 'Período',
          es: 'Período',
          en: 'Period',
        );
    }
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 14,
              value: progress,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Center(
        child: Text(
          tr(
            context,
            pt: 'Sem dados para o período.',
            es: 'Sin datos para el período.',
            en: 'No data for this period.',
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _TrendLinePainter(
            values: values,
            color: color,
            gridColor: Theme.of(context).colorScheme.outlineVariant,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    const horizontalPadding = 14.0;
    const verticalPadding = 12.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.35)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = verticalPadding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(horizontalPadding + chartWidth, y),
        gridPaint,
      );
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = horizontalPadding +
          (values.length == 1 ? 0 : chartWidth * i / (values.length - 1));
      final normalized = (values[i] / safeMax).clamp(0.0, 1.0);
      final y = verticalPadding + chartHeight * (1 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(horizontalPadding + chartWidth, verticalPadding + chartHeight)
      ..lineTo(horizontalPadding, verticalPadding + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..color = color.withOpacity(0.16)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.values.length != values.length) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (values[i] != oldDelegate.values[i]) {
        return true;
      }
    }
    return false;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsWindow {
  const _StatsWindow(this.id, this.duration);

  final String id;
  final Duration duration;
}

class _ComputedStats {
  const _ComputedStats({
    required this.salesCount,
    required this.sendCount,
    required this.pixSalesCount,
    required this.paypalSalesCount,
    required this.photosSoldCount,
    required this.revenueCents,
    required this.expenseCents,
    required this.profitCents,
    required this.revenueTrendCents,
  });

  const _ComputedStats.empty()
      : salesCount = 0,
        sendCount = 0,
        pixSalesCount = 0,
        paypalSalesCount = 0,
        photosSoldCount = 0,
        revenueCents = 0,
        expenseCents = 0,
        profitCents = 0,
        revenueTrendCents = const <int>[0, 0, 0, 0, 0, 0, 0, 0];

  final int salesCount;
  final int sendCount;
  final int pixSalesCount;
  final int paypalSalesCount;
  final int photosSoldCount;
  final int revenueCents;
  final int expenseCents;
  final int profitCents;
  final List<int> revenueTrendCents;
}
