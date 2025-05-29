import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'transactions/transactions_screen.dart';
// import 'edit_account_screen.dart';
// import 'add_account_screen.dart';
import 'print_accounts.dart';

import '../../database/account_db.dart';
import '../../database/database_helper.dart';
import '../../utils/transaction_helper.dart';
import '../../utils/account_types.dart';
import '../../utils/account_share_helper.dart';
import '../../widgets/account/account_filter_bottom_sheet.dart';
import '../../widgets/account/account_action_dialogs.dart';
import '../../widgets/account/account_list_view.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/auth_widget.dart';
import '../../utils/search_manager.dart';
import '../../widgets/account/account_form_dialog.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  // Controllers & State
  late final TabController _tabController;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;
  late final SearchManager _searchManager;

  bool _isAtTop = true;
  bool _isLoading = true;
  bool _isSearching = false;

  String _searchQuery = '';
  String? _selectedAccountType;
  String? _selectedCurrency;

  List<String> _currencyOptions = [];
  bool _currenciesLoaded = false;

  // Pagination state for active accounts
  List<Map<String, dynamic>> _activeAccounts = [];
  int _activeOffset = 0;
  final int _limit = 20;
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
    _searchManager = SearchManager();
    _searchController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_updateScrollPosition);
    _scrollController.addListener(_onScroll);
    _searchManager.searchStream.listen((searchState) {
      setState(() {
        _searchQuery = searchState.query;
        if (_tabController.index == 0) {
          _activeAccounts = searchState.results;
        } else {
          _deactivatedAccounts = searchState.results;
        }
      });
    });
    _loadAccounts();
    _loadCurrencies();
  }

  @override
  void dispose() {
    _searchManager.dispose();
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
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _activeAccounts = [];
      _deactivatedAccounts = [];
      _activeOffset = 0;
      _deactivatedOffset = 0;
      _activeHasMore = true;
      _deactivatedHasMore = true;
    });

    try {
      await Future.wait([
        _loadMoreActiveAccounts(reset: true),
        _loadMoreDeactivatedAccounts(reset: true),
      ]);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreActiveAccounts({bool reset = false}) async {
    if (_isLoadingMoreActive || !_activeHasMore) return;
    setState(() => _isLoadingMoreActive = true);
    try {
      final offset = reset ? 0 : _activeOffset;
      final accounts = await AccountDBHelper().getAccountsPage(
        offset: offset,
        limit: _limit,
        isActive: true,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        accountType: _selectedAccountType,
        currency: _selectedCurrency,
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
      final accounts = await AccountDBHelper().getAccountsPage(
        offset: offset,
        limit: _limit,
        isActive: false,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        accountType: _selectedAccountType,
        currency: _selectedCurrency,
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

    final threshold = 200.0;
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;

    // only load if scrolled within threshold AND not already loading
    if (max - pos <= threshold) {
      if (_tabController.index == 0) {
        if (!_isLoadingMoreActive && _activeHasMore) {
          _loadMoreActiveAccounts();
        }
      } else {
        if (!_isLoadingMoreDeactivated && _deactivatedHasMore) {
          _loadMoreDeactivatedAccounts();
        }
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
              'balances': aggregateTransactions(acct['account_details'])
            })
        .toList();
  }

  Future<void> _showPrintModal() async {
    final loc = AppLocalizations.of(context)!;
    // getAccountTypes returns a Map<key,label>
    final typesMap = getAccountTypes(loc);

    // build a List<String> so we can prepend "all"
    final types = ['all', ...typesMap.keys];

    String selectedType = 'all';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.accountType),
        content: StatefulBuilder(
          builder: (context, setState) => DropdownButton<String>(
            value: selectedType,
            isExpanded: true,
            items: types.map((t) {
              final label = (t == 'all') ? loc.all : typesMap[t]!;
              return DropdownMenuItem<String>(
                value: t,
                child: Text(label),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => selectedType = val);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: Text(loc.print),
            onPressed: () async {
              Navigator.of(context).pop();
              final accountsToPrint = await AccountDBHelper()
                  .getAccountsForPrint(accountType: selectedType);
              PrintAccounts.printAccounts(context, accountsToPrint);
            },
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    var tmpType = _selectedAccountType;
    var tmpCurr = _selectedCurrency;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, setM) => Dialog(
          child: FilterBottomSheet(
            selectedAccountType: tmpType,
            selectedCurrency: tmpCurr,
            currencyOptions: _currencyOptions,
            onChanged: ({accountType, currency}) {
              setM(() {
                if (accountType != null) tmpType = accountType;
                if (currency != null) tmpCurr = currency;
              });
            },
            onReset: () {
              setM(() {
                tmpType = null;
                tmpCurr = null;
              });
            },
            onApply: ({accountType, currency}) {
              setState(() {
                _selectedAccountType = tmpType;
                _selectedCurrency = tmpCurr;
              });
              Navigator.pop(context);
              _loadAccounts();
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
        if (!mounted) return;
        
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) => AccountFormDialog(
            accountData: account,
            onSave: (accountData) async {
              try {
                await AccountDBHelper().updateAccount(account['id'], accountData);
                Navigator.of(dialogContext).pop(accountData);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.existsAccountError),
                    ),
                  );
                }
              }
            },
          ),
        );
        
        if (result != null && mounted) {
          await _loadAccounts();
        }
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
      case 'call':
        await launchAccountCall(context, account['phone'] as String?);
        break;
    }
  }

  void _confirmDelete(Map<String, dynamic> account, bool isActive) {
    showDialog(
      context: context,
      builder: (_) => AuthWidget(
        actionReason: AppLocalizations.of(context)!.deleteAccountAuthMessage,
        onAuthenticated: () {
          Navigator.of(context).pop(); // Close the AuthWidget dialog
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

    return Scaffold(
      appBar: AppBar(
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
                onSubmitted: (_) => _loadAccounts(),
              )
            : Text(loc.accounts, style: const TextStyle(fontSize: 20)),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              tooltip: loc.search,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  _showFilterModal();
                  break;
                case 'print':
                  _showPrintModal();
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
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.activeAccounts),
            Tab(text: loc.deactivatedAccounts)
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      AccountListView(
                        accounts: _activeAccounts,
                        isActive: true,
                        isLoadingMore: _isLoadingMoreActive,
                        hasMore: _activeHasMore,
                        onLoadMore: _loadMoreActiveAccounts,
                        onRefresh: _loadAccounts,
                        onActionSelected: _handleAccountAction,
                        scrollController: _scrollController,
                      ),
                      AccountListView(
                        accounts: _deactivatedAccounts,
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
        heroTag: 'accounts_add_fab',
        onPressed: _isAtTop ? _addAccount : _scrollToTop,
        tooltip: _isAtTop
            ? AppLocalizations.of(context)!.addAccount
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
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AccountFormDialog(
        onSave: (accountData) async {
          try {
            await AccountDBHelper().insertAccount(accountData);
            Navigator.of(dialogContext).pop(accountData);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.existsAccountError),
                ),
              );
            }
          }
        },
      ),
    );
    
    if (result != null && mounted) {
      await _loadAccounts();
    }
  }
}
