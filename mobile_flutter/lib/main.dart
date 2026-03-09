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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  'gray_light': Color(0xFFD1D5DB),
  'gray_mid': Color(0xFF6B7280),
  'gray_dark': Color(0xFF374151),
  'red_light': Color(0xFFFCA5A5),
  'red_mid': Color(0xFFDC2626),
  'red_dark': Color(0xFF7F1D1D),
  'brown_light': Color(0xFFD2B48C),
  'brown_mid': Color(0xFF8B5E3C),
  'brown_dark': Color(0xFF4E342E),
};

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
      themeMode: _visualSettings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      builder: (context, child) {
        final safeChild = child ?? const SizedBox.shrink();
        if (!_visualSettings.solarLargeFontEnabled) {
          return safeChild;
        }
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: const TextScaler.linear(1.15),
          ),
          child: safeChild,
        );
      },
      home: AdminGatePage(
        settingsStore: widget.appSettingsStore,
        database: widget.database,
        locale: _locale,
        visualSettings: _visualSettings,
        onLocaleChanged: _onLocaleChanged,
        onVisualSettingsChanged: _onVisualSettingsChanged,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accentColorFromKey(_visualSettings.accentColorKey),
      brightness: brightness,
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
      ),
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
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    super.key,
  });

  final AppSettingsStore settingsStore;
  final AppDatabase database;
  final Locale locale;
  final AppVisualSettings visualSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings)
      onVisualSettingsChanged;

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
      onLocaleChanged: widget.onLocaleChanged,
      onVisualSettingsChanged: widget.onVisualSettingsChanged,
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
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    required this.onLogout,
    super.key,
  });

  final AppSettingsStore settingsStore;
  final AppDatabase database;
  final Locale locale;
  final AppVisualSettings visualSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings)
      onVisualSettingsChanged;
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
                          onLocaleChanged: onLocaleChanged,
                          onVisualSettingsChanged: onVisualSettingsChanged,
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
  List<DeliveryHistoryEntry> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            RecentPhotosPage(
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
}

class AppConfigurationPage extends StatefulWidget {
  const AppConfigurationPage({
    required this.settingsStore,
    required this.locale,
    required this.visualSettings,
    required this.onLocaleChanged,
    required this.onVisualSettingsChanged,
    super.key,
  });

  final AppSettingsStore settingsStore;
  final Locale locale;
  final AppVisualSettings visualSettings;
  final Future<void> Function(Locale locale) onLocaleChanged;
  final Future<void> Function(AppVisualSettings settings)
      onVisualSettingsChanged;

  @override
  State<AppConfigurationPage> createState() => _AppConfigurationPageState();
}

class _AppConfigurationPageState extends State<AppConfigurationPage> {
  final _photographerNameController = TextEditingController();
  final _photographerWhatsappController = TextEditingController();
  final _photographerEmailController = TextEditingController();
  final _pixKeyController = TextEditingController();
  final _paypalController = TextEditingController();
  final _paymentApiBaseUrlController = TextEditingController();
  final _paymentApiTokenController = TextEditingController();
  final _adminUserController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _wifiOnly = false;
  int _accessCodeDays = 7;
  List<PictureComboPricing> _pictureCombos = const [];
  PaymentProvider _paymentProvider = PaymentProvider.manual;
  late AppVisualSettings _visualSettings;
  String get _currentAccentFamily =>
      _accentFamilyFromKey(_visualSettings.accentColorKey);

  @override
  void initState() {
    super.initState();
    _visualSettings = widget.visualSettings;
    _loadSettings();
  }

  @override
  void dispose() {
    _photographerNameController.dispose();
    _photographerWhatsappController.dispose();
    _photographerEmailController.dispose();
    _pixKeyController.dispose();
    _paypalController.dispose();
    _paymentApiBaseUrlController.dispose();
    _paymentApiTokenController.dispose();
    _adminUserController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final businessProfile = await widget.settingsStore.loadBusinessProfile();
    final credentials = await widget.settingsStore.loadAdminCredentials();
    final delivery = await widget.settingsStore.loadDeliverySettings();
    final pictureCombos = await widget.settingsStore.loadPictureCombos();
    final paymentIntegration =
        await widget.settingsStore.loadPaymentIntegrationSettings();
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
      _adminUserController.text = credentials.username;
      _wifiOnly = delivery.wifiOnly;
      _accessCodeDays = delivery.accessCodeValidityDays;
      _pictureCombos = pictureCombos;
      _paymentProvider = paymentIntegration.provider;
      _paymentApiBaseUrlController.text = paymentIntegration.apiBaseUrl;
      _paymentApiTokenController.text = paymentIntegration.apiToken;
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
    final currentSuggestion = _paymentProviderDefaultApiBaseUrls[_paymentProvider];
    final nextSuggestion = _paymentProviderDefaultApiBaseUrls[provider];
    if (currentUrl.isEmpty ||
        (currentSuggestion != null && currentUrl == currentSuggestion)) {
      _paymentApiBaseUrlController.text = nextSuggestion ?? '';
    }
    setState(() => _paymentProvider = provider);
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(
                          context,
                          pt: 'Perfil do fotógrafo',
                          es: 'Perfil del fotógrafo',
                          en: 'Photographer profile',
                        ),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
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
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveBusinessProfile,
                        child: Text(
                          tr(
                            context,
                            pt: 'Salvar perfil',
                            es: 'Guardar perfil',
                            en: 'Save profile',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(
                          context,
                          pt: 'Integração Pix por banco',
                          es: 'Integración Pix por banco',
                          en: 'Bank Pix integration',
                        ),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
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
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(
                          context,
                          pt: 'Segurança do administrador',
                          es: 'Seguridad del administrador',
                          en: 'Administrator security',
                        ),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _adminUserController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: tr(
                          context,
                          pt: 'Usuário admin',
                          es: 'Usuario admin',
                          en: 'Admin username',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _adminPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: tr(
                          context,
                          pt: 'Nova senha admin',
                          es: 'Nueva contraseña admin',
                          en: 'New admin password',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveAdminCredentials,
                        child: Text(
                          tr(
                            context,
                            pt: 'Atualizar credenciais',
                            es: 'Actualizar credenciales',
                            en: 'Update credentials',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(
                          context,
                          pt: 'Acessibilidade e exibição',
                          es: 'Accesibilidad y visualización',
                          en: 'Accessibility and display',
                        ),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
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
                        final next = _visualSettings.copyWith(
                            highContrastEnabled: value);
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
                        final next = _visualSettings.copyWith(
                            solarLargeFontEnabled: value);
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
                          final next =
                              _visualSettings.copyWith(themeMode: value);
                          setState(() => _visualSettings = next);
                          await widget.onVisualSettingsChanged(next);
                        },
                        items: [
                          DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text(tr(
                                context,
                                pt: 'Sistema',
                                es: 'Sistema',
                                en: 'System',
                              ))),
                          DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text(tr(
                                context,
                                pt: 'Claro',
                                es: 'Claro',
                                en: 'Light',
                              ))),
                          DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text(tr(
                                context,
                                pt: 'Escuro',
                                es: 'Oscuro',
                                en: 'Dark',
                              ))),
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
                          DropdownMenuItem(
                              value: Locale('en'), child: Text('EN')),
                          DropdownMenuItem(
                              value: Locale('es'), child: Text('ES')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        tr(
                          context,
                          pt: 'Parâmetros operacionais',
                          es: 'Parámetros operativos',
                          en: 'Operational parameters',
                        ),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
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
                      subtitle: Text(tr(
                        context,
                        pt: '$_accessCodeDays dia(s)',
                        es: '$_accessCodeDays día(s)',
                        en: '$_accessCodeDays day(s)',
                      )),
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
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      tr(
                        context,
                        pt: 'Configure regras de preco por quantidade. Exemplo: a partir de 5 fotos, cada foto custa R\$ 5,00.',
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

  Future<void> _saveBusinessProfile() async {
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
    final username = _adminUserController.text.trim();
    final newPassword = _adminPasswordController.text;
    if (username.isEmpty || newPassword.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              pt: 'Informe usuário e nova senha para atualizar.',
              es: 'Ingresa usuario y nueva contraseña para actualizar.',
              en: 'Enter username and new password to update.',
            ),
          ),
        ),
      );
      return;
    }

    await widget.settingsStore.saveAdminCredentials(
      username: username,
      newPassword: newPassword,
    );
    _adminPasswordController.clear();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: 'Credenciais de administrador atualizadas.',
            es: 'Credenciales de administrador actualizadas.',
            en: 'Administrator credentials updated.',
          ),
        ),
      ),
    );
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
      id: widget.existing?.id ?? 'combo_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      minimumPhotos: minimumPhotos,
      unitPriceCents: unitPriceCents,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    });
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
        .where((entry) => entry.createdAt.isAfter(minDate))
        .toList(growable: false);
    final paidHistory = historyInWindow
        .where((entry) => entry.paymentRequired)
        .toList(growable: false);

    final ordersInWindow = orders
        .where((order) => order.createdAt.isAfter(minDate))
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
    final expenses =
        (revenue * 0.25).round() + ((sends - sales) * 100).clamp(0, 1000000000);
    final profit = revenue - expenses;

    if (!mounted) {
      return;
    }
    setState(() {
      _stats = _ComputedStats(
        salesCount: sales,
        sendCount: sends,
        revenueCents: revenue,
        expenseCents: expenses,
        profitCents: profit,
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
      (_stats.sendCount * 100).abs(),
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
            : Column(
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
                            child: Text(_windowLabel(context, window))))
                        .toList(growable: false),
                    onChanged: (window) {
                      if (window == null) {
                        return;
                      }
                      setState(() => _selectedWindow = window);
                      _reload();
                    },
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
                  const SizedBox(height: 16),
                  Text(
                      tr(
                        context,
                        pt: 'Gráfico de performance',
                        es: 'Gráfico de rendimiento',
                        en: 'Performance chart',
                      ),
                      style: Theme.of(context).textTheme.titleLarge),
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
                      pt: 'Gastos (R\$)',
                      es: 'Gastos (R\$)',
                      en: 'Expenses (R\$)',
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
                      pt: 'Volume de envios',
                      es: 'Volumen de envíos',
                      en: 'Delivery volume',
                    ),
                    value: (_stats.sendCount * 100).toDouble(),
                    maxValue: maxBarValue.toDouble(),
                    color: Colors.orange.shade700,
                  ),
                ],
              ),
      ),
    );
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
    required this.revenueCents,
    required this.expenseCents,
    required this.profitCents,
  });

  const _ComputedStats.empty()
      : salesCount = 0,
        sendCount = 0,
        revenueCents = 0,
        expenseCents = 0,
        profitCents = 0;

  final int salesCount;
  final int sendCount;
  final int revenueCents;
  final int expenseCents;
  final int profitCents;
}


