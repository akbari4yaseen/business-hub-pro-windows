import '../../../widgets/journal/journal_filter_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'print_transactions.dart';

import '../../../database/account_db.dart';
import '../../../database/journal_db.dart';
import '../../../utils/account_share_helper.dart';
import '../../../database/database_helper.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/transaction/transaction_details_widget.dart';
import '../../../widgets/search_bar.dart';
import '../../../utils/date_formatters.dart' as dFormatter;
import '../../../utils/utilities.dart';
import '../../../widgets/auth_widget.dart';
import '../../../widgets/transaction/transaction_print_settings_dialog.dart';
import '../../../utils/transaction_share_helper.dart';
import '../../../utils/transaction_helper.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/journal/journal_form_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const TransactionsScreen({Key? key, required this.account}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const int _pageSize = 30;
  static final NumberFormat _amountFormatter = NumberFormat('#,###.##');

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> transactions = [];
  bool isLoading = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedCurrency;
  DateTime? _selectedDate;
  final List<String> _currencyOptions = ['all'];

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isAtTop = true;

  Map<String, dynamic> _balances = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _balances = widget.account['balances'] as Map<String, dynamic>? ?? {};
    _loadCurrencies();
    _refreshTransactions();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;

    // load more when near bottom
    if (pos.pixels >= pos.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !isLoading) {
      _fetchNextPage();
    }

    // hide/show FAB based on whether we're at the top
    final atTop = pos.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      transactions.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _fetchNextPage(reset: true);
    await _loadBalances();
  }

  /// re‐load the raw details from the DB and re‐aggregate
  Future<void> _loadBalances() async {
    final allDetails =
        await AccountDBHelper().getTransactionsForPrint(widget.account['id']);
    final newBalances = aggregateTransactions(allDetails);
    if (!mounted) return;
    setState(() => _balances = newBalances);
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

  Future<void> _loadCurrencies() async {
    final list = await DatabaseHelper().getDistinctCurrencies();
    setState(() {
      _currencyOptions
        ..clear()
        ..addAll(['all', ...list..sort()]);
    });
  }

  void _showFilterModal() {
    String? tmpType = _selectedType;
    String? tmpCurrency = _selectedCurrency;
    DateTime? tmpDate = _selectedDate;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return JournalFilterDialog(
              selectedType: tmpType,
              selectedCurrency: tmpCurrency,
              selectedDate: tmpDate,
              typeOptions: const ['all', 'credit', 'debit'],
              currencyOptions: _currencyOptions,
              onChanged: ({String? type, String? currency, DateTime? date}) {
                setModalState(() {
                  if (type != null) tmpType = type;
                  if (currency != null) tmpCurrency = currency;
                  if (date != null) tmpDate = date;
                });
              },
              onReset: () {
                setModalState(() {
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
                Navigator.of(context).pop();
                _refreshTransactions();
              },
            );
          },
        );
      },
    );
  }

  void _shareTransaction(Map<String, dynamic> transaction) {
    // Add the account_name field
    transaction['account_name'] = widget.account['name'];

    // Now pass the updated map along
    shareJournalEntry(context, transaction);
  }

  /// Fetches all transactions, applies print settings filters in-memory, then prints.
  void _onPrintPressed() async {
    if (_currencyOptions.isEmpty) {
      await _loadCurrencies();
    }

    final result = await showDialog<PrintSettings>(
      context: context,
      builder: (_) => PrintSettingsDialog(
        typeOptions: ['all', 'credit', 'debit'],
        currencyOptions: _currencyOptions,
        initialType: _selectedType ?? 'all',
        initialCurrency: _selectedCurrency ?? 'all',
        initialStart: null,
        initialEnd: null,
      ),
    );
    if (result == null) return;

    // 1) Fetch all transactions
    final allTxs = await AccountDBHelper().getTransactionsForPrint(
      widget.account['id'] as int,
    );

    final start = result.startDate; // nullable DateTime
    final end = result.endDate; // nullable DateTime

// compute an exclusive upper bound
    final endExclusive = end?.add(Duration(days: 1));
    final startExclusive = start?.add(Duration(days: 1));

    // 2) Filter in-memory
    final filtered = allTxs.where((tx) {
      final txDate = DateTime.parse(tx['date'] as String);

      final dateOk =
          (startExclusive == null || !txDate.isBefore(startExclusive)) &&
              (endExclusive == null || txDate.isBefore(endExclusive));

      final typeOk = result.transactionType == 'all' ||
          (tx['transaction_type'] as String) == result.transactionType;
      final currencyOk = result.currency == 'all' ||
          (tx['currency'] as String) == result.currency;
      return dateOk && typeOk && currencyOk;
    }).toList();

    // 3) Print filtered list
    await PrintTransactions.printTransactions(
      context,
      widget.account,
      transactions: filtered,
    );
  }

  @override
  Widget build(BuildContext context) {
    final balances = _balances;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final loc = AppLocalizations.of(context)!;

    Widget sliverHeader = SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.cardBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: balances.isNotEmpty
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
            : const SizedBox.shrink(),
      ),
    );

    Widget sliverList = SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tx = transactions[index];
            return _buildTransactionCard(tx, loc);
          },
          childCount: transactions.length,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? CommonSearchBar(
                controller: _searchController,
                debounceDuration: const Duration(milliseconds: 500),
                isLoading: isLoading,
                onChanged: (_) => _refreshTransactions(),
                onSubmitted: (_) => _refreshTransactions(),
                onCancel: () {
                  _searchController.clear();
                  _isSearching = false;
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
              icon: const Icon(Icons.refresh),
              onPressed: _refreshTransactions,
              tooltip: loc.refresh,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  _showFilterModal();
                  break;
                case 'print':
                  _onPrintPressed();
                  break;
                case 'share':
                  shareAccountBalances(context, widget.account);
                  break;
                case 'whatsapp':
                  shareAccountBalances(context, widget.account,
                      viaWhatsApp: true);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: const Icon(Icons.filter_list),
                  title: Text(loc.filter),
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(loc.print),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: const FaIcon(FontAwesomeIcons.shareNodes),
                  title: Text(loc.shareBalance),
                ),
              ),
              PopupMenuItem(
                value: 'whatsapp',
                child: ListTile(
                  leading: const FaIcon(FontAwesomeIcons.whatsapp),
                  title: Text(loc.sendBalance),
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? Center(child: Text(loc.noTransactionsFound))
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    sliverHeader,
                    sliverList,
                    if (_isLoadingMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transaction_add_fab',
        mini: !_isAtTop,
        child: FaIcon(
            _isAtTop ? FontAwesomeIcons.plus : FontAwesomeIcons.angleUp,
            size: 18),
        onPressed: () {
          if (_isAtTop) {
            _addJournal();
          } else {
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut);
          }
        },
      ),
    );
  }

  Widget _buildBalanceCard(MapEntry<String, dynamic> entry) {
    final loc = AppLocalizations.of(context)!;
    final currency = entry.value['currency'] ?? entry.key;
    final summary = entry.value['summary'] ?? {};
    final credit = summary['credit'] as num? ?? 0;
    final debit = summary['debit'] as num? ?? 0;
    final balance = summary['balance'] as num? ?? 0;

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
                  Text(loc.credit,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
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
                  Text(loc.debit,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
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
              Text(loc.balance,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '\u200E${_amountFormatter.format(balance)}',
                style: const TextStyle(
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
    showDialog(
      context: context,
      builder: (_) => TransactionDetailsSheet(transaction: tx),
    );
  }

  Future<void> _addJournal() async {
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => JournalFormDialog(
        initialAccountId: widget.account['id'],
        initialAccountName: widget.account['name'],
        onSave: (journalData) async {
          try {
            await JournalDBHelper().insertJournal(
              date: journalData['date'],
              accountId: journalData['account_id'],
              trackId: journalData['track_id'],
              amount: journalData['amount'],
              currency: journalData['currency'],
              transactionType: journalData['transaction_type'],
              description: journalData['description'],
            );
            Navigator.of(dialogContext).pop(journalData);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.errorSavingJournal)),
              );
            }
          }
        },
      ),
    );

    if (result != null && mounted) {
      await _refreshTransactions();
    }
  }

  Future<void> _handleEdit(
      Map<String, dynamic> tx, AppLocalizations loc) async {
    if (tx['transaction_group'] != 'journal') return;
    final context = this.context;
    try {
      final journal =
          await JournalDBHelper().getJournalById(tx['transaction_id']);
      if (journal == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.transactionNotFound)),
          );
        }
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => JournalFormDialog(
          journal: journal,
          onSave: (journalData) async {
            try {
              await JournalDBHelper().updateJournal(
                id: journal['id'],
                date: journalData['date'],
                accountId: journalData['account_id'],
                trackId: journalData['track_id'],
                amount: journalData['amount'],
                currency: journalData['currency'],
                transactionType: journalData['transaction_type'],
                description: journalData['description'],
              );
              Navigator.of(dialogContext).pop(journalData);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.transactionEditError)),
                );
              }
            }
          },
        ),
      );

      if (result != null && mounted) {
        await _refreshTransactions();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.transactionEditError)),
        );
      }
    }
  }

  Future<void> _handleDelete(
      Map<String, dynamic> tx, AppLocalizations loc) async {
    final ctx = context;

    // Step 1: authenticate
    showDialog(
      context: ctx,
      builder: (_) => AuthWidget(
        actionReason: loc.deleteJournalAuthMessage,
        onAuthenticated: () {
          // Close the auth dialog
          Navigator.of(ctx).pop();

          // Step 2: show confirmation dialog with constrained width
          showDialog(
            context: ctx,
            builder: (confirmCtx) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AlertDialog(
                  title: Text(loc.confirmDelete),
                  content: Text(loc.confirmDeleteTransaction),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(confirmCtx).pop(),
                      child: Text(loc.cancel),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(confirmCtx).pop();
                        try {
                          if (tx['transaction_group'] == 'journal') {
                            await JournalDBHelper()
                                .deleteJournal(tx['transaction_id']);
                            if (ctx.mounted) {
                              await _refreshTransactions();
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                  content: Text(loc.transactionDeleteError)),
                            );
                          }
                        }
                      },
                      child: Text(
                        loc.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, AppLocalizations loc) {
    final isCredit = tx['transaction_type'] == 'credit';
    final icon = isCredit ? FontAwesomeIcons.plus : FontAwesomeIcons.minus;
    final color = isCredit ? Colors.green : Colors.red;
    final balanceColor = tx['balance'] >= 0 ? Colors.green : Colors.red;
    String formatAmount(num amount) =>
        '\u200E${_amountFormatter.format(amount)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () => _showDetails(tx),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          '${formatAmount(tx['amount'])} ${tx['currency']}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.balance}:${formatAmount(tx['balance'])} ${tx['currency']}',
              style: TextStyle(fontSize: 14, color: balanceColor),
            ),
            Text(dFormatter.formatLocalizedDateTime(context, tx['date']),
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
                _handleEdit(tx, loc);
                break;
              case 'delete':
                _handleDelete(tx, loc);
              case 'share':
                _shareTransaction(tx);
                break;
              case 'print':
                // print later
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'details',
              child: ListTile(
                leading: const Icon(Icons.info),
                title: Text(loc.details),
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text(loc.share),
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
                title: Text(loc.edit),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: Text(loc.delete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
