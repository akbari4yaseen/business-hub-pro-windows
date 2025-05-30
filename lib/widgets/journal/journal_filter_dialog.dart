import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;

class JournalFilterDialog extends StatelessWidget {
  final String? selectedType;
  final String? selectedCurrency;
  final DateTime? selectedDate;
  final List<String> typeOptions;
  final List<String> currencyOptions;
  final void Function({String? type, String? currency, DateTime? date}) onApply;
  final VoidCallback onReset;
  final void Function({String? type, String? currency, DateTime? date}) onChanged;

  const JournalFilterDialog({
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

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500), // Width constraint only
        child: Padding(
          padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min, // <== key to wrap content height
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.filter, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Transaction Type Dropdown
              Text(loc.transactionType, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selectedType ?? 'all',
                items: typeOptions.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type == 'all' ? loc.all : (type == 'credit' ? loc.credit : loc.debit)),
                  );
                }).toList(),
                onChanged: (value) => onChanged(type: value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 16),

              // Currency Dropdown
              Text(loc.currency, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selectedCurrency ?? 'all',
                items: currencyOptions.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency == 'all' ? loc.all : currency),
                  );
                }).toList(),
                onChanged: (value) => onChanged(currency: value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await pickLocalizedDate(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                  );
                  if (picked != null) onChanged(date: picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(labelText: loc.date),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate != null
                            ? dFormatter.formatLocalizedDate(context, selectedDate.toString())
                            : loc.selectDate,
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onReset,
                      child: Text(loc.reset),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onApply(
                        type: selectedType,
                        currency: selectedCurrency,
                        date: selectedDate,
                      ),
                      child: Text(loc.applyFilters),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
