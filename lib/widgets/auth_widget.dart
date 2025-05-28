import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/auth_helper.dart';
import '../../providers/settings_provider.dart';

class AuthWidget extends StatefulWidget {
  final String actionReason;
  final VoidCallback onAuthenticated;

  const AuthWidget({
    Key? key,
    required this.actionReason,
    required this.onAuthenticated,
  }) : super(key: key);

  @override
  State<AuthWidget> createState() => _AuthWidgetState();
}

class _AuthWidgetState extends State<AuthWidget> {
  final AuthHelper _authHelper = AuthHelper();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    });

    // Delay the biometric auth trigger to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      if (settingsProvider.useFingerprint) {
        _authenticateBiometric();
      }
    });
  }

  Future<void> _authenticateBiometric() async {
    if (_isAuthenticating) return;
    final success = await _authHelper.authenticate(widget.actionReason);

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(
          () => _errorMessage = AppLocalizations.of(context)!.biometricFailed);
    }

    setState(() => _isAuthenticating = false);
  }

  Future<void> _authenticateWithPassword() async {
    if (_isAuthenticating) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isAuthenticating = true);
    final success = await _authHelper.authenticateWithPassword(
      widget.actionReason,
      _passwordController.text.trim(),
    );
    setState(() => _isAuthenticating = false);

    if (success) {
      widget.onAuthenticated();
    } else {
      setState(
          () => _errorMessage = AppLocalizations.of(context)!.invalidPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400, // Adjust this value as needed for desktop
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_outline, size: 40, color: colors.primary),
                const SizedBox(height: 12),
                Text(loc.authTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(widget.actionReason,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _authenticateWithPassword(),
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: loc.passwordLabel,
                      errorText: _errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        gapPadding: 8.0,
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? loc.enterPasswordError
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isAuthenticating
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(loc.cancel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAuthenticating
                            ? null
                            : _authenticateWithPassword,
                        child: _isAuthenticating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(loc.confirm),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (settingsProvider.useFingerprint) const SizedBox(height: 16),
                if (settingsProvider.useFingerprint)
                  Center(
                    child: TextButton.icon(
                      onPressed:
                          _isAuthenticating ? null : _authenticateBiometric,
                      icon: Icon(
                        Icons.fingerprint,
                        color: _isAuthenticating
                            ? colors.onSurface.withValues(alpha: 0.4)
                            : colors.primary,
                      ),
                      label: Text(
                        loc.useFingerprint,
                        style: TextStyle(
                          color: _isAuthenticating
                              ? colors.onSurface.withValues(alpha: 0.4)
                              : colors.primary,
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

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
