import 'package:flutter/material.dart';

class FilterBottomSheet extends StatelessWidget {
  final String? selectedAccountType;
  final String? selectedCurrency;
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
    final currencies = ["USD", "EUR", "PKR", "IRR", "AFN"];
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text("Account Filters",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text("Account Type",
                        style: Theme.of(context).textTheme.labelMedium),
                    Wrap(
                      spacing: 10,
                      children: accountTypes
                          .map((type) => FilterChip(
                                label: Text(type),
                                selected: selectedAccountType == type,
                                onSelected: (_) => onChanged(accountType: type),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text("Currency",
                        style: Theme.of(context).textTheme.labelMedium),
                    Wrap(
                      spacing: 10,
                      children: currencies
                          .map((cur) => FilterChip(
                                label: Text(cur),
                                selected: selectedCurrency == cur,
                                onSelected: (_) => onChanged(currency: cur),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text("Balance Range",
                        style: Theme.of(context).textTheme.labelMedium),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Min"),
                            initialValue: minBalance?.toString() ?? '',
                            onChanged: (val) =>
                                onChanged(min: double.tryParse(val)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Max"),
                            initialValue: maxBalance?.toString() ?? '',
                            onChanged: (val) =>
                                onChanged(max: double.tryParse(val)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text("Balance Type",
                        style: Theme.of(context).textTheme.labelMedium),
                    Wrap(
                      spacing: 10,
                      children: [
                        FilterChip(
                          label: const Text("Positive"),
                          selected: isPositiveBalance == true,
                          onSelected: (_) => onChanged(isPositive: true),
                        ),
                        FilterChip(
                          label: const Text("Negative"),
                          selected: isPositiveBalance == false,
                          onSelected: (_) => onChanged(isPositive: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onReset,
                            child: const Text("Reset"),
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
                            child: const Text("Apply Filters"),
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
