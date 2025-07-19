import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../database/database_helper.dart';
import '../database/user_dao.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  // Biometric authentication
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  late final AnimationController _logoController;
  late final AnimationController _cardSlideController;
  late final AnimationController _shakeController;

  late final Animation<double> _logoFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<Offset> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 400),
        () => _cardSlideController.forward());

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardSlideController,
      curve: Curves.easeOut,
    ));

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _initBiometrics();

    // Delay the biometric auth trigger to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      if (settingsProvider.useFingerprint) {
        _authenticateWithBiometrics();
      }
    });
  }

  Future<void> _initBiometrics() async {
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = [];
    try {
      canCheckBiometrics = await _auth.canCheckBiometrics;
      availableBiometrics = await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      // Handle error if needed
    }
    if (!mounted) return;
    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _login() async {
    final loc = AppLocalizations.of(context)!;
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() => _errorMessage = loc.enterPassword);
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // get DAO
    final db = await DatabaseHelper().database;
    final dao = UserDao(db);
    final isValid = await dao.validate(password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!isValid) {
      setState(() => _errorMessage = loc.wrongPassword);
      _shakeController.forward(from: 0);
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    final loc = AppLocalizations.of(context)!;

    try {
      authenticated = await _auth.authenticate(
        localizedReason: loc.biometricReason,
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _errorMessage = loc.biometricError;
      });
      return;
    }
    if (!mounted) return;
    if (authenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _cardSlideController.dispose();
    _shakeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? Colors.white
          : theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: Image.asset("assets/images/app_logo.png", height: 100),
              ),
              const SizedBox(height: 24),
              Text(
                loc.loginHeader,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: "VazirBold",
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              SlideTransition(
                position: _cardSlide,
                child: SlideTransition(
                  position: _shakeAnimation,
                  child: _buildLoginCard(loc, theme),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to forgot-password flow
                },
                child: Text(loc.forgotPassword),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(AppLocalizations loc, ThemeData theme) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    final isDesktop = Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 400 : double.infinity,
        ),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: loc.passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        key: ValueKey(_obscurePassword),
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    errorText: _errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(loc.loginButton,
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
                if (_canCheckBiometrics && settingsProvider.useFingerprint)
                  const SizedBox(height: 16),
                if (_canCheckBiometrics && settingsProvider.useFingerprint)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      label: Text(loc.useFingerprint),
                      onPressed:
                          _isLoading ? null : _authenticateWithBiometrics,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
