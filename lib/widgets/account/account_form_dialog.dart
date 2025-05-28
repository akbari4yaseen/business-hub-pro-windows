import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/account_types.dart';
import '../../themes/app_theme.dart';

class AccountFormDialog extends StatefulWidget {
  final Map<String, dynamic>? accountData;
  final Function(Map<String, dynamic>) onSave;

  const AccountFormDialog({
    Key? key,
    this.accountData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  String _selectedAccountType = 'customer';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    final data = widget.accountData;
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';
      _selectedAccountType = data['account_type'] ?? 'customer';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final accountData = {
      'name': _nameController.text.trim(),
      'account_type': _selectedAccountType,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    try {
      await widget.onSave(accountData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.existsAccountError),
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLength = 32,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isLTR = false,
    bool autoFocus = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: isLTR ? TextDirection.ltr : null,
      autofocus: autoFocus,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final accountTypes = getAccountTypes(localizations);
    final isEdit = widget.accountData != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          // Add scroll view here
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit : Icons.person_add,
                      size: 24,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit
                          ? localizations.editAccount
                          : localizations.addAccount,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  label: localizations.accountName,
                  controller: _nameController,
                  icon: Icons.person,
                  autoFocus: true,
                  maxLength: 32,
                  validator: (value) =>
                      (value == null || value.trim().length < 2)
                          ? localizations.nameRequired
                          : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAccountType,
                  decoration: InputDecoration(
                    labelText: localizations.accountType,
                    prefixIcon: const Icon(Icons.supervisor_account_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  items: accountTypes.entries
                      .map((entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedAccountType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: localizations.phone,
                  controller: _phoneController,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  isLTR: true,
                  maxLength: 16,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final phoneRegExp = RegExp(r'^\+?\d{0,3}?\d{9,}$');
                      if (!phoneRegExp.hasMatch(value)) {
                        return localizations.invalidPhone;
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: localizations.address,
                  controller: _addressController,
                  icon: Icons.location_on,
                  maxLength: 128,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(localizations.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(localizations.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
