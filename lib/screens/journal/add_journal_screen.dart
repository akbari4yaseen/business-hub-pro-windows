import '../../database/journal_db.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/currencies.dart';

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
  String _currency = 'AFN';
  DateTime _selectedDate = DateTime.now(); // Default to today

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await DatabaseHelper().getOptionAccounts();
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
      await JournalDBHelper().insertJournal(
        date: _selectedDate, // Use selected date
        accountId: _selectedAccount!,
        trackId: _selectedTrack!,
        amount: double.parse(_amountController.text.replaceAll(',', '')),
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

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
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

  Widget _buildTransactionTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Transaction Type"),
        const SizedBox(height: 5),
        ToggleButtons(
          borderRadius: BorderRadius.circular(10),
          isSelected: [
            _transactionType == "Credit",
            _transactionType == "Debit"
          ],
          onPressed: (index) {
            setState(() => _transactionType = index == 0 ? "Credit" : "Debit");
          },
          children: const [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Credit")),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Debit")),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Journal"),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(localizations.save),
            onPressed: _saveJournal,
            style: ButtonStyle(
                padding: WidgetStateProperty.all(
                    EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0))),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? "Amount is required" : null,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final formatter = NumberFormat("#,###");
                        final parsedValue =
                            double.tryParse(value.replaceAll(',', ''));
                        if (parsedValue != null) {
                          _amountController.value = TextEditingValue(
                            text: formatter.format(parsedValue),
                            selection: TextSelection.collapsed(
                                offset: formatter.format(parsedValue).length),
                          );
                        }
                      }
                    },
                    
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 100, // Set a smaller width for currency
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    items: currencies.map((currency) {
                      return DropdownMenuItem(
                          value: currency, child: Text(currency));
                    }).toList(),
                    onChanged: (value) => setState(() => _currency = value!),
                    decoration: const InputDecoration(labelText: "Currency"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTransactionTypeToggle(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLength: 256,
                  maxLines: 16,
                  minLines: 2,
                ))
              ],
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Select Date"),
              subtitle: Text(DateFormat.yMd().format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}
