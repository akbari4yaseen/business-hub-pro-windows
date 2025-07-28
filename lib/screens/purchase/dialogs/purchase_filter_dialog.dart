import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../utils/date_time_picker_helper.dart';
import '../../../utils/date_formatters.dart' as dFormatter;

class PurchaseFilterDialog extends StatelessWidget {
  final String? selectedSupplier;
  final String? selectedCurrency;
  final DateTime? selectedDate;
  final List<String> supplierOptions;
  final List<String> currencyOptions;
  final void Function({String? supplier, String? currency, DateTime? date}) onApply;
  final VoidCallback onReset;
  final void Function({String? supplier, String? currency, DateTime? date}) onChanged;

  const PurchaseFilterDialog({
    Key? key,
    this.selectedSupplier,
    this.selectedCurrency,
    this.selectedDate,
    required this.supplierOptions,
    required this.currencyOptions,
    required this.onApply,
    required this.onReset,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, minWidth: 500),
        child: Padding(
          padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.filter_list, size: 24, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    loc.filter,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'VazirBold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Options in a more organized layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Supplier Dropdown
                        Text(
                          loc.supplier,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedSupplier ?? 'all',
                          items: supplierOptions.map((supplier) {
                            final displayName = supplier == 'all' ? loc.all : supplier.split(' (')[0];
                            return DropdownMenuItem(
                              value: supplier,
                              child: Text(
                                displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => onChanged(supplier: value),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Currency Dropdown
                        Text(
                          loc.currency,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCurrency ?? 'all',
                          items: currencyOptions.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency == 'all' ? loc.all : currency),
                            );
                          }).toList(),
                          onChanged: (value) => onChanged(currency: value),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Date Picker (full width)
              Text(
                loc.date,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await pickLocalizedDate(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                  );
                  if (picked != null) onChanged(date: picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate != null
                            ? dFormatter.formatLocalizedDate(context, selectedDate.toString())
                            : loc.selectDate,
                        style: TextStyle(
                          color: selectedDate != null ? null : Colors.grey[600],
                        ),
                      ),
                      Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.clear),
                      label: Text(loc.reset),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onApply(
                        supplier: selectedSupplier,
                        currency: selectedCurrency,
                        date: selectedDate,
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(loc.applyFilters),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 