import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/date_formatters.dart';
import '../../utils/utilities.dart';

class PrintSettings {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? transactionType;
  final String? currency;

  PrintSettings({
    this.startDate,
    this.endDate,
    this.transactionType,
    this.currency,
  });
}

class PrintSettingsDialog extends StatefulWidget {
  final List<String> typeOptions;
  final List<String> currencyOptions;
  final String? initialType;
  final String? initialCurrency;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const PrintSettingsDialog({
    Key? key,
    required this.typeOptions,
    required this.currencyOptions,
    this.initialType,
    this.initialCurrency,
    this.initialStart,
    this.initialEnd,
  }) : super(key: key);

  @override
  _PrintSettingsDialogState createState() => _PrintSettingsDialogState();
}

class _PrintSettingsDialogState extends State<PrintSettingsDialog> {
  DateTime? _start;
  DateTime? _end;
  String? _type;
  String? _currency;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _type = widget.initialType ?? 'all';
    _currency = widget.initialCurrency ?? 'all';
  }

  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final initial = isStart ? _start ?? DateTime.now() : _end ?? DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _start = picked;
        else
          _end = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.printSettings),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(context, true),
                    child: Text(_start == null
                        ? loc.startDate
                        : formatLocalizedDate(context, _start.toString())),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(context, false),
                    child: Text(_end == null
                        ? loc.endDate
                        : formatLocalizedDate(context, _end.toString())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transaction type
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(labelText: loc.transactionType),
              items: widget.typeOptions
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(getLocalizedTxType(context, t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 16),

            // Currency
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(labelText: loc.currency),
              items: widget.currencyOptions
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c == 'all' ? loc.all : c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<PrintSettings>(null),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(PrintSettings(
              startDate: _start,
              endDate: _end,
              transactionType: _type,
              currency: _currency,
            ));
          },
          child: Text(loc.print),
        ),
      ],
    );
  }
}
