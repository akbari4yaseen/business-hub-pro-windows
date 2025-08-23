import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../database/reports_db.dart';
import '../../utils/utilities.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;
import '../../themes/app_theme.dart';
import 'widgets/per_account_filter_panel.dart';

class PeriodicReportsScreen extends StatefulWidget {
  const PeriodicReportsScreen({Key? key}) : super(key: key);

  @override
  _PeriodicReportsScreenState createState() => _PeriodicReportsScreenState();
}

class _PeriodicReportsScreenState extends State<PeriodicReportsScreen> {
  final ReportsDBHelper _db = ReportsDBHelper();
  late AppLocalizations loc;
  final NumberFormat _formatter = NumberFormat("#,###.##");
  // Period options
  final Map<String, String> _periods = {
    'today': '',
    'yesterday': '',
    '7_days': '',
    '14_days': '',
    '1_month': '',
    '3_months': '',
    '6_months': '',
    '1_year': '',
    'custom': '',
  };
  String _selectedPeriod = 'today';
  DateTime? _customStart;
  DateTime? _customEnd;

  // Filters
  String? _accountType;
  String? _currency;

  // Account types and currencies data
  List<Map<String, dynamic>> _accountTypes = [];
  List<String> _currencies = [];
  bool _isLoading = true;

  // Results
  double _creditTotal = 0;
  double _debitTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadAccountTypes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loc = AppLocalizations.of(context)!;
    // initialize localized period labels
    _periods
      ..['today'] = loc.today
      ..['yesterday'] = loc.yesterday
      ..['7_days'] = loc.last7Days
      ..['14_days'] = loc.last14Days
      ..['1_month'] = loc.lastMonth
      ..['3_months'] = loc.last3Months
      ..['6_months'] = loc.last6Months
      ..['1_year'] = loc.lastYear
      ..['custom'] = loc.customRange;
  }

  Future<void> _loadAccountTypes() async {
    try {
      final accountTypes = await _db.getAccountTypeCounts();
      setState(() {
        _accountTypes = accountTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading account types: $e')),
      );
    }
  }

  Future<void> _loadCurrencies() async {
    if (_accountType == null) return;

    try {
      // Get all account balances and filter currencies by selected account type
      final balances = await _db.getAccountBalances();
      final Set<String> currencies = {};

      for (var balance in balances) {
        if (balance['account_type'] == _accountType) {
          currencies.add(balance['currency'] as String);
        }
      }

      setState(() {
        _currencies = currencies.toList();
        // Reset currency selection if previous selection is no longer valid
        if (_currency != null && !_currencies.contains(_currency)) {
          _currency = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading currencies: $e')),
      );
    }
  }

  Future<void> _pickDate(BuildContext ctx, bool isStart) async {
    final initial = DateTime.now();

    final date = await pickLocalizedDate(
      context: ctx,
      initialDate: initial,
    );
    if (date != null) {
      setState(() {
        if (isStart)
          _customStart = date;
        else
          _customEnd = date;
      });
    }
  }

  void _fetchBalances() async {
    if (_accountType == null || _currency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseSelectAllFilters)),
      );
      return;
    }

    DateTime now = DateTime.now();
    DateTime start, end;
    switch (_selectedPeriod) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        break;
      case 'yesterday':
        final y = now.subtract(const Duration(days: 1));
        start = DateTime(y.year, y.month, y.day);
        end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        break;
      case '7_days':
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        start = end.subtract(const Duration(days: 6));
        break;
      case '14_days':
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        start = end.subtract(const Duration(days: 13));
        break;
      case '1_month':
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        start = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3_months':
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6_months':
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        start = DateTime(now.year, now.month - 6, now.day);
        break;
      case '1_year':
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        start = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'custom':
        if (_customStart == null || _customEnd == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.pleaseSelectDateRange)),
          );
          return;
        }
        start = _customStart!;
        end = DateTime(
            _customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59);
        break;
      default:
        return;
    }

    setState(() {
      _creditTotal = 0;
      _debitTotal = 0;
    });

    try {
      final rows = await _db.getCreditDebitBalances(
        accountType: _accountType!,
        currency: _currency!,
        startDate: start,
        endDate: end,
      );

      double credit = 0, debit = 0;
      for (var r in rows) {
        if (r['transaction_type'] == 'credit')
          credit = (r['total'] as num).toDouble();
        else if (r['transaction_type'] == 'debit')
          debit = (r['total'] as num).toDouble();
      }

      setState(() {
        _creditTotal = credit;
        _debitTotal = debit;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(loc.periodicReports)),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Filters Panel
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.filters,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 20),

                              // Account Type
                              DropdownButtonFormField<String>(
                                decoration:
                                    InputDecoration(labelText: loc.accountType),
                                value: _accountType,
                                items: _accountTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type['account_type'] as String,
                                    child: Text(getLocalizedAccountType(
                                        context, type['account_type'])),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _accountType = v;
                                    _currency = null;
                                    _currencies = [];
                                  });
                                  _loadCurrencies(); // now _accountType is up-to-date
                                },
                              ),
                              const SizedBox(height: 16),

                              // Currency
                              DropdownButtonFormField<String>(
                                decoration:
                                    InputDecoration(labelText: loc.currency),
                                value: _currency,
                                items: _currencies.map((currency) {
                                  return DropdownMenuItem<String>(
                                    value: currency,
                                    child: Text(currency),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _currency = v),
                              ),
                              const SizedBox(height: 16),

                              // Period
                              DropdownButtonFormField<String>(
                                decoration:
                                    InputDecoration(labelText: loc.period),
                                value: _selectedPeriod,
                                items: _periods.entries
                                    .map((e) => DropdownMenuItem(
                                        value: e.key, child: Text(e.value)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedPeriod = v!),
                              ),

                              // Custom Date Picker
                              if (_selectedPeriod == 'custom') ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _pickDate(context, true),
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(_customStart == null
                                            ? loc.startDate
                                            : dFormatter.formatLocalizedDate(
                                                context,
                                                _customStart.toString())),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _pickDate(context, false),
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(_customEnd == null
                                            ? loc.endDate
                                            : dFormatter.formatLocalizedDate(
                                                context,
                                                _customEnd.toString())),
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _fetchBalances,
                                icon: const Icon(Icons.analytics),
                                label: Text(loc.generateReport),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right: Result Summary
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(loc.summary,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),

                          // Credit
                          Card(
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.arrow_downward,
                                  color: Colors.green),
                              title: Text(loc.totalCredit),
                              trailing: Text(
                                _currency != null
                                    ? '${_formatter.format(_creditTotal)} $_currency'
                                    : _formatter.format(_creditTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Debit
                          Card(
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.arrow_upward,
                                  color: Colors.red),
                              title: Text(loc.totalDebit),
                              trailing: Text(
                                _currency != null
                                    ? '${_formatter.format(_debitTotal)} $_currency'
                                    : _formatter.format(_debitTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Balance
                          Card(
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.balance,
                                  color: AppTheme.primaryColor),
                              title: Text(loc.balance),
                              trailing: Text(
                                _currency != null
                                    ? '\u200E${_formatter.format(_creditTotal - _debitTotal)} $_currency'
                                    : '\u200E${_formatter.format(_creditTotal - _debitTotal)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _creditTotal >= _debitTotal
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // New: Per-Account Filter Section
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: PerAccountFilterPanel(
                                  db: _db, formatter: _formatter),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ));
  }
}
