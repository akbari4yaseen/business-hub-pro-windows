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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  String _selectedAccountType = "customer";

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
    if (!_formKey.currentState!.validate()) return;

    final newAccount = {
      'name': _nameController.text.trim(),
      'account_type': _selectedAccountType,
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    if (widget.accountData == null) {
      await _dbHelper.insertAccount(newAccount);
    } else {
      await _dbHelper.updateAccount(widget.accountData!["id"], newAccount);
    }

    Navigator.pop(context, newAccount);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    IconData? icon,
    TextInputType? keyboardType,
    bool isLTR = false,
    bool autoFocus = false,
    required int maxLength,
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
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(10),
        // ),
      ),
      validator: validator,
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
      appBar: AppBar(
        title: Text(localizations.addAccount),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(localizations.save),
            onPressed: _saveAccount,
            style: ButtonStyle(
                padding: WidgetStateProperty.all(
                    EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0))),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      backgroundColor: Colors.white70,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: localizations.accountName,
                        controller: _nameController,
                        icon: Icons.person,
                        autoFocus: true,
                        maxLength: 32,
                        validator: (value) =>
                            value!.isEmpty ? localizations.nameRequired : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedAccountType,
                        decoration: InputDecoration(
                          labelText: localizations.accountType,
                        ),
                        items: _accountTypes.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedAccountType = value!),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: localizations.phone,
                        controller: _phoneController,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        isLTR: true,
                        maxLength: 13,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                          label: localizations.address,
                          controller: _addressController,
                          icon: Icons.location_on,
                          maxLength: 128),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
