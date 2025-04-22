import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../database/account_db.dart';
import '../../database/database_helper.dart';
import '../../utils/transaction_helper.dart';
import '../../utils/account_share_helper.dart';

import 'transactions/transactions_screen.dart';
import 'edit_account_screen.dart';
import 'add_account_screen.dart';
import '../../widgets/account_filter_bottom_sheet.dart';
import '../../widgets/account_action_dialogs.dart';
import '../../widgets/account_list_view.dart';
import '../../widgets/search_bar.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const AccountScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  // Controllers & State
  late final TabController _tabController;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;

  bool _isAtTop = true;
  bool _isLoading = true;
  bool _isSearching = false;

  String _searchQuery = '';
  String? _selectedAccountType;
  String? _selectedCurrency;
  double? _minBalance;
  double? _maxBalance;
  bool? _isPositiveBalance;

  List<String> _currencyOptions = [];
  bool _currenciesLoaded = false;

  // Pagination state for active accounts
  List<Map<String, dynamic>> _activeAccounts = [];
  int _activeOffset = 0;
  final int _limit = 30;
  bool _activeHasMore = true;
  bool _isLoadingMoreActive = false;

  // Pagination state for deactivated accounts
  List<Map<String, dynamic>> _deactivatedAccounts = [];
  int _deactivatedOffset = 0;
  bool _deactivatedHasMore = true;
  bool _isLoadingMoreDeactivated = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_updateScrollPosition);
    _scrollController.addListener(_onScroll);
    _loadAccounts();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollPosition() {
    if (!mounted) return;
    final atTop = _scrollController.position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _activeAccounts = [];
      _deactivatedAccounts = [];
      _activeOffset = 0;
      _deactivatedOffset = 0;
      _activeHasMore = true;
      _deactivatedHasMore = true;
    });
    await Future.wait([
      _loadMoreActiveAccounts(reset: true),
      _loadMoreDeactivatedAccounts(reset: true),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreActiveAccounts({bool reset = false}) async {
    if (_isLoadingMoreActive || !_activeHasMore) return;
    setState(() => _isLoadingMoreActive = true);
    try {
      final offset = reset ? 0 : _activeOffset;
      final accounts = await AccountDBHelper().getActiveAccountsPage(
        offset: offset,
        limit: _limit,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _activeAccounts = _mapWithBalances(accounts);
          _activeOffset = accounts.length;
        } else {
          _activeAccounts.addAll(_mapWithBalances(accounts));
          _activeOffset += accounts.length;
        }
        _activeHasMore = accounts.length == _limit;
        _isLoadingMoreActive = false;
      });
    } catch (_) {
      setState(() => _isLoadingMoreActive = false);
    }
  }

  Future<void> _loadMoreDeactivatedAccounts({bool reset = false}) async {
    if (_isLoadingMoreDeactivated || !_deactivatedHasMore) return;
    setState(() => _isLoadingMoreDeactivated = true);
    try {
      final offset = reset ? 0 : _deactivatedOffset;
      final accounts = await AccountDBHelper().getDeactivatedAccountsPage(
        offset: offset,
        limit: _limit,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _deactivatedAccounts = _mapWithBalances(accounts);
          _deactivatedOffset = accounts.length;
        } else {
          _deactivatedAccounts.addAll(_mapWithBalances(accounts));
          _deactivatedOffset += accounts.length;
        }
        _deactivatedHasMore = accounts.length == _limit;
        _isLoadingMoreDeactivated = false;
      });
    } catch (_) {
      setState(() => _isLoadingMoreDeactivated = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      if (_tabController.index == 0) {
        _loadMoreActiveAccounts();
      } else {
        _loadMoreDeactivatedAccounts();
      }
    }
  }

  Future<void> _loadCurrencies() async {
    if (_currenciesLoaded) return;
    final list = await DatabaseHelper().getDistinctCurrencies();
    list.sort();
    setState(() {
      _currencyOptions = ['all', ...list];
      _currenciesLoaded = true;
    });
  }

  List<Map<String, dynamic>> _mapWithBalances(List<Map<String, dynamic>> list) {
    return list
        .map((acct) => {
              ...acct,
              'balances': aggregateTransactions(
                (acct['account_details'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [],
              ),
            })
        .toList();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> list) {
    final q = _searchQuery.toLowerCase();
    return list.where((acct) {
      // Text search
      if (q.isNotEmpty) {
        final name = acct['name']?.toString().toLowerCase() ?? '';
        final addr = acct['address']?.toString().toLowerCase() ?? '';
        if (!name.contains(q) && !addr.contains(q)) return false;
      }
      // Type filter
      if (_selectedAccountType != null &&
          _selectedAccountType != 'all' &&
          acct['account_type'] != _selectedAccountType) return false;
      // Currency filter
      final balances = acct['balances'] as Map<String, dynamic>;
      if (_selectedCurrency != null &&
          _selectedCurrency != 'all' &&
          !balances.containsKey(_selectedCurrency)) return false;
      // Aggregate balance once
      final total = balances.values.fold<double>(
          0.0, (sum, e) => sum + (e['summary']['balance'] as double? ?? 0.0));
      // Range & sign filters
      if (_minBalance != null && total < _minBalance!) return false;
      if (_maxBalance != null && total > _maxBalance!) return false;
      if (_isPositiveBalance != null && (total > 0) != _isPositiveBalance!)
        return false;
      return true;
    }).toList();
  }

  void _showFilterModal() {
    var tmpType = _selectedAccountType;
    var tmpCurr = _selectedCurrency;
    var tmpMin = _minBalance;
    var tmpMax = _maxBalance;
    var tmpPos = _isPositiveBalance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (c, setM) => Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: FilterBottomSheet(
            selectedAccountType: tmpType,
            selectedCurrency: tmpCurr,
            currencyOptions: _currencyOptions,
            minBalance: tmpMin,
            maxBalance: tmpMax,
            isPositiveBalance: tmpPos,
            onChanged: ({accountType, currency, min, max, isPositive}) {
              setM(() {
                tmpType = accountType;
                tmpCurr = currency;
                tmpMin = min;
                tmpMax = max;
                tmpPos = isPositive;
              });
            },
            onReset: () {
              setM(() {
                tmpType = null;
                tmpCurr = null;
                tmpMin = null;
                tmpMax = null;
                tmpPos = null;
              });
            },
            onApply: ({accountType, currency, min, max, isPositive}) {
              setState(() {
                _selectedAccountType = tmpType;
                _selectedCurrency = tmpCurr;
                _minBalance = tmpMin;
                _maxBalance = tmpMax;
                _isPositiveBalance = tmpPos;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccountAction(
      String action, Map<String, dynamic> account, bool isActive) async {
    switch (action) {
      case 'transactions':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionsScreen(account: account),
          ),
        );
        break;
      case 'edit':
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditAccountScreen(accountData: account),
          ),
        );
        if (updated != null) _loadAccounts();
        break;
      case 'deactivate':
        _confirmDeactivate(account);
        break;
      case 'reactivate':
        _confirmReactivate(account);
        break;
      case 'delete':
        _confirmDelete(account, isActive);
        break;
      case 'share':
        await shareAccountBalances(context, account);
        break;
      case 'whatsapp':
        await shareAccountBalances(context, account, viaWhatsApp: true);
        break;
    }
  }

  void _confirmDelete(Map<String, dynamic> account, bool isActive) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        accountName: account['name'],
        onConfirm: () {
          setState(() {
            if (isActive) {
              _activeAccounts.remove(account);
            } else {
              _deactivatedAccounts.remove(account);
            }
            AccountDBHelper().deleteAccount(account['id']);
          });
        },
      ),
    );
  }

  void _confirmDeactivate(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDeactivateDialog(
        accountName: account['name'],
        onConfirm: () {
          setState(() {
            _activeAccounts.remove(account);
            _deactivatedAccounts.add(account);
            AccountDBHelper().deactivateAccount(account['id']);
          });
        },
      ),
    );
  }

  void _confirmReactivate(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (_) => ConfirmReactivateDialog(
        accountName: account['name'],
        onConfirm: () {
          setState(() {
            _deactivatedAccounts.remove(account);
            _activeAccounts.add(account);
            AccountDBHelper().activateAccount(account['id']);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final filteredActive = _applyFilters(_activeAccounts);
    final filteredDeactivated = _applyFilters(_deactivatedAccounts);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        title: _isSearching
            ? CommonSearchBar(
                controller: _searchController,
                debounceDuration: const Duration(milliseconds: 500),
                isLoading: _isLoading,
                hintText: loc.search,
                onChanged: (value) {
                  final query = value.trim();
                  if (query != _searchQuery) {
                    setState(() => _searchQuery = query);
                    _loadAccounts();
                  }
                },
                onCancel: () => setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                  _loadAccounts();
                }),
                onClear: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _loadAccounts();
                }),
                onSubmitted: (_) => _loadAccounts(),
              )
            : Text(loc.accounts, style: const TextStyle(fontSize: 20)),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: cs.primary,
                  tabs: [
                    Tab(text: loc.activeAccounts),
                    Tab(text: loc.deactivatedAccounts)
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      AccountListView(
                        accounts: filteredActive,
                        isActive: true,
                        isLoadingMore: _isLoadingMoreActive,
                        hasMore: _activeHasMore,
                        onLoadMore: _loadMoreActiveAccounts,
                        onRefresh: _loadAccounts,
                        onActionSelected: _handleAccountAction,
                        scrollController: _scrollController,
                      ),
                      AccountListView(
                        accounts: filteredDeactivated,
                        isActive: false,
                        isLoadingMore: _isLoadingMoreDeactivated,
                        hasMore: _deactivatedHasMore,
                        onLoadMore: _loadMoreDeactivatedAccounts,
                        onRefresh: _loadAccounts,
                        onActionSelected: _handleAccountAction,
                        scrollController: _scrollController,
                      )
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAtTop ? _addAccount : _scrollToTop,
        tooltip: _isAtTop
            ? loc.addAccount
            : AppLocalizations.of(context)!.scrollToTop,
        mini: !_isAtTop,
        child: FaIcon(
            _isAtTop ? FontAwesomeIcons.userPlus : FontAwesomeIcons.angleUp,
            size: 18),
      ),
    );
  }

  void _scrollToTop() => _scrollController.animateTo(0,
      duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);

  void _addAccount() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => AddAccountScreen()));
    if (result != null) _loadAccounts();
  }
}
