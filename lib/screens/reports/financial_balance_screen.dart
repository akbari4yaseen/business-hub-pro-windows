import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../database/account_db.dart';
import '../../utils/transaction_helper.dart';

class FinancialBalanceScreen extends StatefulWidget {
  const FinancialBalanceScreen({Key? key}) : super(key: key);
  @override
  State<FinancialBalanceScreen> createState() => _FinancialBalanceScreenState();
}

final NumberFormat _formatter = NumberFormat("#,##0.##");

class _FinancialBalanceScreenState extends State<FinancialBalanceScreen> {
  final AccountDBHelper _accountDB = AccountDBHelper();

  Map<String, Map<String, dynamic>> _summaryByCurrency = {};
  bool _isLoading = true;
  String? _selectedCurrency;
  String? _selectedAccountType;

  // Cache for accounts and transactions to avoid repeated database calls
  List<Map<String, dynamic>>? _cachedAccounts;
  Map<int, List<Map<String, dynamic>>>? _cachedTransactions;

  // Debouncer for filter changes to avoid excessive reloads
  DateTime? _lastFilterChange;
  static const Duration _filterDebounceTime = Duration(milliseconds: 300);

  final List<String> _accountTypes = [
    'customer',
    'supplier',
    'exchanger',
    'bank',
    'income',
    'expense',
    'owner',
    'company',
    'employee',
  ];

  @override
  void initState() {
    super.initState();
    _loadFinancialBalanceData();
  }

  Future<void> _loadFinancialBalanceData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load accounts only once and cache them
      if (_cachedAccounts == null) {
        _cachedAccounts = await _accountDB.getAllAccounts();
      }

      final accounts = _cachedAccounts!;
      final summaryByCurrency = <String, Map<String, dynamic>>{};

      // Initialize cache for transactions if not exists
      if (_cachedTransactions == null) {
        _cachedTransactions = {};
      }

      // Process accounts in batches for better performance
      const int batchSize = 10;
      for (int i = 0; i < accounts.length; i += batchSize) {
        final endIndex =
            (i + batchSize < accounts.length) ? i + batchSize : accounts.length;
        final batch = accounts.sublist(i, endIndex);

        await _processAccountBatch(batch, summaryByCurrency);

        // Allow UI to update between batches
        if (mounted && i + batchSize < accounts.length) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      if (mounted) {
        setState(() {
          _summaryByCurrency = summaryByCurrency;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .errorLoadingData(e.toString()))),
        );
      }
    }
  }

  Future<void> _processAccountBatch(List<Map<String, dynamic>> accounts,
      Map<String, Map<String, dynamic>> summaryByCurrency) async {
    for (final account in accounts) {
      if (account['id'] > 10 && account['active'] == 1) {
        // Apply account type filter if selected
        if (_selectedAccountType != null &&
            _selectedAccountType != 'all' &&
            account['account_type'] != _selectedAccountType) {
          continue;
        }

        final accountId = account['id'] as int;

        // Use cached transactions if available
        List<Map<String, dynamic>> transactions;
        if (_cachedTransactions!.containsKey(accountId)) {
          transactions = _cachedTransactions![accountId]!;
        } else {
          transactions = await _accountDB.getTransactionsForPrint(accountId);
          _cachedTransactions![accountId] = transactions;
        }

        final balances = aggregateTransactions(transactions);

        for (final currency in balances.keys) {
          // Apply currency filter if selected
          if (_selectedCurrency != null &&
              _selectedCurrency != 'all' &&
              currency != _selectedCurrency) {
            continue;
          }

          final balance = balances[currency]!;
          final credit = balance['summary']['credit'] ?? 0.0;
          final debit = balance['summary']['debit'] ?? 0.0;
          final netBalance = credit - debit;

          summaryByCurrency.putIfAbsent(
              currency,
              () => <String, dynamic>{
                    'totalCredit': 0.0,
                    'totalDebit': 0.0,
                    'totalPayable': 0.0,
                    'totalReceivable': 0.0,
                    'netBalance': 0.0,
                    'accountCount': 0,
                  });

          final summary = summaryByCurrency[currency]!;
          summary['totalCredit'] += credit;
          summary['totalDebit'] += debit;

          if (netBalance < 0) {
            summary['totalPayable'] += netBalance.abs();
          } else if (netBalance > 0) {
            summary['totalReceivable'] += netBalance;
          }

          summary['netBalance'] += netBalance;
          summary['accountCount']++;
        }
      }
    }
  }

  void _onFilterChanged() {
    final now = DateTime.now();
    if (_lastFilterChange != null &&
        now.difference(_lastFilterChange!) < _filterDebounceTime) {
      return; // Debounce filter changes
    }
    _lastFilterChange = now;
    _loadFinancialBalanceData();
  }

  Widget _buildFilters() {
    if (_summaryByCurrency.isEmpty) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Account Type Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedAccountType ?? 'all',
              decoration: InputDecoration(
                labelText: loc.accountType,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: const Icon(Icons.category),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(loc.showAll),
                ),
                ..._accountTypes.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getLocalizedAccountType(type)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAccountType = value;
                });
                _onFilterChanged();
              },
            ),
          ),
          const SizedBox(width: 16), // spacing between filters

          // Currency Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCurrency ?? 'all',
              decoration: InputDecoration(
                labelText: loc.currency,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                prefixIcon: const Icon(Icons.currency_exchange),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(loc.showAll),
                ),
                ..._summaryByCurrency.keys.map((currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value;
                });
                _onFilterChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String currency, Map<String, dynamic> summary) {
    final totalCredit = summary['totalCredit'] as double;
    final totalDebit = summary['totalDebit'] as double;
    final totalReceivable = summary['totalReceivable'] as double;
    final totalPayable = summary['totalPayable'] as double;
    final netBalance = summary['netBalance'] as double;
    final accountCount = summary['accountCount'] as int;

    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with currency and account count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currency,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$accountCount ${accountCount == 1 ? loc.account : loc.accounts}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main metrics grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      loc.totalCredit,
                      totalCredit,
                      currency,
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      loc.totalDebit,
                      totalDebit,
                      currency,
                      Colors.red,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Net balance highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: netBalance >= 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: netBalance >= 0 ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      loc.netBalance,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: netBalance >= 0 ? Colors.green : Colors.red,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${netBalance >= 0 ? '' : ''}\u200E${_formatter.format(netBalance)} $currency',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: netBalance >= 0 ? Colors.green : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payable/Receivable summary
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      loc.receivable,
                      totalReceivable,
                      currency,
                      Colors.blue,
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryMetric(
                      loc.payable,
                      totalPayable,
                      currency,
                      Colors.orange,
                      Icons.arrow_downward,
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

  Widget _buildMetricCard(String label, double amount, String currency,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatter.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            currency,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, double amount, String currency,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatter.format(amount)} $currency',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getLocalizedAccountType(String accountType) {
    final loc = AppLocalizations.of(context)!;
    switch (accountType) {
      case 'customer':
        return loc.customer;
      case 'supplier':
        return loc.supplier;
      case 'exchanger':
        return loc.exchanger;
      case 'bank':
        return loc.bank;
      case 'income':
        return loc.income;
      case 'expense':
        return loc.expense;
      case 'owner':
        return loc.owner;
      case 'company':
        return loc.company;
      case 'employee':
        return loc.employee;
      default:
        return accountType.toUpperCase();
    }
  }

  Widget _buildEmptyState() {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            loc.noFinancialDataAvailable,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            loc.addAccountsTransactionsMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.financialBalance),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialBalanceData,
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _summaryByCurrency.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildFilters(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _summaryByCurrency.length,
                        itemBuilder: (context, index) {
                          final entry =
                              _summaryByCurrency.entries.elementAt(index);
                          return _buildSummaryCard(entry.key, entry.value);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
