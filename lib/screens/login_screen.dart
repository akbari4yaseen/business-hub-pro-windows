import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  late AnimationController _logoController;
  late AnimationController _cardSlideController;
  late AnimationController _shakeController;

  late Animation<double> _logoFade;
  late Animation<Offset> _cardSlide;
  late Animation<Offset> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardSlideController, curve: Curves.easeOut),
    );

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(-0.02, 0)),
          weight: 1),
      TweenSequenceItem(
          tween:
              Tween(begin: const Offset(-0.02, 0), end: const Offset(0.02, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.02, 0), end: Offset.zero),
          weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400),
        () => _cardSlideController.forward());
  }

  Future<void> _login() async {
    final loc = AppLocalizations.of(context)!;
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() => _errorMessage = loc.enterPassword);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isValidUser = await DatabaseHelper().validateUser(password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!isValidUser) {
      setState(() => _errorMessage = loc.wrongPassword);
      _shakeController.forward(from: 0);
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
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
                  fontWeight: FontWeight.bold,
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
                onPressed: () {},
                child: Text(
                  loc.forgotPassword,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(AppLocalizations loc, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: IconButton(
                    key: ValueKey(_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        loc.loginButton,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
