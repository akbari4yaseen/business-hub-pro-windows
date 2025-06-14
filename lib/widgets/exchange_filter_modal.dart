import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/date_time_picker_helper.dart';
import '../utils/date_formatters.dart' as dFormatter;

class ExchangeFilterModal extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final Function(DateTime? fromDate, DateTime? toDate) onApplyFilters;

  const ExchangeFilterModal({
    Key? key,
    this.initialFromDate,
    this.initialToDate,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _ExchangeFilterModalState createState() => _ExchangeFilterModalState();
}

class _ExchangeFilterModalState extends State<ExchangeFilterModal> {
  late DateTime? _tmpFromDate;
  late DateTime? _tmpToDate;

  @override
  void initState() {
    super.initState();
    _tmpFromDate = widget.initialFromDate;
    _tmpToDate = widget.initialToDate;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.filters),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // From Date Picker
            InkWell(
              onTap: () async {
                final picked = await pickLocalizedDate(
                  context: context,
                  initialDate: _tmpFromDate ?? DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _tmpFromDate = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: loc.startDate,
                  border: const OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tmpFromDate != null
                          ? dFormatter.formatLocalizedDate(
                              context, _tmpFromDate.toString())
                          : loc.selectDate,
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // To Date Picker
            InkWell(
              onTap: () async {
                final picked = await pickLocalizedDate(
                  context: context,
                  initialDate: _tmpToDate ?? DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _tmpToDate = picked);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: loc.endDate,
                  border: const OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tmpToDate != null
                          ? dFormatter.formatLocalizedDate(
                              context, _tmpToDate.toString())
                          : loc.selectDate,
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _tmpFromDate = null;
              _tmpToDate = null;
            });
          },
          child: Text(loc.reset),
        ),
        TextButton(
          onPressed: () {
            widget.onApplyFilters(_tmpFromDate, _tmpToDate);
            Navigator.of(context).pop();
          },
          child: Text(loc.applyFilters),
        ),
      ],
    );
  }
} 