import 'package:flutter/material.dart';
import '../../database/account_db.dart';

class EditAccountScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const EditAccountScreen({super.key, required this.account});

  @override
  _EditAccountScreenState createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String _accountType = 'Customer';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account['name']);
    _phoneController = TextEditingController(text: widget.account['phone']);
    _addressController = TextEditingController(text: widget.account['address']);
    _accountType = widget.account['account_type'];
  }

Future<void> _updateAccount() async {
  if (_formKey.currentState!.validate()) {
    final updatedAccount = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'account_type': _accountType,
    };

    // Update account in SQLite database
    await AccountDBHelper().updateAccount(widget.account['id'], updatedAccount);

    // Close screen and return updated data
    Navigator.pop(context, updatedAccount);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویرایش حساب')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'نام'),
                validator: (value) =>
                    value!.isEmpty ? 'نام نمی‌تواند خالی باشد' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'شماره تلفن'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'آدرس'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: const InputDecoration(labelText: 'نوع حساب'),
                items: ['Customer', 'System']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _accountType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateAccount,
                child: const Text('ذخیره تغییرات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
