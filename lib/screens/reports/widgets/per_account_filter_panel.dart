import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../database/reports_db.dart';
import '../../../database/database_helper.dart';
import '../../../utils/date_time_picker_helper.dart';
import '../../../utils/date_formatters.dart' as dFormatter;
import '../../../themes/app_theme.dart';

class PerAccountFilterPanel extends StatefulWidget {
  final ReportsDBHelper db;
  final NumberFormat formatter;
  const PerAccountFilterPanel(
      {Key? key, required this.db, required this.formatter})
      : super(key: key);

  @override
  State<PerAccountFilterPanel> createState() => _PerAccountFilterPanelState();
}

class _PerAccountFilterPanelState extends State<PerAccountFilterPanel> {
  int? _accountId;
  String? _currency;
  DateTime _start = DateTime.now().subtract(const Duration(days: 7));
  DateTime _end = DateTime.now();
  double _credit = 0;
  double _debit = 0;
  bool _loading = false;
  List<Map<String, dynamic>> _accounts = [];
  List<String> _currencies = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _loadCurrencies();
  }

  Future<void> _loadAccounts() async {
    try {
      final rows = await widget.db.getActiveAccounts();
      setState(() => _accounts = rows);
    } catch (_) {}
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await DatabaseHelper().getDistinctCurrencies();

      setState(() {
        _currencies = currencies;
        if (_currency != null && !_currencies.contains(_currency)) {
          _currency = null; // reset if no longer valid
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading currencies: $e')),
      );
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await pickLocalizedDate(
        context: context, initialDate: isStart ? _start : _end);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          if (_start.isAfter(_end)) _end = _start;
        } else {
          _end = picked;
          if (_end.isBefore(_start)) _start = _end;
        }
      });
    }
  }

  Future<void> _run() async {
    final loc = AppLocalizations.of(context)!;
    if (_accountId == null || _currency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseSelectAllFilters)),
      );
      return;
    }
    setState(() {
      _loading = true;
      _credit = 0;
      _debit = 0;
    });
    try {
      final rows = await widget.db.getCreditDebitBalancesForAccount(
        accountId: _accountId!,
        currency: _currency!,
        startDate: DateTime(_start.year, _start.month, _start.day),
        endDate: DateTime(_end.year, _end.month, _end.day, 23, 59, 59),
      );
      double c = 0, d = 0;
      for (final r in rows) {
        if (r['transaction_type'] == 'credit')
          c = (r['total'] as num).toDouble();
        if (r['transaction_type'] == 'debit')
          d = (r['total'] as num).toDouble();
      }
      setState(() {
        _credit = c;
        _debit = d;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.accountReports,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (a) => a['name'] as String,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _accounts;
                }
                return _accounts.where((a) => (a['name'] as String)
                    .toLowerCase()
                    .contains(textEditingValue.text.toLowerCase()));
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(labelText: loc.account),
                );
              },
              onSelected: (selected) {
                setState(() {
                  _accountId = selected['id'] as int;
                });
              },
            )),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: loc.currency),
                value: _currency,
                items: _currencies.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _currency = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                    dFormatter.formatLocalizedDate(context, _start.toString())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.calendar_today),
                label: Text(
                    dFormatter.formatLocalizedDate(context, _end.toString())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _run,
            icon: const Icon(Icons.playlist_add_check),
            label: Text(loc.generateReport),
          ),
        ),
        const SizedBox(height: 8),
        if (_loading) const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.green),
            title: Text(loc.totalCredit),
            trailing: Text(
              '\u200E${widget.formatter.format(_credit)} ${_currency ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.red),
            title: Text(loc.totalDebit),
            trailing: Text(
              '\u200E${widget.formatter.format(_debit)} ${_currency ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.balance, color: AppTheme.primaryColor),
            title: Text(loc.balance),
            trailing: Text(
              '\u200E${widget.formatter.format(_credit - _debit)} ${_currency ?? ''}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _credit >= _debit ? Colors.green : Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
