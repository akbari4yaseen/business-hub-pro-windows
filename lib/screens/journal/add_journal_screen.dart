import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class AddJournalScreen extends StatefulWidget {
  const AddJournalScreen({super.key});

  @override
  _AddJournalScreenState createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  List<Map<String, dynamic>> _accounts = [];
  int? _selectedAccount;
  int? _selectedTrack;
  String _transactionType = 'Credit';
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await DatabaseHelper().getAllAccounts();
    setState(() => _accounts = accounts);
  }

  Future<void> _saveJournal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccount == null || _selectedTrack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both account and track")),
      );
      return;
    }

    try {
      await DatabaseHelper().insertJournal(
        date: DateTime.now(),
        accountId: _selectedAccount!,
        trackId: _selectedTrack!,
        amount: double.parse(_amountController.text),
        currency: _currency,
        transactionType: _transactionType.toLowerCase(),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving journal: $e")),
      );
    }
  }

  Widget _buildAutocompleteField({
    required String label,
    required Function(int) onSelected,
  }) {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return _accounts;
        return _accounts.where((item) => item['name']
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (item) => item['name'],
      onSelected: (item) => onSelected(item['id']),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label),
          validator: (value) => value!.isEmpty ? "Please select $label" : null,
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((item) =>
              DropdownMenuItem(value: item, child: Text(item.toString())))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Journal")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildAutocompleteField(
              label: "Select Account",
              onSelected: (id) => setState(() => _selectedAccount = id),
            ),
            const SizedBox(height: 10),
            _buildAutocompleteField(
              label: "Select Track",
              onSelected: (id) => setState(() => _selectedTrack = id),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value!.isEmpty ? "Amount is required" : null,
            ),
            const SizedBox(height: 10),
            _buildDropdown<String>(
              label: "Transaction Type",
              value: _transactionType,
              items: ["Credit", "Debit"],
              onChanged: (value) => setState(() => _transactionType = value!),
            ),
            const SizedBox(height: 10),
            _buildDropdown<String>(
              label: "Currency",
              value: _currency,
              items: ["USD", "EUR", "PKR"],
              onChanged: (value) => setState(() => _currency = value!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveJournal,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
