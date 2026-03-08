import 'dart:io';

import 'package:clickpix_ramon/core/i18n/app_localizations.dart';
import 'package:clickpix_ramon/core/i18n/ui_text.dart';
import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/services/photo_ingestion_service.dart';
import 'package:clickpix_ramon/data/services/upload_worker.dart';
import 'package:clickpix_ramon/presentation/recent_photos_page.dart';
import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: brightness,
    );

    final scheme = _visualSettings.highContrastEnabled
        ? (brightness == Brightness.dark
            ? const ColorScheme.highContrastDark()
            : const ColorScheme.highContrastLight())
        : baseScheme;

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
          final scaledHeight = MediaQuery.textScalerOf(context).scale(210);
          final tileHeight = scaledHeight < 210
              ? 210.0
              : scaledHeight > 280
                  ? 280.0
                  : scaledHeight;

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
                child: Text(subtitle),
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
                        pt: 'Pagamentos suportados: Pix, PayPal, cartão de crédito e cartão de débito.',
                        es: 'Pagos soportados: Pix, PayPal, tarjeta de crédito y tarjeta de débito.',
                        en: 'Supported payments: Pix, PayPal, credit card and debit card.',
                      ),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            RecentPhotosPage(
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

    setState(() => _ingesting = true);
    final result = await _ingestionService.ingestFromFolder(
      directory: Directory(folderPath),
    );
    await widget.settingsStore.savePreferredInputFolder(folderPath);
    if (!mounted) {
      return;
    }
    setState(() => _ingesting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            context,
            pt: '${result.insertedCount} foto(s) importada(s) da pasta.',
            es: '${result.insertedCount} foto(s) importada(s) desde la carpeta.',
            en: '${result.insertedCount} photo(s) imported from the folder.',
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
    setState(() => _ingesting = false);
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
  final _adminUserController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  bool _wifiOnly = false;
  int _accessCodeDays = 7;
  late AppVisualSettings _visualSettings;

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
    _adminUserController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final businessProfile = await widget.settingsStore.loadBusinessProfile();
    final credentials = await widget.settingsStore.loadAdminCredentials();
    final delivery = await widget.settingsStore.loadDeliverySettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _photographerNameController.text = businessProfile.photographerName;
      _photographerWhatsappController.text =
          businessProfile.photographerWhatsapp;
      _photographerEmailController.text = businessProfile.photographerEmail;
      _pixKeyController.text = businessProfile.photographerPixKey;
      _adminUserController.text = credentials.username;
      _wifiOnly = delivery.wifiOnly;
      _accessCodeDays = delivery.accessCodeValidityDays;
    });
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
          ],
        ),
      ),
    );
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
