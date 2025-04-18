import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class JournalFilterBottomSheet extends StatelessWidget {
  final String? selectedType;
  final String? selectedCurrency;
  final DateTime? selectedDate;
  final List<String> typeOptions;
  final List<String> currencyOptions;
  final void Function({String? type, String? currency, DateTime? date}) onApply;
  final VoidCallback onReset;
  final void Function({String? type, String? currency, DateTime? date}) onChanged;

  const JournalFilterBottomSheet({
    Key? key,
    this.selectedType,
    this.selectedCurrency,
    this.selectedDate,
    required this.typeOptions,
    required this.currencyOptions,
    required this.onApply,
    required this.onReset,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.95,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.filter, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    // Transaction Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedType ?? 'all',
                      items: typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      decoration: InputDecoration(labelText: loc.transactionType),
                      onChanged: (val) => onChanged(type: val),
                    ),
                    const SizedBox(height: 12),
                    // Currency Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCurrency ?? 'all',
                      items: currencyOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      decoration: InputDecoration(labelText: loc.currency),
                      onChanged: (val) => onChanged(currency: val),
                    ),
                    const SizedBox(height: 12),
                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) onChanged(date: picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: loc.date),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedDate != null
                                ? '${selectedDate!.year}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}'
                                : loc.selectDate),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: onReset,
                          child: Text(loc.reset),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => onApply(
                            type: selectedType,
                            currency: selectedCurrency,
                            date: selectedDate,
                          ),
                          child: Text(loc.apply),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
