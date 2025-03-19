import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../constants/currencies.dart';
import '../../database/account_db.dart';
import '../../database/journal_db.dart';

/// A custom [TextInputFormatter] that formats numeric input with thousand separators.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###.##");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final numericString = newValue.text.replaceAll(',', '');
    final value = double.tryParse(numericString);
    if (value == null) return oldValue;
    final newText = _formatter.format(value);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AddJournalScreen extends StatefulWidget {
  const AddJournalScreen({Key? key}) : super(key: key);

  @override
  State<AddJournalScreen> createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _faDateController = TextEditingController();

  List<Map<String, dynamic>> _accounts = [];
  int? _selectedAccount;
  int? _selectedTrack;
  String _transactionType = 'credit';
  String _currency = 'AFN';

  // Track option state: 'treasure', 'noTreasure', or 'track'
  String _selectedTrackOption = 'noTreasure';
  final int _treasureTrackId = 1;
  final int _noTreasureTrackId = 2;
  String _customTrackName = "Track";

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    // Set default track to treasure.
    _selectedTrack = _noTreasureTrackId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize Persian date field with the current Jalali date and time.
    final currentJalali = Jalali.now();
    final currentTime = TimeOfDay.now();

    _selectedDate = currentJalali.toDateTime();
    _faDateController.text =
        '${currentJalali.formatCompactDate()} ${currentTime.format(context)}';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _faDateController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    final accounts = await AccountDBHelper().getOptionAccounts();
    if (mounted) {
      setState(() => _accounts = accounts);
    }
  }

// Combined date and time picker method.
  Future<void> _pickDateTime() async {
    final locale = Localizations.localeOf(context);
    DateTime? date;

    // Pick the date based on the current locale.
    if (locale.languageCode == 'fa') {
      Jalali? picked = await showPersianDatePicker(
        context: context,
        initialDate: Jalali.now(),
        firstDate: Jalali(1390, 1),
        lastDate: Jalali.fromDateTime(
          DateTime.now().add(const Duration(days: 2)),
        ),
        initialEntryMode: PersianDatePickerEntryMode.calendarOnly,
        initialDatePickerMode: PersianDatePickerMode.day,
      );
      if (picked == null) return; // User canceled the picker.
      date = picked.toDateTime();
    } else {
      date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(Duration(days: 2)),
      );
      if (date == null) return; // User canceled the picker.
    }

    // Pick the time with default set to current time.
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(), // Ensure current time is set
    );
    if (time == null) return; // User canceled the picker.

    // Combine the picked date and time.
    final combinedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Update the field and selected date.
    setState(() {
      _selectedDate = combinedDateTime;
      if (locale.languageCode == 'fa') {
        final jalali = Jalali.fromDateTime(combinedDateTime);
        _faDateController.text =
            '${jalali.formatCompactDate()} ${time.format(context)}';
      } else {
        _faDateController.text =
            DateFormat.yMd().add_jm().format(combinedDateTime);
      }
    });
  }

  Future<void> _saveJournal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      await JournalDBHelper().insertJournal(
        date: _selectedDate,
        accountId: _selectedAccount!,
        trackId: _selectedTrack!,
        amount: amount,
        currency: _currency,
        transactionType: _transactionType.toLowerCase(),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving journal: $e")),
      );
    }
  }

  /// Returns a reusable Autocomplete field for account selection.
  Widget _buildAutocompleteField({
    required String label,
    required Function(int) onSelected,
  }) {
    final localizations = AppLocalizations.of(context)!;
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return _accounts;
        return _accounts.where((item) => (item['name'] as String)
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (item) => item['name'] as String,
      onSelected: (item) => onSelected(item['id'] as int),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label),
          validator: (value) => (value == null || value.isEmpty)
              ? localizations.pleaseSelectAccount
              : null,
        );
      },
    );
  }

  /// Helper method to generate toggle button styles.
  ButtonStyle _toggleButtonStyle(bool isSelected,
      {Color? unselectedTextColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
      foregroundColor:
          isSelected ? Colors.white : (unselectedTextColor ?? Colors.grey[900]),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildTransactionTypeToggle() {
    final localizations = AppLocalizations.of(context)!;
    const types = ['credit', 'debit'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        SizedBox(
          width: double.infinity,
          child: Row(
            children: types.map((type) {
              bool isSelected = _transactionType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _transactionType = type),
                    style: _toggleButtonStyle(isSelected),
                    child: Text(
                      "${type == "credit" ? localizations.credit : localizations.debit}",
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountWithCurrency() {
    final localizations = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: localizations.amount,
        suffixIcon: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _currency,
            items: currencies
                .map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _currency = value!),
          ),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsSeparatorInputFormatter()],
      validator: (value) => (value == null || value.isEmpty)
          ? localizations.amountRequired
          : null,
      maxLength: 9,
    );
  }

  Future<void> _showTrackDialog() async {
    final localizations = AppLocalizations.of(context)!;
    Map<String, dynamic>? dialogSelectedAccount;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations.selectTrack),
          content: SizedBox(
            width: double.maxFinite,
            child: Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return _accounts;
                return _accounts.where((account) => (account['name'] as String)
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              displayStringForOption: (option) => option['name'] as String,
              onSelected: (option) {
                dialogSelectedAccount = option;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: localizations.typeToSearchTrack,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogSelectedAccount != null) {
                  setState(() {
                    _selectedTrack = dialogSelectedAccount!['id'] as int;
                    _selectedTrackOption = 'track';
                    _customTrackName = dialogSelectedAccount!['name'] as String;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.pleaseSelectTrack)),
                  );
                }
              },
              child: Text(localizations.confirm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackSegmentedControl() {
    final localizations = AppLocalizations.of(context)!;
    // Helper function for creating a single-line label.
    Widget buildSegmentLabel(String text) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SegmentedButton<String>(
          segments: <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'treasure',
              label: buildSegmentLabel(localizations.treasure),
            ),
            ButtonSegment<String>(
              value: 'noTreasure',
              label: buildSegmentLabel(localizations.noTreasure),
            ),
            ButtonSegment<String>(
              value: 'track',
              label: buildSegmentLabel(
                _selectedTrackOption == 'track'
                    ? _customTrackName
                    : localizations.track,
              ),
            ),
          ],
          selected: <String>{_selectedTrackOption},
          onSelectionChanged: (Set<String> newSelection) async {
            final selected = newSelection.first;
            if (selected == 'track') {
              // Trigger the dialog for a custom track.
              await _showTrackDialog();
              setState(() => _selectedTrackOption = 'track');
            } else {
              setState(() {
                _selectedTrackOption = selected;
                _selectedTrack = (selected == 'treasure')
                    ? _treasureTrackId
                    : _noTreasureTrackId;
              });
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.addJournal),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(localizations.save),
            onPressed: _saveJournal,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Persian date picker field
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _faDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: _pickDateTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildAutocompleteField(
                    label: localizations.selectAccount,
                    onSelected: (id) => setState(() => _selectedAccount = id),
                  ),
                  const SizedBox(height: 10),
                  _buildAmountWithCurrency(),
                  const SizedBox(height: 10),
                  _buildTransactionTypeToggle(),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: localizations.description,
                    ),
                    maxLength: 256,
                    minLines: 2,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 10),
                  _buildTrackSegmentedControl(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
