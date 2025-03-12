import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddAccountScreen extends StatefulWidget {
  final Map<String, dynamic>? accountData;

  AddAccountScreen({this.accountData});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  String _selectedAccountType = "customer"; // Default to key values

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    if (widget.accountData != null) {
      _nameController.text = widget.accountData!["name"] ?? "";
      _phoneController.text = widget.accountData!["phone"] ?? "";
      _addressController.text = widget.accountData!["address"] ?? "";
      _selectedAccountType = widget.accountData!["account_type"] ?? "customer";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final localizations = AppLocalizations.of(context)!;
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String address = _addressController.text.trim();

    if (name.isEmpty) {
      _showSnackBar(localizations.nameRequired);
      return;
    }

    final newAccount = {
      'name': name,
      'account_type':
          _selectedAccountType, // Store the key, not localized value
      'phone': phone,
      'address': address,
    };

    if (widget.accountData == null) {
      await _dbHelper.insertAccount(newAccount);
    } else {
      await _dbHelper.updateAccount(widget.accountData!["id"], newAccount);
    }

    Navigator.pop(context, newAccount);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isLTR = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      textDirection: isLTR ? TextDirection.ltr : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final Map<String, String> _accountTypes = {
      "customer": localizations.customer,
      "supplier": localizations.supplier,
      "exchanger": localizations.exchanger,
    };

    return Scaffold(
      appBar: AppBar(title: Text(localizations.addAccount)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
                label: localizations.accountName, controller: _nameController),
            DropdownButtonFormField<String>(
              value: _selectedAccountType,
              decoration: InputDecoration(labelText: localizations.accountType),
              items: _accountTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedAccountType = value!),
            ),
            _buildTextField(
                label: localizations.phone,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                isLTR: true),
            _buildTextField(
                label: localizations.address, controller: _addressController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAccount,
              child: Text(localizations.saveAccount),
            ),
          ],
        ),
      ),
    );
  }
}
