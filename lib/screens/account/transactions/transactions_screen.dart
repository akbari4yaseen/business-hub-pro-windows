import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../database/account_db.dart';
import '../../../database/database_helper.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/transaction_details_widget.dart';
import '../../../widgets/search_bar.dart';
import '../../../widgets/transaction_filter_bottom_sheet.dart';
import '../../../utils/date_formatters.dart';
import '../../../utils/utilities.dart';

class TransactionsScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const TransactionsScreen({Key? key, required this.account}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const int _pageSize = 30;
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  List<Map<String, dynamic>> transactions = [];
  bool isLoading = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedCurrency;
  DateTime? _selectedDate;
  List<String> currencyOptions = [];

  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refreshTransactions();
  }

  Future<void> _loadCurrencies() async {
    final list = await DatabaseHelper().getDistinctCurrencies();
    list.sort();
    currencyOptions = ['all', ...list];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !isLoading) {
      _fetchNextPage();
    }
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      transactions.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _fetchNextPage(reset: true);
  }

  Future<void> _fetchNextPage({bool reset = false}) async {
    if (!_hasMore && !reset) return;
    setState(() {
      if (reset) isLoading = true;
      _isLoadingMore = !reset;
    });
    final txs = await AccountDBHelper().getTransactions(
      widget.account['id'],
      offset: _currentPage * _pageSize,
      limit: _pageSize,
      searchQuery: _searchController.text,
      transactionType: _selectedType,
      currency: _selectedCurrency,
      exactDate: _selectedDate,
    );
    if (!mounted) return;
    setState(() {
      if (reset) {
        transactions = txs;
        isLoading = false;
      } else {
        transactions.addAll(txs);
      }
      _isLoadingMore = false;
      if (txs.length < _pageSize) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
    });
  }

  void _showFilterModal() {
    String? tmpType = _selectedType;
    String? tmpCurrency = _selectedCurrency;
    DateTime? tmpDate = _selectedDate;
    _loadCurrencies();

    final typeList = ['all', 'credit', 'debit'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c2, setModal) => Material(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: TransactionFilterBottomSheet(
            selectedType: tmpType,
            selectedCurrency: tmpCurrency,
            selectedDate: tmpDate,
            typeOptions: typeList,
            currencyOptions: currencyOptions,
            onChanged: ({type, currency, date}) {
              setModal(() {
                tmpType = type;
                tmpCurrency = currency;
                tmpDate = date;
              });
            },
            onReset: () {
              setModal(() {
                tmpType = null;
                tmpCurrency = null;
                tmpDate = null;
              });
            },
            onApply: ({type, currency, date}) {
              setState(() {
                _selectedType = tmpType;
                _selectedCurrency = tmpCurrency;
                _selectedDate = tmpDate;
              });
              Navigator.pop(context);
              _refreshTransactions();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = widget.account['balances'] as Map<String, dynamic>? ?? {};
    final themeProvider = Provider.of<ThemeProvider>(context);
    final loc = AppLocalizations.of(context)!;

    final summaryCard = balances.isNotEmpty
        ? SizedBox(
            height: 167,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: balances.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                final entry = balances.entries.elementAt(idx);
                return _buildBalanceCard(entry);
              },
            ),
          )
        : const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: _isSearching
            ? CommonSearchBar(
                controller: _searchController,
                debounceDuration: const Duration(milliseconds: 500),
                isLoading: isLoading,
                onChanged: (_) => _refreshTransactions(),
                onSubmitted: (_) => _refreshTransactions(),
                onCancel: () => setState(() => _isSearching = false),
                onClear: () {
                  _searchController.clear();
                  _refreshTransactions();
                },
                hintText: loc.search,
              )
            : Text(
                getLocalizedSystemAccountName(context, widget.account['name']),
                style: const TextStyle(fontSize: 18),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              tooltip: loc.search,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
            tooltip: loc.filter,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? Center(child: Text(loc.noTransactionsFound))
              : NestedScrollView(
                  headerSliverBuilder: (context, innerScroll) => [
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeProvider.cardBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24)),
                        ),
                        padding: const EdgeInsets.only(top: 16, bottom: 24),
                        child: summaryCard,
                      ),
                    ),
                  ],
                  body: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return _buildTransactionCard(tx, loc);
                    },
                  ),
                ),
    );
  }

  Widget _buildBalanceCard(MapEntry<String, dynamic> entry) {
    final currency = entry.value['currency'] ?? entry.key;
    final summary = entry.value['summary'] ?? {};
    final credit = summary['credit'] ?? 0;
    final debit = summary['debit'] ?? 0;
    final balance = summary['balance'] ?? 0;

    return Container(
      width: 240,
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Color.fromARGB(255, 99, 83, 218)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currency,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Credit',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _amountFormatter.format(credit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Debit',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _amountFormatter.format(debit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              const Text('Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '\u200E${_amountFormatter.format(balance)}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(transaction: tx),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, AppLocalizations loc) {
    final isCredit = tx['transaction_type'] == 'credit';
    final icon = isCredit ? FontAwesomeIcons.plus : FontAwesomeIcons.minus;
    final color = isCredit ? Colors.green : Colors.red;
    final balanceColor = tx['balance'] >= 0 ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          '\u200E${_amountFormatter.format(tx['amount'])} ${tx['currency']}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.balance}: \u200E${_amountFormatter.format(tx['balance'])} ${tx['currency']}',
              style: TextStyle(fontSize: 14, color: balanceColor),
            ),
            Text(formatLocalizedDate(context, tx['date']),
                style: const TextStyle(fontSize: 13)),
            Text(
              tx['description'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'details':
                _showDetails(tx);
                break;
              case 'edit':
                // TODO: implement edit
                break;
              case 'delete':
                // TODO: implement delete
                break;
              default:
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'details',
                child: ListTile(
                    leading: const Icon(Icons.info), title: Text(loc.details))),
            PopupMenuItem(
                value: 'share',
                child: ListTile(
                    leading: const Icon(Icons.share), title: Text(loc.share))),
            PopupMenuItem(
                value: 'edit',
                child: ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: Text(loc.edit))),
            PopupMenuItem(
                value: 'delete',
                child: ListTile(
                    leading: const Icon(Icons.delete, color: Colors.redAccent),
                    title: Text(loc.delete))),
            PopupMenuItem(
                value: 'print',
                enabled: false,
                child: ListTile(
                    leading: const Icon(Icons.print, color: Colors.grey),
                    title: Text(loc.printDisabled))),
          ],
        ),
      ),
    );
  }
}
