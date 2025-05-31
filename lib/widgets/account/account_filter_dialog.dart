import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../utils/utilities.dart';

class AccountFilterBottomDialog extends StatelessWidget {
  final String? selectedAccountType;
  final String? selectedCurrency;
  final List<String> currencyOptions;
  final void Function({String? accountType, String? currency}) onApply;
  final VoidCallback onReset;
  final void Function({String? accountType, String? currency}) onChanged;

  const AccountFilterBottomDialog({
    Key? key,
    required this.selectedAccountType,
    required this.selectedCurrency,
    required this.currencyOptions,
    required this.onApply,
    required this.onReset,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountTypes = [
      "all",
      "system",
      "customer",
      "supplier",
      "exchanger",
      "income",
      "expense",
      "owner",
      "company",
      "employee"
    ];
    final loc = AppLocalizations.of(context)!;

    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.accountFilters,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Account Type Dropdown
                Text(
                  loc.accountType,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedAccountType ?? 'all',
                  onChanged: (value) => onChanged(accountType: value),
                  items: accountTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(getLocalizedAccountType(context, type)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Currency Dropdown
                Text(
                  loc.currency,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCurrency ?? 'all',
                  onChanged: (value) => onChanged(currency: value),
                  items: currencyOptions.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency == 'all' ? loc.all : currency),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Buttons
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
                          accountType: selectedAccountType,
                          currency: selectedCurrency,
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
        ));
  }
}
