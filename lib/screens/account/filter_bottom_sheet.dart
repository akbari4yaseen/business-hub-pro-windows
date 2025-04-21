import 'package:BusinessHub/utils/utilities.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FilterBottomSheet extends StatelessWidget {
  final String? selectedAccountType;
  final String? selectedCurrency;
  final List<String> currencyOptions;
  final double? minBalance;
  final double? maxBalance;
  final bool? isPositiveBalance;
  final void Function(
      {String? accountType,
      String? currency,
      double? min,
      double? max,
      bool? isPositive}) onApply;
  final VoidCallback onReset;
  final void Function(
      {String? accountType,
      String? currency,
      double? min,
      double? max,
      bool? isPositive}) onChanged;

  const FilterBottomSheet({
    Key? key,
    required this.selectedAccountType,
    required this.selectedCurrency,
    required this.currencyOptions,
    required this.minBalance,
    required this.maxBalance,
    required this.isPositiveBalance,
    required this.onApply,
    required this.onReset,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountTypes = ["all", "system", "customer", "supplier", "exchanger"];
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
                    Text(
                      loc.accountFilters,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // Account Type with horizontal scrolling
                    Text(
                      loc.accountType,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: accountTypes.map((type) {
                          final isSelected =
                              (selectedAccountType ?? 'all') == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FilterChip(
                              label:
                                  Text(getLocalizedAccountType(context, type)),
                              selected: isSelected,
                              onSelected: (_) => onChanged(accountType: type),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Currency with horizontal scrolling
                    Text(
                      loc.currency,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
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

                    // Balance Range
                    Text(
                      loc.balanceRange,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: loc.min),
                            initialValue: minBalance?.toString() ?? '',
                            onChanged: (val) =>
                                onChanged(min: double.tryParse(val)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: loc.max),
                            initialValue: maxBalance?.toString() ?? '',
                            onChanged: (val) =>
                                onChanged(max: double.tryParse(val)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Balance Type
                    Text(
                      loc.balanceType,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Wrap(
                      spacing: 10,
                      children: [
                        FilterChip(
                          label: Text(loc.positive),
                          selected: isPositiveBalance == true,
                          onSelected: (_) => onChanged(isPositive: true),
                        ),
                        FilterChip(
                          label: Text(loc.negative),
                          selected: isPositiveBalance == false,
                          onSelected: (_) => onChanged(isPositive: false),
                        ),
                      ],
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
                              min: minBalance,
                              max: maxBalance,
                              isPositive: isPositiveBalance,
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
            );
          },
        ),
      ),
    );
  }
}
