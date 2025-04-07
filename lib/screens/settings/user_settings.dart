import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await DatabaseHelper().updateUserPassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    final localizations = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? localizations.passwordUpdated
            : localizations.incorrectCurrentPassword),
        backgroundColor: success ? null : Colors.red,
      ),
    );

    if (success) Navigator.pop(context);
  }

  String? _validatePassword(String? value) {
    final localizations = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) return localizations.fieldRequired;
    if (value.length < 6) return localizations.passwordTooShort;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final localizations = AppLocalizations.of(context)!;
    if (value != _newPasswordController.text)
      return localizations.passwordsDoNotMatch;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.changePassword)),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    PasswordField(
                      label: localizations.currentPassword,
                      controller: _currentPasswordController,
                      obscure: !_showCurrent,
                      onToggle: () =>
                          setState(() => _showCurrent = !_showCurrent),
                    ),
                    const SizedBox(height: 20),
                    PasswordField(
                      label: localizations.newPassword,
                      controller: _newPasswordController,
                      obscure: !_showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),
                    PasswordField(
                      label: localizations.confirmPassword,
                      controller: _confirmPasswordController,
                      obscure: !_showConfirm,
                      onToggle: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      validator: _validateConfirmPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _updatePassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(localizations.changePassword),
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

  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: const OutlineInputBorder(),
      ),
      validator: validator ??
          (value) => value == null || value.isEmpty
              ? localizations.fieldRequired
              : null,
    );
  }
}
