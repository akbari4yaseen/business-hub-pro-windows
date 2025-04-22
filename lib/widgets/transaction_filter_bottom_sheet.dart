import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TransactionFilterBottomSheet extends StatelessWidget {
  final String? selectedType;
  final String? selectedCurrency;
  final DateTime? selectedDate;
  final List<String> typeOptions;
  final List<String> currencyOptions;
  final void Function({String? type, String? currency, DateTime? date}) onApply;
  final VoidCallback onReset;
  final void Function({String? type, String? currency, DateTime? date})
      onChanged;

  const TransactionFilterBottomSheet({
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
        padding:
            MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
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
                    Text(loc.filter,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    // Transaction Type FilterChips
                    Text(loc.transactionType,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: typeOptions.map((type) {
                        final isSelected = (selectedType ?? 'all') == type;
                        return FilterChip(
                          label: Text(type == 'all'
                              ? loc.all
                              : (type == 'credit' ? loc.credit : loc.debit)),
                          selected: isSelected,
                          onSelected: (_) => onChanged(type: type),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Currency FilterChips

                    Text(loc.currency,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: currencyOptions.map((currency) {
                          final isSelected =
                              (selectedCurrency ?? 'all') == currency;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label:
                                  Text(currency == 'all' ? loc.all : currency),
                              selected: isSelected,
                              onSelected: (_) => onChanged(currency: currency),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
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
                        TextButton(
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
