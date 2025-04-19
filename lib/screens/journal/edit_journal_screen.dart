import '../../providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../constants/currencies.dart';
import '../../database/account_db.dart';
import '../../database/journal_db.dart';
import '../../utils/utilities.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###.##");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(',', '');
    if (text.isEmpty) return newValue;
    final value = double.tryParse(text);
    if (value == null) return oldValue;
    final newText = _formatter.format(value);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

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

  late String _accountName; // <-- holds current account name
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
    // Controllers
    _descCtrl = TextEditingController(text: j['description'] ?? '');
    _amountCtrl = TextEditingController(
      text: NumberFormat('#,###.##').format(j['amount']),
    );
    _dateCtrl = TextEditingController();

    // Remember the original account name so we can display it initially:
    _accountName = j['account_name'] as String;

    // Initial values
    _transactionType = j['transaction_type'];
    _currency = j['currency'];
    _selectedAccount = j['account_id'];
    _selectedTrack = j['track_id'];
    _selectedDate = DateTime.parse(j['date']);
    _trackOption = 'track';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set date display
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'fa') {
        final jd = Jalali.fromDateTime(_selectedDate);
        final tm = TimeOfDay.fromDateTime(_selectedDate);
        _dateCtrl.text = '${jd.formatCompactDate()} ${tm.format(context)}';
      } else {
        _dateCtrl.text = DateFormat.yMd().add_jm().format(_selectedDate);
      }

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

      // Only update _customTrackName if we actually found a matching track:
      if (_selectedTrack != null) {
        Map<String, dynamic>? match;
        for (var a in accounts) {
          if (a['id'] == _selectedTrack) {
            match = a;
            break;
          }
        }
        if (match != null) {
          _customTrackName =
              getLocalizedSystemAccountName(context, match['name']);
        }
        // else: leave _customTrackName as-is (e.g. from initState)
      }

      // Initialize date text (this was already correct)
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'fa') {
        final jd = Jalali.fromDateTime(_selectedDate);
        final tm = TimeOfDay.fromDateTime(_selectedDate);
        _dateCtrl.text = '${jd.formatCompactDate()} ${tm.format(context)}';
      } else {
        _dateCtrl.text = DateFormat.yMd().add_jm().format(_selectedDate);
      }
    });
  }

  Future<void> _pickDateTime() async {
    final locale = Localizations.localeOf(context);
    DateTime? date;

    if (locale.languageCode == 'fa') {
      final j = await showPersianDatePicker(
        context: context,
        initialDate: Jalali.fromDateTime(_selectedDate),
        firstDate: Jalali(1390, 1),
        lastDate: Jalali.fromDateTime(DateTime.now().add(Duration(days: 2))),
      );
      if (j == null) return;
      date = j.toDateTime();
    } else {
      date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(Duration(days: 2)),
      );
      if (date == null) return;
    }

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (t == null) return;

    final dt = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    setState(() => _selectedDate = dt);

    if (locale.languageCode == 'fa') {
      final jd = Jalali.fromDateTime(dt);
      final tm = TimeOfDay.fromDateTime(dt);
      _dateCtrl.text = '${jd.formatCompactDate()} ${tm.format(context)}';
    } else {
      _dateCtrl.text = DateFormat.yMd().add_jm().format(dt);
    }
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
        actions: [
          IconButton(onPressed: _saveJournal, icon: Icon(Icons.save)),
        ],
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
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDateTime,
              ),
              SizedBox(height: 16),
              _AccountField(
                label: loc.selectAccount,
                accounts: _accounts,
                // initialize the text field with the existing account name:
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
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                maxLength: 9,
                validator: (v) =>
                    v?.isEmpty == true ? loc.amountRequired : null,
              ),
              SizedBox(height: 16),
              _ToggleButtons(
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
              _TrackSelector(
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
                      _selectedTrack = 1; // system treasure account ID
                      _customTrackName = loc.treasure;
                    } else if (opt == 'noTreasure') {
                      _selectedTrack = 2; // system no-treasure account ID
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

class _AccountField extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> accounts;
  final ValueChanged<int> onSelected;
  final TextEditingValue? initialValue; // <-- new

  const _AccountField({
    required this.label,
    required this.accounts,
    required this.onSelected,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Autocomplete<Map<String, dynamic>>(
      initialValue: initialValue, // <-- prefill with existing account
      optionsBuilder: (txt) => txt.text.isEmpty
          ? accounts
          : accounts.where((a) => (a['name'] as String)
              .toLowerCase()
              .contains(txt.text.toLowerCase())),
      displayStringForOption: (a) =>
          getLocalizedSystemAccountName(context, a['name']),
      onSelected: (a) => onSelected(a['id'] as int),
      fieldViewBuilder: (ctx, ctl, fn, sub) => TextFormField(
        controller: ctl,
        focusNode: fn,
        decoration: InputDecoration(labelText: label),
        validator: (v) => v?.isEmpty == true ? loc.pleaseSelectAccount : null,
      ),
    );
  }
}

// _ToggleButtons and _TrackSelector unchanged
class _ToggleButtons extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ToggleButtons({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Row(
      children: options.map((opt) {
        final isSel = selected == opt.toLowerCase();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSel ? Colors.blue : Colors.grey[300],
                foregroundColor: isSel ? Colors.white : Colors.black,
              ),
              onPressed: () => onChanged(opt.toLowerCase()),
              child: Text(
                "${opt == "credit" ? localizations.credit : localizations.debit}",
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TrackSelector extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final String selectedOption;
  final String customTrackName;
  final void Function(String option, int? id) onOptionChanged;

  const _TrackSelector({
    required this.accounts,
    required this.selectedOption,
    required this.customTrackName,
    required this.onOptionChanged,
  });

  // Helper function for creating a single-line label.
  Widget buildSegmentLabel(String text) => FittedBox(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
            value: 'treasure', label: buildSegmentLabel(loc.treasure)),
        ButtonSegment(
            value: 'noTreasure', label: buildSegmentLabel(loc.noTreasure)),
        ButtonSegment(
            value: 'track', label: buildSegmentLabel(customTrackName)),
      ],
      selected: {selectedOption},
      onSelectionChanged: (s) async {
        final opt = s.first;
        if (opt == 'track') {
          final selected = await showDialog<int>(
            context: context,
            builder: (_) => _TrackDialog(accounts: accounts),
          );
          onOptionChanged('track', selected);
        } else {
          onOptionChanged(opt, opt == 'treasure' ? 1 : 2);
        }
      },
    );
  }
}

class _TrackDialog extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  const _TrackDialog({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Map<String, dynamic>? sel;
    return AlertDialog(
      title: Text(loc.selectTrack),
      content: Autocomplete<Map<String, dynamic>>(
        optionsBuilder: (txt) => txt.text.isEmpty
            ? accounts
            : accounts.where((a) =>
                getLocalizedSystemAccountName(context, a['name'])
                    .toLowerCase()
                    .contains(txt.text.toLowerCase())),
        displayStringForOption: (a) =>
            getLocalizedSystemAccountName(context, a['name']),
        onSelected: (a) => sel = a,
        fieldViewBuilder: (ctx, ctl, fn, sub) => TextField(
          controller: ctl,
          focusNode: fn,
          decoration: InputDecoration(hintText: loc.typeToSearchTrack),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (sel != null)
              Navigator.pop(context, sel!['id'] as int);
            else
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(loc.pleaseSelectTrack)));
          },
          child: Text(loc.confirm),
        ),
      ],
    );
  }
}
