import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    bool success = await DatabaseHelper().updateUserPassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _errorMessage = success ? null : "Current password is incorrect";
    });
    if (success) Navigator.pop(context);
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggleVisibility,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "This field is required";
        if (label == "New Password" && value.length < 6)
          return "Must be at least 6 characters";
        if (label == "Confirm Password" && value != _newPasswordController.text)
          return "Passwords do not match";
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _buildPasswordField(
                  "Current Password",
                  _currentPasswordController,
                  _showCurrentPassword,
                  () => setState(
                      () => _showCurrentPassword = !_showCurrentPassword)),
              const SizedBox(height: 16),
              _buildPasswordField(
                  "New Password",
                  _newPasswordController,
                  _showNewPassword,
                  () => setState(() => _showNewPassword = !_showNewPassword)),
              const SizedBox(height: 16),
              _buildPasswordField(
                  "Confirm Password",
                  _confirmPasswordController,
                  _showConfirmPassword,
                  () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updatePassword,
                child: const Text("Change Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
