import 'package:BusinessHub/utils/date_time_picker_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../database/account_db.dart';
import '../../database/database_helper.dart';
import '../../utils/transaction_helper.dart';
import '../../utils/utilities.dart';
import '../../providers/info_provider.dart';

import 'transactions_screen.dart';
import 'edit_account_screen.dart';
import 'add_account_screen.dart';
import 'account_filter_bottom_sheet.dart';

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

  List<Map<String, dynamic>> _activeAccounts = [];
  List<Map<String, dynamic>> _deactivatedAccounts = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        final query = _searchController.text.trim();
        if (query != _searchQuery) {
          setState(() => _searchQuery = query);
        }
      });
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_updateScrollPosition);
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
    try {
      final activeRaw = await AccountDBHelper().getActiveAccounts();
      final deactRaw = await AccountDBHelper().getDeactivatedAccounts();
      if (!mounted) return;
      setState(() {
        _activeAccounts = _mapWithBalances(activeRaw);
        _deactivatedAccounts = _mapWithBalances(deactRaw);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
        _shareBalances(account);
        break;
      case 'whatsapp':
        _shareBalances(account, viaWhatsApp: true);
        break;
    }
  }

  void _confirmDelete(Map<String, dynamic> account, bool isActive) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأیید حذف"),
        content: Text(
            "آیا مطمئن هستید که می‌خواهید ${account['name']} را حذف کنید؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("لغو")),
          TextButton(
            onPressed: () {
              setState(() {
                if (isActive) {
                  _activeAccounts.remove(account);
                } else {
                  _deactivatedAccounts.remove(account);
                }
                AccountDBHelper().deleteAccount(account['id']);
              });
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأیید غیرفعالسازی"),
        content: Text(
            "آیا مطمئن هستید که می‌خواهید حساب ${account['name']} را غیرفعال کنید؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("لغو")),
          TextButton(
            onPressed: () {
              setState(() {
                _activeAccounts.remove(account);
                _deactivatedAccounts.add(account);
                AccountDBHelper().deactivateAccount(account['id']);
              });
              Navigator.pop(context);
            },
            child: const Text('غیرفعال کردن حساب',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تأیید فعالسازی مجدد"),
        content:
            Text("آیا می‌خواهید حساب ${account['name']} را دوباره فعال کنید؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("لغو")),
          TextButton(
            onPressed: () {
              setState(() {
                _deactivatedAccounts.remove(account);
                _activeAccounts.add(account);
                AccountDBHelper().activateAccount(account['id']);
              });
              Navigator.pop(context);
            },
            child:
                const Text('فعال‌سازی', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  String _buildShareMessage(Map<String, dynamic> account) {
    final now = DateTime.now();
    final formattedDate = formatLocalizedDateTime(context, now);
    final balances = account['balances'] as Map<String, dynamic>;
    final lines = balances.entries.map((e) {
      final cur = e.value['currency'] ?? e.key;
      final bal = e.value['summary']['balance'] as double? ?? 0.0;
      return '•  $cur: ${NumberFormat('#,###.##').format(bal)}';
    }).join('\n');
    final info = Provider.of<InfoProvider>(context, listen: false).info;
    final footer = info.name ?? 'BusinessHub';
    var msg =
        'Hello *${account['name']}*,\n\n*Current Balances:*\n$lines\n\n*Timestamp:* $formattedDate';
    if (balances.values.any((e) => (e['summary']['balance'] as num) < 0)) {
      msg += '\n\n💡 *Please pay the remaining balance.*';
    }
    return '$msg\n\n---\n$footer';
  }

  Future<void> _shareBalances(Map<String, dynamic> account,
      {bool viaWhatsApp = false}) async {
    final msg = _buildShareMessage(account);
    if (viaWhatsApp) {
      final phone = account['phone'] ?? '';
      if (phone.isEmpty) return;
      final uri =
          Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      await Share.share(msg);
    }
  }

  Widget _buildSearchField(AppLocalizations loc) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: loc.search,
          border: InputBorder.none,
          prefixIcon: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() {
              _isSearching = false;
              _searchController.clear();
              _searchQuery = '';
            }),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  }),
                )
              : null,
        ),
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
            ? _buildSearchField(loc)
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
                      _buildListView(filteredActive, true),
                      _buildListView(filteredDeactivated, false),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAtTop ? _addAccount : _scrollToTop,
        tooltip: _isAtTop ? loc.addAccount : 'Scroll to Top',
        child: FaIcon(
            _isAtTop ? FontAwesomeIcons.userPlus : FontAwesomeIcons.angleUp,
            size: 18),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> accounts, bool isActive) =>
      RefreshIndicator(
        onRefresh: _loadAccounts,
        child: accounts.isEmpty
            ? Center(child: Text("No accounts available"))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 50),
                itemCount: accounts.length,
                itemBuilder: (_, i) => AccountTile(
                  account: accounts[i],
                  isActive: isActive,
                  onActionSelected: (action) =>
                      _handleAccountAction(action, accounts[i], isActive),
                ),
              ),
      );

  void _scrollToTop() => _scrollController.animateTo(0,
      duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);

  void _addAccount() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => AddAccountScreen()));
    if (result != null) _loadAccounts();
  }
}

class AccountTile extends StatelessWidget {
  final Map<String, dynamic> account;
  final bool isActive;
  final void Function(String) onActionSelected;

  const AccountTile(
      {Key? key,
      required this.account,
      required this.isActive,
      required this.onActionSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balances = account['balances'] as Map<String, dynamic>;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        leading: Icon(
          isActive ? Icons.account_circle : Icons.no_accounts_outlined,
          size: 40,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        title: Text(
          account['id'] <= 10
              ? getLocalizedSystemAccountName(context, account['name'])
              : account['name'],
          style: const TextStyle(fontSize: 14, fontFamily: "IRANSans"),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getLocalizedAccountType(context, account['account_type']),
                style: const TextStyle(fontSize: 13)),
            Text('\u200E${account['phone']}',
                style: const TextStyle(fontSize: 13)),
            Text('${account['address']}', style: const TextStyle(fontSize: 13)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: balances.entries.map((e) {
                final bal = e.value['summary']['balance'] as double? ?? 0.0;
                return Text(
                  '\u200E${NumberFormat('#,###.##').format(bal)} ${e.value['currency']}',
                  style: TextStyle(
                    color: bal >= 0 ? Colors.green[700] : Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              onSelected: onActionSelected,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                if (isActive) ...[
                  _buildMenuItem(
                      'transactions', FontAwesomeIcons.listUl, 'معاملات حساب'),
                  if (account['id'] > 10) ...[
                    _buildMenuItem(
                        'edit', FontAwesomeIcons.userPen, 'ویرایش حساب'),
                    _buildMenuItem('deactivate', FontAwesomeIcons.userSlash,
                        'غیرفعال کردن حساب'),
                  ],
                ] else if (account['id'] > 10)
                  _buildMenuItem('reactivate', FontAwesomeIcons.userCheck,
                      'فعال‌سازی مجدد حساب'),
                if (account['id'] > 10)
                  _buildMenuItem('delete', FontAwesomeIcons.trash, 'حذف حساب'),
                _buildMenuItem('share', FontAwesomeIcons.shareNodes,
                    'اشتراک گذاری بیلانس'),
                _buildMenuItem(
                    'whatsapp', FontAwesomeIcons.whatsapp, 'ارسال بیلانس'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        FaIcon(icon, size: 16),
        const SizedBox(width: 8),
        Text(text)
      ]),
    );
  }
}
