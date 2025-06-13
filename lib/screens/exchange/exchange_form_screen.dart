import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../database/exchange_db.dart';
import '../../utils/utilities.dart';
import '../../constants/currencies.dart';
import '../../models/exchange.dart';
import '../../database/account_db.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../utils/number_input_formatter.dart';

class ExchangeFormScreen extends StatefulWidget {
  final Exchange? exchange;

  const ExchangeFormScreen({Key? key, this.exchange}) : super(key: key);

  @override
  State<ExchangeFormScreen> createState() => _ExchangeFormScreenState();
}

class _ExchangeFormScreenState extends State<ExchangeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exchangeDB = ExchangeDBHelper();
  final _accountDB = AccountDBHelper();
  static final NumberFormat _numberFormatter = NumberFormat('#,##0.##');

  late TextEditingController _fromAccountController;
  late TextEditingController _toAccountController;
  late TextEditingController _amountController;
  late TextEditingController _rateController;
  late TextEditingController _expectedRateController;
  late TextEditingController _descriptionController;
  late TextEditingController _resultAmountController;

  Map<String, dynamic>? _selectedFromAccount;
  Map<String, dynamic>? _selectedToAccount;
  String _fromCurrency = 'AFN';
  String _toCurrency = 'USD';
  String _operator = '*';
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'exchange';
  double _profitLoss = 0;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _filteredFromAccounts = [];
  List<Map<String, dynamic>> _filteredToAccounts = [];

  final List<String> _transactionTypes = [
    'exchange',
    'cash_in',
    'cash_out',
    'cash_swap'
  ];

  @override
  void initState() {
    super.initState();
    _fromAccountController = TextEditingController();
    _toAccountController = TextEditingController();
    _amountController = TextEditingController();
    _rateController = TextEditingController();
    _expectedRateController = TextEditingController();
    _descriptionController = TextEditingController();
    _resultAmountController = TextEditingController();

    _loadAccounts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.exchange != null && _accounts.isNotEmpty) {
      _loadExchangeData();
    }
  }

  void _updateControllers() {
    if (!mounted) return;

    if (_selectedFromAccount != null) {
      _fromAccountController.text =
          getLocalizedSystemAccountName(context, _selectedFromAccount!['name']);
    }

    if (_selectedToAccount != null) {
      _toAccountController.text =
          getLocalizedSystemAccountName(context, _selectedToAccount!['name']);
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _accountDB.getOptionAccounts();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _filteredFromAccounts = accounts;
          _filteredToAccounts = accounts;
        });
        // Load exchange data after accounts are loaded
        _loadExchangeData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading accounts: $e')),
        );
      }
    }
  }

  Future<void> _loadExchangeData() async {
    if (widget.exchange == null) return;

    try {
      final exchange = widget.exchange!;

      // Set the selected accounts first
      final fromAccount = _accounts.firstWhere(
        (account) => account['id'] == exchange.fromAccountId,
        orElse: () => _accounts.first,
      );
      final toAccount = _accounts.firstWhere(
        (account) => account['id'] == exchange.toAccountId,
        orElse: () => _accounts.first,
      );

      if (!mounted) return;

      setState(() {
        _selectedFromAccount = fromAccount;
        _selectedToAccount = toAccount;
        _fromCurrency = exchange.fromCurrency;
        _toCurrency = exchange.toCurrency;
        _operator = exchange.operator;
        _transactionType = exchange.transactionType;
        _selectedDate = DateTime.parse(exchange.date);
        _profitLoss = exchange.profitLoss;
      });

      // Update all controllers in one place
      if (mounted) {
        _amountController.text = exchange.amount.toString();
        _rateController.text = exchange.rate.toString();
        _expectedRateController.text = exchange.expectedRate?.toString() ?? '';
        _descriptionController.text = exchange.description ?? '';
        _resultAmountController.text = exchange.resultAmount.toString();
        _updateControllers(); // Update account controllers
      }

      // Update filtered accounts after setting state
      if (mounted) {
        setState(() {
          _filteredFromAccounts = _accounts;
          _filteredToAccounts = _accounts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exchange data: $e')),
        );
      }
    }
  }

  void _calculateResultAmount() {
    if (_amountController.text.isEmpty || _rateController.text.isEmpty) return;

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final rate = double.parse(_rateController.text.replaceAll(',', ''));
      double resultAmount;

      if (_operator == '*') {
        resultAmount = amount * rate;
      } else {
        resultAmount = amount / rate;
      }

      setState(() {
        _resultAmountController.text = _numberFormatter.format(resultAmount);
      });

      // Calculate profit/loss if expected rate is provided
      if (_expectedRateController.text.isNotEmpty) {
        final expectedRate =
            double.parse(_expectedRateController.text.replaceAll(',', ''));
        double expectedAmount;

        if (_operator == '*') {
          expectedAmount = resultAmount / rate * expectedRate;
        } else {
          expectedAmount = resultAmount * rate / expectedRate;
        }

        setState(() {
          _profitLoss = resultAmount - expectedAmount;
        });
      }
    } catch (e) {
      // Handle parsing errors silently
      debugPrint(e.toString());
    }
  }

  void _filterFromAccounts(String query) {
    setState(() {
      _filteredFromAccounts = _accounts
          .where((account) => account['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _filterToAccounts(String query) {
    setState(() {
      _filteredToAccounts = _accounts
          .where((account) => account['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _saveExchange() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFromAccount == null || _selectedToAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both accounts')),
      );
      return;
    }

    try {
      if (widget.exchange == null) {
        // New exchange
        await _exchangeDB.performExchange(
          fromAccountId: _selectedFromAccount!['id'],
          toAccountId: _selectedToAccount!['id'],
          fromCurrency: _fromCurrency,
          toCurrency: _toCurrency,
          amount: double.parse(_amountController.text.replaceAll(',', '')),
          rate: double.parse(_rateController.text.replaceAll(',', '')),
          resultAmount:
              double.parse(_resultAmountController.text.replaceAll(',', '')),
          operator: _operator,
          description: _descriptionController.text,
          expectedRate: _expectedRateController.text.isNotEmpty
              ? double.parse(_expectedRateController.text)
              : null,
          transactionType: _transactionType,
          date: _selectedDate,
        );
      } else {
        // Edit existing exchange
        final updatedExchange = Exchange(
          id: widget.exchange!.id,
          fromAccountId: _selectedFromAccount!['id'],
          toAccountId: _selectedToAccount!['id'],
          fromCurrency: _fromCurrency,
          toCurrency: _toCurrency,
          operator: _operator,
          amount: double.parse(_amountController.text.replaceAll(',', '')),
          rate: double.parse(_rateController.text.replaceAll(',', '')),
          resultAmount:
              double.parse(_resultAmountController.text.replaceAll(',', '')),
          expectedRate: _expectedRateController.text.isNotEmpty
              ? double.parse(_expectedRateController.text)
              : null,
          profitLoss: _profitLoss,
          transactionType: _transactionType,
          description: _descriptionController.text,
          date: _selectedDate.toIso8601String(),
        );
        await _exchangeDB.updateExchange(updatedExchange);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.exchange == null ? loc.newExchange : loc.editExchange),
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Text(
                        loc.exchangeDetails,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Expanded(
                            child: Column(
                              children: [
                                // Transaction Type Selection
                                DropdownButtonFormField<String>(
                                  value: _transactionType,
                                  decoration: InputDecoration(
                                    labelText: loc.transactionType,
                                  ),
                                  items: _transactionTypes
                                      .map((type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type
                                                .replaceAll('_', ' ')
                                                .toUpperCase()),
                                          ))
                                      .toList(),
                                  onChanged: null, // disables the dropdown
                                ),

                                const SizedBox(height: 16),

                                // From Account Autocomplete
                                Autocomplete<Map<String, dynamic>>(
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _accounts;
                                    }
                                    return _filteredFromAccounts;
                                  },
                                  displayStringForOption:
                                      (Map<String, dynamic> account) =>
                                          getLocalizedSystemAccountName(
                                              context, account['name']),
                                  onSelected: (Map<String, dynamic> account) {
                                    setState(() {
                                      _selectedFromAccount = account;
                                      _fromAccountController.text =
                                          getLocalizedSystemAccountName(
                                              context, account['name']);

                                      // Also set the 'to' account if not already selected
                                      if (_selectedToAccount == null) {
                                        _selectedToAccount = account;
                                        _toAccountController.text =
                                            getLocalizedSystemAccountName(
                                                context, account['name']);
                                      }
                                    });
                                  },
                                  fieldViewBuilder: (context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted) {
                                    _fromAccountController =
                                        textEditingController;
                                    return TextFormField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: loc.fromAccount,
                                      ),
                                      onChanged: _filterFromAccounts,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return loc.pleaseSelectAccount;
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // To Account Autocomplete
                                Autocomplete<Map<String, dynamic>>(
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return _accounts;
                                    }
                                    return _filteredToAccounts;
                                  },
                                  displayStringForOption:
                                      (Map<String, dynamic> account) =>
                                          getLocalizedSystemAccountName(
                                              context, account['name']),
                                  onSelected: (Map<String, dynamic> account) {
                                    setState(() {
                                      _selectedToAccount = account;
                                      _toAccountController.text =
                                          getLocalizedSystemAccountName(
                                              context, account['name']);
                                    });
                                  },
                                  fieldViewBuilder: (context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted) {
                                    _toAccountController =
                                        textEditingController;
                                    return TextFormField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: loc.toAccount,
                                      ),
                                      onChanged: _filterToAccounts,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return loc.pleaseSelectAccount;
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Currencies
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _fromCurrency,
                                        decoration: InputDecoration(
                                          labelText: loc.fromCurrency,
                                        ),
                                        items: currencies
                                            .map((currency) => DropdownMenuItem(
                                                  value: currency,
                                                  child: Text(currency),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(
                                                () => _fromCurrency = value);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _toCurrency,
                                        decoration: InputDecoration(
                                          labelText: loc.toCurrency,
                                        ),
                                        items: currencies
                                            .map((currency) => DropdownMenuItem(
                                                  value: currency,
                                                  child: Text(currency),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _toCurrency = value);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right Column
                          Expanded(
                            child: Column(
                              children: [
                                // Amount and Rate
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _amountController,
                                        decoration: InputDecoration(
                                          labelText: loc.amount,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [NumberInput()],
                                        onChanged: (_) =>
                                            _calculateResultAmount(),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter an amount';
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _rateController,
                                        decoration: InputDecoration(
                                          labelText: loc.rate,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [NumberInput()],
                                        onChanged: (_) =>
                                            _calculateResultAmount(),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a rate';
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Operator Selection
                                DropdownButtonFormField<String>(
                                  value: _operator,
                                  decoration: InputDecoration(
                                    labelText: loc.operator,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                        value: '*', child: Text(loc.multiply)),
                                    DropdownMenuItem(
                                        value: '/', child: Text(loc.divide)),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _operator = value;
                                        _calculateResultAmount();
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Result Amount
                                TextFormField(
                                  controller: _resultAmountController,
                                  decoration: InputDecoration(
                                    labelText: loc.resultAmount,
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [NumberInput()],
                                ),
                                const SizedBox(height: 16),

                                // Expected Rate (Optional)
                                TextFormField(
                                  controller: _expectedRateController,
                                  decoration: InputDecoration(
                                    labelText: loc.expectedRateOptional,
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [NumberInput()],
                                  onChanged: (_) => _calculateResultAmount(),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Profit/Loss Display
                                if (_expectedRateController.text.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: _profitLoss >= 0
                                              ? Colors.green
                                              : Colors.red),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(loc.profitLoss),
                                        Text(
                                          _profitLoss.toStringAsFixed(2),
                                          style: TextStyle(
                                            color: _profitLoss >= 0
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        loc.additionalInfo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: loc.description,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Date Selection
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(loc.date),
                        subtitle: Text(dFormatter.formatLocalizedDate(
                            context, _selectedDate.toString())),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await pickLocalizedDate(
                            context: context,
                            initialDate: _selectedDate,
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveExchange,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            loc.saveExchange,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromAccountController.dispose();
    _toAccountController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _expectedRateController.dispose();
    _descriptionController.dispose();
    _resultAmountController.dispose();
    super.dispose();
  }
}
