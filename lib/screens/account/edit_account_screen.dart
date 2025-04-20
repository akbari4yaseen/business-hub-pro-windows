import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../database/account_db.dart';

class EditAccountScreen extends StatefulWidget {
  final Map<String, dynamic> accountData;
  const EditAccountScreen({Key? key, required this.accountData})
      : super(key: key);

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  String _selectedAccountType = 'customer';
  final AccountDBHelper _dbHelper = AccountDBHelper();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    final data = widget.accountData;
    _nameController.text = data['name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _addressController.text = data['address'] ?? '';
    _selectedAccountType = data['account_type'] ?? 'customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Build the updated account object including the id.
    final updatedAccount = {
      'name': _nameController.text.trim(),
      'account_type': _selectedAccountType,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    try {
      await _dbHelper.updateAccount(widget.accountData['id'], updatedAccount);
      if (mounted) Navigator.pop(context, updatedAccount);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.existsAccountError),
        ),
      );
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
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final accountTypes = {
      'customer': localizations.customer,
      'supplier': localizations.supplier,
      'exchanger': localizations.exchanger,
      'bank': localizations.bank,
      'income': localizations.income,
      'expense': localizations.expense,
    };
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.addAccount),
        actions: [
          IconButton(onPressed: _updateAccount, icon: Icon(Icons.save)),
        ],
      ),
      backgroundColor: themeProvider.appBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                label: localizations.accountName,
                controller: _nameController,
                icon: Icons.person,
                autoFocus: true,
                maxLength: 32,
                validator: (value) => (value == null || value.trim().length < 2)
                    ? localizations.nameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAccountType,
                decoration: InputDecoration(
                  labelText: localizations.accountType,
                  prefixIcon: const Icon(Icons.supervisor_account_outlined),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              _buildTextField(
                label: localizations.address,
                controller: _addressController,
                icon: Icons.location_on,
                maxLength: 128,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
