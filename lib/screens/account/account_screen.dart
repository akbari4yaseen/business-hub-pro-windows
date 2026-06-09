import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:BusinessHubPro/localization/app_localizations.dart';

import 'transactions/transactions_screen.dart';
import 'print_accounts.dart';

import '../../database/account_db.dart';
import '../../database/database_helper.dart';
import '../../utils/transaction_helper.dart';
import '../../utils/account_types.dart';
import '../../utils/account_share_helper.dart';
import '../../widgets/account/account_filter_dialog.dart';
import '../../widgets/account/account_action_dialogs.dart';
import '../../widgets/account/account_list_view.dart';
import '../../widgets/search_bar.dart';
import '../../widgets/auth_widget.dart';
import '../../utils/search_manager.dart';
import '../../widgets/account/account_form_dialog.dart';
import '../../themes/app_theme.dart';
import '../../utils/utilities.dart';

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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

  bool get _hasActiveFilters =>
      (_selectedAccountType != null && _selectedAccountType != 'all') ||
      (_selectedCurrency != null && _selectedCurrency != 'all');

  List<Map<String, dynamic>> get _currentAccounts =>
      _tabController.index == 0 ? _activeAccounts : _deactivatedAccounts;

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
        builder: (c, setM) => AccountFilterBottomDialog(
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
                await AccountDBHelper()
                    .updateAccount(account['id'], accountData);
                Navigator.of(dialogContext).pop(accountData);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.existsAccountError),
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
            : _buildTitle(loc),
        actions: _buildActions(loc),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(loc.activeAccounts),
                  if (_activeAccounts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _tabBadge('${_activeAccounts.length}'),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(loc.deactivatedAccounts),
                  if (_deactivatedAccounts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _tabBadge('${_deactivatedAccounts.length}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: _isLoading && _activeAccounts.isEmpty && _deactivatedAccounts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                  ],
                ),
              )
            : Column(
                children: [
                  if (_hasActiveFilters) _buildActiveFiltersBar(loc),
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts_add_fab',
        onPressed: _addAccount,
        tooltip: loc.addAccount,
        icon: const FaIcon(FontAwesomeIcons.userPlus, size: 18),
        label: Text(loc.addAccount),
      ),
    );
  }

  Widget _buildTitle(AppLocalizations loc) {
    return Row(
      children: [
        Icon(Icons.people, size: 24, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          loc.accounts,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'VazirBold',
          ),
        ),
        if (_currentAccounts.isNotEmpty) ...[
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentAccounts.length}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(AppLocalizations loc) {
    if (_isSearching) return [];

    return [
      if (_hasActiveFilters)
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 4),
              Text(
                loc.activeFilters,
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _isLoading ? null : _loadAccounts,
        tooltip: loc.refresh,
      ),
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearching = true),
        tooltip: loc.search,
      ),
      IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: loc.filter,
        onPressed: _showFilterModal,
      ),
      IconButton(
        icon: const Icon(Icons.print_outlined),
        tooltip: loc.print,
        onPressed: _showPrintModal,
      ),
      const SizedBox(width: 8),
    ];
  }

  Widget _tabBadge(String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar(AppLocalizations loc) {
    final chips = <Widget>[];

    if (_selectedAccountType != null && _selectedAccountType != 'all') {
      chips.add(_filterChip(
        label: getLocalizedAccountType(context, _selectedAccountType!),
        onRemove: () {
          setState(() => _selectedAccountType = null);
          _loadAccounts();
        },
      ));
    }

    if (_selectedCurrency != null && _selectedCurrency != 'all') {
      chips.add(_filterChip(
        label: _selectedCurrency!,
        onRemove: () {
          setState(() => _selectedCurrency = null);
          _loadAccounts();
        },
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${loc.activeFilters}:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          ...chips,
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedAccountType = null;
                _selectedCurrency = null;
              });
              _loadAccounts();
            },
            icon: const Icon(Icons.clear_all, size: 16),
            label: Text(loc.reset),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      labelStyle: TextStyle(
        color: AppTheme.primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

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
                  content:
                      Text(AppLocalizations.of(context)!.existsAccountError),
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
