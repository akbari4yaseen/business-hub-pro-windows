import 'package:BusinessHub/database/journal_db.dart';
import 'package:flutter/material.dart';
import '../../database/account_db.dart';

class EditJournalScreen extends StatefulWidget {
  final Map<String, dynamic> journal;
  const EditJournalScreen({super.key, required this.journal});

  @override
  _EditJournalScreenState createState() => _EditJournalScreenState();
}

class _EditJournalScreenState extends State<EditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late String _transactionType;
  late String _currency;
  late DateTime _selectedDate;
  int? _selectedAccount;
  int? _selectedTrack;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _tracks = [];

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.journal['description']);
    _amountController =
        TextEditingController(text: widget.journal['amount'].toString());
    _transactionType = widget.journal['transaction_type'];
    _currency = widget.journal['currency'];
    _selectedAccount = widget.journal['account_id'];
    _selectedTrack = widget.journal['track_id'];
    _selectedDate = DateTime.parse(widget.journal['date']);

    _loadAccountsAndTracks();
  }

  Future<void> _loadAccountsAndTracks() async {
    List<Map<String, dynamic>> accounts =
        await AccountDBHelper().getActiveAccounts();
    List<Map<String, dynamic>> tracks =
        await AccountDBHelper().getActiveAccounts();

    setState(() {
      _accounts = accounts;
      _tracks = tracks;
    });
  }

  Future<void> _updateJournal() async {
    if (_formKey.currentState!.validate() &&
        _selectedAccount != null &&
        _selectedTrack != null) {
      await JournalDBHelper().updateJournal(
        id: widget.journal['id'],
        date: _selectedDate,
        accountId: _selectedAccount!,
        trackId: _selectedTrack!,
        amount: double.parse(_amountController.text),
        currency: _currency,
        transactionType: _transactionType.toLowerCase(),
        description: _descriptionController.text,
      );

      Navigator.pop(context, true); // Go back and refresh the list
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ویرایش ژورنال"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateJournal,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(labelText: "تاریخ"),
                controller: TextEditingController(
                    text: "${_selectedDate.toLocal()}".split(' ')[0]),
                onTap: () => _pickDate(context),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedAccount,
                decoration: const InputDecoration(labelText: "حساب"),
                items: _accounts
                    .map((account) => DropdownMenuItem<int>(
                          value: account['id'],
                          child: Text(account['name']),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedAccount = value);
                },
                validator: (value) =>
                    value == null ? "لطفاً یک حساب را انتخاب کنید" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedTrack,
                decoration: const InputDecoration(labelText: "پیگیری"),
                items: _tracks
                    .map((track) => DropdownMenuItem<int>(
                          value: track['id'],
                          child: Text(track['name']),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedTrack = value);
                },
                validator: (value) =>
                    value == null ? "لطفاً یک پیگیری را انتخاب کنید" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "توضیحات"),
                validator: (value) =>
                    value!.isEmpty ? "توضیحات نمی‌تواند خالی باشد" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "مقدار"),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? "مقدار را وارد کنید" : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: const InputDecoration(labelText: "نوع معامله"),
                items: ["Credit", "Debit"]
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _transactionType = value!);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: "ارز"),
                items: ["USD", "EUR", "PKR"]
                    .map((currency) => DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _currency = value!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
