import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(String?) onAccountTypeChanged;
  final Function(String?) onCurrencyChanged;
  final Function(double, double) onBalanceAmountChanged;
  final Function(bool) onPositiveNegativeChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterBottomSheet({
    Key? key,
    required this.onAccountTypeChanged,
    required this.onCurrencyChanged,
    required this.onBalanceAmountChanged,
    required this.onPositiveNegativeChanged,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedAccountType;
  String? _selectedCurrency;
  TextEditingController _minBalanceController =
      TextEditingController(text: "0");
  TextEditingController _maxBalanceController =
      TextEditingController(text: "10000");
  bool _showPositiveBalances = true;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _minBalanceController.dispose();
    _maxBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context)
            .viewInsets
            .bottom, // Push up when keyboard opens
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text("Filters",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),

              // Account Type Filter
              ExpansionTile(
                title: Text("Account Type"),
                leading: Icon(Icons.account_balance_wallet),
                children: [
                  Wrap(
                    spacing: 8.0,
                    children: [
                      "All",
                      "System",
                      "Customer",
                      "Supplier",
                      "Exchanger"
                    ]
                        .map((type) => ChoiceChip(
                              label: Text(type),
                              selected: _selectedAccountType == type,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedAccountType = selected ? type : null;
                                });
                                widget
                                    .onAccountTypeChanged(_selectedAccountType);
                              },
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 10),
                ],
              ),

              // Currency Filter
              ExpansionTile(
                title: Text("Currency"),
                leading: Icon(Icons.monetization_on),
                children: [
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCurrency,
                    hint: Text("Select Currency"),
                    items: ["USD", "EUR", "PKR", "IRR", "EUD", "AFN"]
                        .map((currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                      widget.onCurrencyChanged(value);
                    },
                  ),
                  SizedBox(height: 10),
                ],
              ),

              // Balance Amount Filter (Text Input)
              ExpansionTile(
                title: Text("Balance Amount"),
                leading: Icon(Icons.attach_money),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minBalanceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: "Min Balance"),
                          onChanged: (value) {
                            widget.onBalanceAmountChanged(
                              double.tryParse(value) ?? 0,
                              double.tryParse(_maxBalanceController.text) ??
                                  10000,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _maxBalanceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: "Max Balance"),
                          onChanged: (value) {
                            widget.onBalanceAmountChanged(
                              double.tryParse(_minBalanceController.text) ?? 0,
                              double.tryParse(value) ?? 10000,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),

              // Positive / Negative Balance Switch
              ExpansionTile(
                title: Text("Positive / Negative Balances"),
                leading: Icon(Icons.compare_arrows),
                children: [
                  SwitchListTile(
                    title: Text(_showPositiveBalances
                        ? "Show Positive Balances"
                        : "Show Negative Balances"),
                    value: _showPositiveBalances,
                    onChanged: (value) {
                      setState(() {
                        _showPositiveBalances = value;
                      });
                      widget.onPositiveNegativeChanged(value);
                    },
                  ),
                  SizedBox(height: 10),
                ],
              ),

              // Apply & Clear Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onClearFilters,
                    child: Text("Clear Filters",
                        style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: widget.onApplyFilters,
                    child: Text("Apply Filters"),
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
