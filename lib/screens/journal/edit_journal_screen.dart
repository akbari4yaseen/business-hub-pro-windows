import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../constants/currencies.dart';
import '../../database/account_db.dart';
import '../../database/journal_db.dart';
import '../../utils/utilities.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../widgets/journal_form_widgets.dart';
import '../../utils/number_input_formatter.dart';

class EditJournalScreen extends StatefulWidget {
  final Map<String, dynamic> journal;
  const EditJournalScreen({Key? key, required this.journal}) : super(key: key);

  @override
  State<EditJournalScreen> createState() => _EditJournalScreenState();
}

class _EditJournalScreenState extends State<EditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _dateCtrl;

  late String _accountName;
  List<Map<String, dynamic>> _accounts = [];
  int? _selectedAccount;
  int? _selectedTrack;
  String _customTrackName = "Track";

  late String _transactionType;
  late String _currency;
  late String _trackOption;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final j = widget.journal;
    _descCtrl = TextEditingController(text: j['description'] ?? '');
    _amountCtrl = TextEditingController(
        text: NumberFormat('#,###.##').format(j['amount']));
    _dateCtrl = TextEditingController();
    _accountName = j['account_name'] as String;
    _transactionType = j['transaction_type'];
    _currency = j['currency'];
    _selectedAccount = j['account_id'];
    _selectedTrack = j['track_id'];
    _selectedDate = DateTime.parse(j['date']);
    _trackOption = 'track';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dateCtrl.text =
          dFormatter.formatLocalizedDateTime(context, _selectedDate.toString());
      final incomingTrackName = j['track_name'] as String;
      if (incomingTrackName == 'treasure') {
        _trackOption = 'treasure';
        _selectedTrack = 1;
      } else if (incomingTrackName == 'noTreasure') {
        _trackOption = 'noTreasure';
        _selectedTrack = 2;
      }
    });

    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await AccountDBHelper().getOptionAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      if (_selectedTrack != null) {
        final match = accounts.firstWhere((a) => a['id'] == _selectedTrack,
            orElse: () => {});
        if (match.isNotEmpty) {
          _customTrackName =
              getLocalizedSystemAccountName(context, match['name']);
        }
      }
    });
  }

  Future<void> _pickDateTime() async {
    final result = await pickLocalizedDateTime(
      context: context,
      initialDate: _selectedDate,
    );
    if (result != null) _setDate(result);
  }

  void _setDate(DateTime dt) {
    _selectedDate = dt;
    _dateCtrl.text = formatLocalizedDateTime(context, dt);
  }

  Future<void> _saveJournal() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
    try {
      await JournalDBHelper().updateJournal(
        id: widget.journal['id'],
        date: _selectedDate,
        accountId: _selectedAccount!,
        trackId: _selectedTrack!,
        amount: amount,
        currency: _currency,
        transactionType: _transactionType.toLowerCase(),
        description: _descCtrl.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating journal: $e')),
      );
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.editJournal),
        actions: [IconButton(onPressed: _saveJournal, icon: Icon(Icons.save))],
      ),
      backgroundColor: themeProvider.appBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                decoration:
                    InputDecoration(prefixIcon: Icon(Icons.calendar_today)),
                onTap: _pickDateTime,
              ),
              SizedBox(height: 16),
              AccountField(
                label: loc.selectAccount,
                accounts: _accounts,
                initialValue: TextEditingValue(
                  text: getLocalizedSystemAccountName(context, _accountName),
                ),
                onSelected: (id) => setState(() {
                  _selectedAccount = id;
                  final acc = _accounts.firstWhere((a) => a['id'] == id);
                  _accountName = acc['name'] as String;
                }),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: loc.amount,
                  suffixIcon: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currency,
                      items: currencies
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [NumberInputFormatter()],
                maxLength: 9,
                validator: (v) =>
                    v?.isEmpty == true ? loc.amountRequired : null,
              ),
              SizedBox(height: 16),
              JournalToggleButtons(
                options: ['credit', 'debit'],
                selected: _transactionType,
                onChanged: (val) => setState(() => _transactionType = val),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: loc.description),
                maxLength: 256,
                minLines: 2,
                maxLines: 5,
              ),
              SizedBox(height: 16),
              TrackSelector(
                accounts: _accounts,
                selectedOption: _trackOption,
                customTrackName: _customTrackName,
                onOptionChanged: (opt, id) {
                  setState(() {
                    _trackOption = opt;
                    if (opt == 'track' && id != null) {
                      _selectedTrack = id;
                      final acc = _accounts.firstWhere((a) => a['id'] == id);
                      _customTrackName =
                          getLocalizedSystemAccountName(context, acc['name']);
                    } else if (opt == 'treasure') {
                      _selectedTrack = 1;
                      _customTrackName = loc.treasure;
                    } else if (opt == 'noTreasure') {
                      _selectedTrack = 2;
                      _customTrackName = loc.noTreasure;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
