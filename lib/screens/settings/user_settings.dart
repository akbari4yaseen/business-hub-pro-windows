// lib/screens/user_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../database/user_dao.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  bool _saving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Use UserDao instead of direct DatabaseHelper call
    final db = await DatabaseHelper().database;
    final dao = UserDao(db);
    final success = await dao.updatePassword(
      _currentPasswordController.text.trim(),
      _newPasswordController.text.trim(),
    );

    final loc = AppLocalizations.of(context)!;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(success ? loc.passwordUpdated : loc.incorrectCurrentPassword),
        backgroundColor: success ? null : Colors.red,
      ),
    );

    setState(() => _saving = false);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  String? _validatePassword(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.fieldRequired;
    }
    if (value.length < 6) {
      return loc.passwordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value != _newPasswordController.text) {
      return loc.passwordsDoNotMatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.changePassword),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc.changePassword,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.enterYourCurrentAndNewPassword, // add to ARB if you don't have it
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: AutofillGroup(
                            child: Column(
                              children: [
                                PasswordField(
                                  label: loc.currentPassword,
                                  controller: _currentPasswordController,
                                  obscure: !_showCurrent,
                                  focusNode: _currentFocus,
                                  nextFocus: _newFocus,
                                  onToggle: () => setState(
                                      () => _showCurrent = !_showCurrent),
                                ),
                                const SizedBox(height: 20),
                                PasswordField(
                                  label: loc.newPassword,
                                  controller: _newPasswordController,
                                  obscure: !_showNew,
                                  focusNode: _newFocus,
                                  nextFocus: _confirmFocus,
                                  onToggle: () =>
                                      setState(() => _showNew = !_showNew),
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 20),
                                PasswordField(
                                  label: loc.confirmPassword,
                                  controller: _confirmPasswordController,
                                  obscure: !_showConfirm,
                                  focusNode: _confirmFocus,
                                  onToggle: () => setState(
                                      () => _showConfirm = !_showConfirm),
                                  validator: _validateConfirmPassword,
                                  onSubmitted: (_) => _updatePassword(),
                                  textInputAction: TextInputAction.done,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Actions row (desktop-like)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.icon(
                            onPressed: _saving ? null : _updatePassword,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(loc.changePassword),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              textStyle: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;

  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
    this.focusNode,
    this.nextFocus,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofillHints: const [AutofillHints.password],
      obscureText: obscure,
      validator: validator ??
          (value) => value == null || value.isEmpty ? loc.fieldRequired : null,
      textInputAction: textInputAction,
      onFieldSubmitted: (v) {
        if (onSubmitted != null) {
          onSubmitted!(v);
        } else {
          nextFocus?.requestFocus();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: theme.colorScheme.surface,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: Tooltip(
          message: obscure
              ? loc.showPassword
              : loc.hidePassword, // add keys if needed
          child: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggle,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
