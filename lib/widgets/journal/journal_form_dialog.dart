import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../database/account_db.dart';
import '../../utils/utilities.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../constants/currencies.dart';
import '../../utils/number_input_formatter.dart';
import 'journal_form_widgets.dart';

class JournalFormDialog extends StatefulWidget {
  final Map<String, dynamic>? journal;
  final int? initialAccountId;
  final String? initialAccountName;
  final Function(Map<String, dynamic>) onSave;

  const JournalFormDialog({
    Key? key,
    this.journal,
    this.initialAccountId,
    this.initialAccountName,
    required this.onSave,
  }) : super(key: key);

  @override
  State<JournalFormDialog> createState() => _JournalFormDialogState();
}

class _JournalFormDialogState extends State<JournalFormDialog> {
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

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _dateCtrl = TextEditingController();

    final j = widget.journal;
    if (j != null) {
      _descCtrl.text = j['description'] ?? '';
      _amountCtrl.text = NumberFormat('#,###.##').format(j['amount']);
      _accountName = j['account_name'] as String;
      _transactionType = j['transaction_type'];
      _currency = j['currency'];
      _selectedAccount = j['account_id'];
      _selectedTrack = j['track_id'];
      _selectedDate = DateTime.parse(j['date']);
      _trackOption = 'track';

      final incomingTrackName = j['track_name'] as String;
      if (incomingTrackName == 'treasure') {
        _trackOption = 'treasure';
        _selectedTrack = 1;
      } else if (incomingTrackName == 'noTreasure') {
        _trackOption = 'noTreasure';
        _selectedTrack = 2;
      }
    } else {
      _selectedAccount = widget.initialAccountId;
      _accountName = widget.initialAccountName ?? '';
      _selectedDate = DateTime.now();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      if (j == null) {
        setState(() {
          _transactionType = settingsProvider.defaultTransaction;
          _currency = settingsProvider.defaultCurrency;
          _trackOption = settingsProvider.defaultTrackOption;
          _selectedTrack = settingsProvider.defaultTrack;
          _customTrackName = AppLocalizations.of(context)!.track;
        });
      }
      _dateCtrl.text =
          dFormatter.formatLocalizedDateTime(context, _selectedDate.toString());
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
    setState(() {
      _selectedDate = dt;
      _dateCtrl.text =
          dFormatter.formatLocalizedDateTime(context, dt.toString());
    });
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
    final journalData = {
      'date': _selectedDate,
      'account_id': _selectedAccount!,
      'track_id': _selectedTrack!,
      'amount': amount,
      'currency': _currency,
      'transaction_type': _transactionType.toLowerCase(),
      'description': _descCtrl.text,
    };

    try {
      await widget.onSave(journalData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.errorSavingJournal)),
        );
      }
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Widget _buildFormFields(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _dateCtrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: loc.date,
            prefixIcon: const Icon(Icons.calendar_today),
            border: const OutlineInputBorder(),
          ),
          onTap: _pickDateTime,
        ),
        const SizedBox(height: 16),
        AccountField(
          label: loc.selectAccount,
          accounts: _accounts,
          initialValue: TextEditingValue(
            text: getLocalizedSystemAccountName(context, _accountName),
          ),
          onSelected: (id) {
            setState(() {
              _selectedAccount = id;
              final acc = _accounts.firstWhere((a) => a['id'] == id);
              _accountName = acc['name'] as String;
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountCtrl,
          decoration: InputDecoration(
            labelText: loc.amount,
            border: const OutlineInputBorder(),
            suffixIcon: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currency,
                items: currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [NumberInputFormatter()],
          maxLength: 15,
          validator: (v) => v?.isEmpty == true ? loc.amountRequired : null,
        ),
        const SizedBox(height: 16),
        JournalToggleButtons(
          options: ['credit', 'debit'],
          selected: _transactionType,
          onChanged: (val) => setState(() => _transactionType = val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descCtrl,
          decoration: InputDecoration(
            labelText: loc.description,
            border: const OutlineInputBorder(),
          ),
          maxLength: 512,
          minLines: 2,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isEdit = widget.journal != null;

    return Dialog(
      backgroundColor: themeProvider.appBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: 500,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          isEdit ? Icons.edit : Icons.add_circle,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEdit ? loc.editJournal : loc.addJournal,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // All your form fields here
                    _buildFormFields(context, loc),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(loc.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _handleSave,
                          child: Text(loc.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
