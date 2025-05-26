import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../database/account_db.dart';
import '../../database/journal_db.dart';
import '../../providers/settings_provider.dart';
import '../../utils/utilities.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../widgets/journal/journal_form_widgets.dart';
import '../../constants/currencies.dart';
import '../../utils/number_input_formatter.dart';

class AddJournalScreen extends StatefulWidget {
  /// If non-null, pre-select this account in the dropdown.
  final int? initialAccountId;
  final String? initialAccountName;

  const AddJournalScreen({
    Key? key,
    this.initialAccountId,
    this.initialAccountName,
  }) : super(key: key);

  @override
  State<AddJournalScreen> createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _dateCtrl;

  List<Map<String, dynamic>> _accounts = [];
  int? _selectedAccount;
  late String _accountName;

  int? _selectedTrack;
  String _customTrackName = "Track";

  late String _transactionType;
  late String _currency;
  late String _trackOption;

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _dateCtrl = TextEditingController();

    _selectedAccount = widget.initialAccountId;
    _accountName = widget.initialAccountName ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _transactionType = settingsProvider.defaultTransaction;
        _currency = settingsProvider.defaultCurrency;
        _trackOption = settingsProvider.defaultTrackOption;
        _selectedTrack = settingsProvider.defaultTrack;
        _customTrackName = AppLocalizations.of(context)!.track;
      });
    });
    _loadAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.read<SettingsProvider>();
    _transactionType = settings.defaultTransaction;
    _currency = settings.defaultCurrency;
    _trackOption = settings.defaultTrackOption;
    _selectedTrack = settings.defaultTrack;
    _setDate(DateTime.now());
  }

  void _setDate(DateTime dt) {
    _selectedDate = dt;
    _dateCtrl.text = dFormatter.formatLocalizedDateTime(context, dt.toString());
  }

  Future<void> _loadAccounts() async {
    final accounts = await AccountDBHelper().getOptionAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
    });
  }

  Future<void> _pickDateTime() async {
    final result = await pickLocalizedDateTime(
      context: context,
      initialDate: _selectedDate,
    );
    if (result != null) _setDate(result);
  }

  Future<void> _saveJournal() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));

    try {
      await JournalDBHelper().insertJournal(
        date: _selectedDate,
        accountId: _selectedAccount!, // ← stays the same
        trackId: _selectedTrack!,
        amount: amount,
        currency: _currency,
        transactionType: _transactionType.toLowerCase(),
        description: _descCtrl.text,
      );

      if (!mounted) return;

      setState(() {
        // clear the two text fields
        _descCtrl.clear();
        _amountCtrl.clear();
        // reset date to “now”
        _setDate(DateTime.now());

        //  reset your toggles/dropdowns/tracks:
        final settings = context.read<SettingsProvider>();
        _transactionType = settings.defaultTransaction;
        _currency = settings.defaultCurrency;
        _trackOption = settings.defaultTrackOption;
        _selectedTrack = settings.defaultTrack;
        _customTrackName = AppLocalizations.of(context)!.track;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.journalSaved)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.errorSavingJournal}: $e')),
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
        title: Text(loc.addJournal),
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
                maxLength: 15,
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
                maxLength: 512,
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
