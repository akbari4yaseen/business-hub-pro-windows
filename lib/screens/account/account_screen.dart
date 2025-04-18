import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../database/account_db.dart';
import '../../utils/transaction_helper.dart';
import '../../utils/utilities.dart';

import 'transactions_screen.dart';
import 'edit_account_screen.dart';
import 'add_account_screen.dart';
import 'filter_bottom_sheet.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback openDrawer;
  const AccountScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  // Controllers & state
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _searchController;

  bool _isAtTop = true;
  bool _isLoading = true;
  bool _isSearching = false;

  String _searchQuery = '';
  String? _selectedAccountType;
  String? _selectedCurrency;
  double? _minBalance;
  double? _maxBalance;
  bool? _isPositiveBalance;

  List<Map<String, dynamic>> _activeAccounts = [];
  List<Map<String, dynamic>> _deactivatedAccounts = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() => setState(() {}));
    _tabController = TabController(length: 2, vsync: this);
    _loadAccounts();
    _scrollController.addListener(_updateScrollPosition);
  }

  void _updateScrollPosition() {
    if (!mounted) return;
    final atTop = _scrollController.position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the account list back to the top with a smooth animation.
  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadAccounts() async {
    try {
      final activeRaw = await AccountDBHelper().getActiveAccounts();
      final deactRaw = await AccountDBHelper().getDeactivatedAccounts();
      if (!mounted) return;
      setState(() {
        _activeAccounts = activeRaw.map((acct) {
          return {
            ...acct,
            'balances': aggregateTransactions(
              (acct['account_details'] as List? ?? [])
                  .cast<Map<String, dynamic>>(),
            ),
          };
        }).toList();
        _deactivatedAccounts = deactRaw.map((acct) {
          return {
            ...acct,
            'balances': aggregateTransactions(
              (acct['account_details'] as List? ?? [])
                  .cast<Map<String, dynamic>>(),
            ),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading accounts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> list) {
    return list.where((account) {
      // Search text
      if (_searchQuery.isNotEmpty) {
        final name = (account['name'] as String).toLowerCase();
        final addr = (account['address'] as String).toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase()) &&
            !addr.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      // Type
      if (_selectedAccountType != null &&
          _selectedAccountType != 'all' &&
          account['account_type'] != _selectedAccountType) {
        return false;
      }
      // Currency
      final balances = (account['balances'] as Map<String, dynamic>);
      if (_selectedCurrency != null &&
          !balances.keys.contains(_selectedCurrency)) {
        return false;
      }
      // Balance amount
      final total = balances.values
          .fold(0.0, (sum, e) => sum + (e['summary']['balance'] as double));
      if (_minBalance != null && total < _minBalance!) return false;
      if (_maxBalance != null && total > _maxBalance!) return false;
      // Positive / negative
      if (_isPositiveBalance != null) {
        final positive = total > 0;
        if (_isPositiveBalance != positive) return false;
      }
      return true;
    }).toList();
  }

  void _showFilterModal() {
    String? tmpType = _selectedAccountType;
    String? tmpCurr = _selectedCurrency;
    double? tmpMin = _minBalance;
    double? tmpMax = _maxBalance;
    bool? tmpPos = _isPositiveBalance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c2, setModal) => Material(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: FilterBottomSheet(
            selectedAccountType: tmpType,
            selectedCurrency: tmpCurr,
            minBalance: tmpMin,
            maxBalance: tmpMax,
            isPositiveBalance: tmpPos,
            onChanged: ({accountType, currency, min, max, isPositive}) {
              setModal(() {
                tmpType = accountType;
                tmpCurr = currency;
                tmpMin = min;
                tmpMax = max;
                tmpPos = isPositive;
              });
            },
            onReset: () {
              setModal(() {
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

  void _confirmDelete(
      BuildContext context, Map<String, dynamic> account, bool isActive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأیید حذف"),
        content: Text(
            "آیا مطمئن هستید که می‌خواهید ${account['name']} را حذف کنید؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("لغو"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (isActive) {
                  _activeAccounts.remove(account);
                } else {
                  _deactivatedAccounts.remove(account);
                }
                AccountDBHelper().deleteAccount(account["id"]);
              });
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأیید غیرفعالسازی"),
        content: Text(
            "آیا مطمئن هستید که می‌خواهید حساب ${account['name']} را غیرفعال کنید؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("لغو"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _activeAccounts.remove(account);
                _deactivatedAccounts.add(account);
              });
              AccountDBHelper().deactivateAccount(account["id"]);
              Navigator.pop(context);
            },
            child: const Text("غیرفعال کردن",
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(BuildContext context, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأیید فعالسازی مجدد"),
        content:
            Text("آیا می‌خواهید حساب ${account['name']} را دوباره فعال کنید؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("لغو"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _deactivatedAccounts.remove(account);
                _activeAccounts.add(account);
              });
              AccountDBHelper().activateAccount(account["id"]);
              Navigator.pop(context);
            },
            child:
                const Text("فعال‌سازی", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _shareBalances(Map<String, dynamic> account,
      {bool viaWhatsApp = false}) {
    final balances = account['balances'] ?? {};
    if (balances.isEmpty) return;

    final balanceText = balances.entries.map((entry) {
      final currency = entry.value['currency'] ?? entry.key;
      final balance = entry.value['summary']['balance'] ?? 0.0;
      return "$currency: ${NumberFormat('#,###.##').format(balance)}";
    }).join(", ");

    final message = "${account['name']} - Balances:\n$balanceText";

    if (viaWhatsApp) {
      sendWhatsAppMessage(account['phone'] ?? '', message);
    } else {
      _shareText(message);
    }
  }

  Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final fullPhone = cleanedPhone.startsWith('+')
        ? cleanedPhone
        : '+93$cleanedPhone'; // default country

    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse("https://wa.me/$fullPhone?text=$encodedMessage");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Cannot open WhatsApp. Please check installation.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open WhatsApp.')),
      );
    }
  }

  Future<void> _shareText(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share the balance.')),
      );
    }
  }

  Future<void> _editAccount(
      BuildContext context, Map<String, dynamic> account) async {
    final updatedAccount = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(accountData: account),
      ),
    );

    if (updatedAccount != null) {
      _loadAccounts();
    }
  }

  void _addAccount() async {
    final newAccount = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAccountScreen()),
    );

    if (newAccount != null) {
      _loadAccounts();
    }
  }

  void _handleAccountAction(
      String action, Map<String, dynamic> account, bool isActive) {
    switch (action) {
      case 'transactions':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TransactionsScreen(account: account)));
        break;
      case 'edit':
        _editAccount(context, account);
        break;
      case 'deactivate':
        _confirmDeactivate(context, account);
        break;
      case 'reactivate':
        _confirmReactivate(context, account);
        break;
      case 'delete':
        _confirmDelete(context, account, isActive);
        break;
      case 'share':
        _shareBalances(account);
        break;
      case 'whatsapp':
        _shareBalances(account, viaWhatsApp: true);
        break;
    }
  }

  Widget _buildAccountList(List<Map<String, dynamic>> accounts, bool isActive) {
    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: accounts.isEmpty
          ? Center(child: Text("No accounts available"))
          : ListView.builder(
              controller: _scrollController,
              itemCount: accounts.length,

              padding: const EdgeInsets.fromLTRB(
                  0, 5, 0, 50), // Added bottom padding
              itemBuilder: (context, index) {
                final account = accounts[index];
                return AccountTile(
                  account: account,
                  isActive: isActive,
                  onActionSelected: (action) =>
                      _handleAccountAction(action, account, isActive),
                );
              },
            ),
    );
  }

  Widget _buildSearchField(AppLocalizations loc) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: loc.search,
          border: InputBorder.none,
          prefixIcon: IconButton(
            icon: Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchQuery = '';
              });
            },
            splashRadius: 20,
            tooltip: loc.cancel,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  splashRadius: 20,
                  tooltip: loc.clear,
                )
              : null,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
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
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: widget.openDrawer,
          splashRadius: 24,
        ),
        title: _isSearching
            ? _buildSearchField(loc)
            : Text(
                loc.accounts,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(
                Icons.search,
              ),
              onPressed: () => setState(() => _isSearching = true),
              splashRadius: 24,
              tooltip: loc.search,
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
            ),
            onPressed: _showFilterModal,
            splashRadius: 24,
            tooltip: loc.filters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelStyle:
                      const TextStyle(fontSize: 14, fontFamily: "IRANSans"),
                  indicatorColor: cs.primary,
                  tabs: [
                    Tab(text: loc.activeAccounts),
                    Tab(text: loc.deactivatedAccounts),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAccountList(filteredActive, true),
                      _buildAccountList(filteredDeactivated, false),
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
          size: 18,
        ),
        mini: !_isAtTop,
      ),
    );
  }
}

class AccountTile extends StatelessWidget {
  final Map<String, dynamic> account;
  final bool isActive;
  final Function(String) onActionSelected;

  const AccountTile({
    required this.account,
    required this.isActive,
    required this.onActionSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        title: Text(
          account["id"] <= 10
              ? getLocalizedSystemAccountName(context, account['name'])
              : account['name'],
          style: const TextStyle(fontSize: 14, fontFamily: "IRANSans"),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getLocalizedAccountType(context, account['account_type']),
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '\u200E${account['phone']}',
              style: const TextStyle(fontSize: 13),
            ),
            Text('${account['address']}', style: const TextStyle(fontSize: 13)),
          ],
        ),
        leading: Icon(
          isActive ? Icons.account_circle : Icons.no_accounts_outlined,
          size: 40,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: (account['balances'] as Map<String, dynamic>)
                    .entries
                    .map((entry) {
                  final balance = entry.value['summary']['balance'] as double;
                  return Text(
                    '${entry.value['currency']}: ${NumberFormat('#,###.##').format(balance)}',
                    style: TextStyle(
                      color: isActive ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              onSelected: onActionSelected,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) {
                return [
                  if (isActive) ...[
                    PopupMenuItem(
                      value: 'transactions',
                      child: Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.listUl, size: 16),
                          SizedBox(width: 8),
                          Text('معاملات حساب'),
                        ],
                      ),
                    ),
                    if (account['id'] > 10) ...[
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: const [
                            FaIcon(FontAwesomeIcons.userPen, size: 16),
                            SizedBox(width: 8),
                            Text('ویرایش حساب'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deactivate',
                        child: Row(
                          children: const [
                            FaIcon(FontAwesomeIcons.userSlash, size: 16),
                            SizedBox(width: 8),
                            Text('غیرفعال کردن حساب'),
                          ],
                        ),
                      ),
                    ],
                  ] else if (account['id'] > 10)
                    PopupMenuItem(
                      value: 'reactivate',
                      child: Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.userCheck, size: 16),
                          SizedBox(width: 8),
                          Text('فعال‌سازی مجدد حساب'),
                        ],
                      ),
                    ),
                  if (account['id'] > 10)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          FaIcon(FontAwesomeIcons.trash, size: 16),
                          SizedBox(width: 8),
                          Text('حذف حساب'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: const [
                        FaIcon(FontAwesomeIcons.shareNodes, size: 16),
                        SizedBox(width: 8),
                        Text('اشتراک گذاری بیلانس'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: const [
                        FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                        SizedBox(width: 8),
                        Text('ارسال بیلانس'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
