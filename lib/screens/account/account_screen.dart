import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transactions_screen.dart';
import 'edit_account_screen.dart';
import 'add_account_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database/account_db.dart';
import '../../utils/transaction_helper.dart';
import '../../utils/utilities.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'search_filter_bar.dart';
import 'filter_bottom_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;
  bool _isLoading = true;
  bool _showSearchBar = true; // To toggle search bar visibility

  List<Map<String, dynamic>> _activeAccounts = [];
  List<Map<String, dynamic>> _deactivatedAccounts = [];
  // Search and filter parameters
  String _searchQuery = '';
  String? _selectedAccountType;
  String? _selectedCurrency;
  double? _minBalance;
  double? _maxBalance;
  bool? _isPositiveBalance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAccounts();
    _scrollController.addListener(_updateScrollPosition);
  }

  void _updateScrollPosition() {
    if (!mounted) return;
    final atTop = _scrollController.position.pixels <= 0;
    if (atTop != _isAtTop) {
      setState(() {
        _isAtTop = atTop;
        _showSearchBar = atTop; // Hide when at the top
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  // Apply search and filter
  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> accounts) {
    return accounts.where((account) {
      // Filter by name or address
      if (_searchQuery.isNotEmpty &&
          !(account['name']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (account['address']
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))) {
        return false;
      }

      // Filter by account type
      if (_selectedAccountType != null &&
          _selectedAccountType != 'all' &&
          account['account_type'] != _selectedAccountType) {
        return false;
      }

      // Filter by currency
      if (_selectedCurrency != null &&
          !(account['balances'] as Map<String, dynamic>)
              .keys
              .contains(_selectedCurrency)) {
        return false;
      }

      // Filter by balance amount
      double balanceAmount = (account['balances'] as Map<String, dynamic>)
          .values
          .fold(0.0, (sum, e) => sum + (e['summary']['balance'] as double));
      if (_minBalance != null && balanceAmount < _minBalance!) {
        return false;
      }
      if (_maxBalance != null && balanceAmount > _maxBalance!) {
        return false;
      }

      // Filter by positive or negative balances
      if (_isPositiveBalance != null) {
        bool isPositive = balanceAmount > 0;
        if (_isPositiveBalance != isPositive) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildFilterOption<T>({
    required String title,
    required List<T> options,
    required T? selected,
    required void Function(T?) onSelected,
  }) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Wrap(
          spacing: 10,
          children: options.map((option) {
            return ChoiceChip(
              label: Text(option.toString()),
              selected: selected == option,
              onSelected: (selected) => onSelected(selected ? option : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Show filter modal
  void _showFilterModal(searchText) {
    String? tempAccountType = _selectedAccountType;
    String? tempCurrency = _selectedCurrency;
    double? tempMinBalance = _minBalance;
    double? tempMaxBalance = _maxBalance;
    bool? tempIsPositiveBalance = _isPositiveBalance;
    String tempSearch = _searchQuery;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Material(
              color: Theme.of(context).canvasColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: FilterBottomSheet(
                selectedAccountType: tempAccountType,
                selectedCurrency: tempCurrency,
                minBalance: tempMinBalance,
                maxBalance: tempMaxBalance,
                isPositiveBalance: tempIsPositiveBalance,
                onChanged: (
                    {String? accountType,
                    String? currency,
                    double? min,
                    double? max,
                    bool? isPositive}) {
                  modalSetState(() {
                    if (accountType != null) tempAccountType = accountType;
                    if (currency != null) tempCurrency = currency;
                    if (min != null || min == null) tempMinBalance = min;
                    if (max != null || max == null) tempMaxBalance = max;
                    if (isPositive != null) tempIsPositiveBalance = isPositive;
                  });
                  // Instant search/filter update
                  setState(() {
                    _searchQuery = tempSearch;
                    _selectedAccountType = tempAccountType;
                    _selectedCurrency = tempCurrency;
                    _minBalance = tempMinBalance;
                    _maxBalance = tempMaxBalance;
                    _isPositiveBalance = tempIsPositiveBalance;
                  });
                },
                onReset: () {
                  modalSetState(() {
                    tempAccountType = null;
                    tempCurrency = null;
                    tempMinBalance = null;
                    tempMaxBalance = null;
                    tempIsPositiveBalance = null;
                  });
                  setState(() {
                    _selectedAccountType = null;
                    _selectedCurrency = null;
                    _minBalance = null;
                    _maxBalance = null;
                    _isPositiveBalance = null;
                  });
                },
                onApply: (
                    {String? accountType,
                    String? currency,
                    double? min,
                    double? max,
                    bool? isPositive}) {
                  setState(() {
                    _searchQuery = tempSearch;
                    _selectedAccountType = tempAccountType;
                    _selectedCurrency = tempCurrency;
                    _minBalance = tempMinBalance;
                    _maxBalance = tempMaxBalance;
                    _isPositiveBalance = tempIsPositiveBalance;
                  });
                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadAccounts() async {
    try {
      final List<Map<String, dynamic>> activeRawAccounts =
          await AccountDBHelper().getActiveAccounts();
      final List<Map<String, dynamic>> deactivatedRawAccounts =
          await AccountDBHelper().getDeactivatedAccounts();
      if (mounted) {
        setState(() {
          _activeAccounts = activeRawAccounts.map((account) {
            return {
              ...account,
              'balances': aggregateTransactions(
                (account['account_details'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [],
              ),
            };
          }).toList();
        });
      }
      if (mounted) {
        setState(() {
          _deactivatedAccounts = deactivatedRawAccounts.map((account) {
            return {
              ...account,
              'balances': aggregateTransactions(
                (account['account_details'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [],
              ),
            };
          }).toList();
        });
      }
    } catch (e) {
      print("Error loading accounts: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    List<Map<String, dynamic>> filteredActiveAccounts =
        _applyFilters(_activeAccounts);
    List<Map<String, dynamic>> filteredDeactivatedAccounts =
        _applyFilters(_deactivatedAccounts);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showSearchBar)
                  SearchFilterBar(
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        filteredActiveAccounts = _applyFilters(_activeAccounts);
                        filteredDeactivatedAccounts =
                            _applyFilters(_deactivatedAccounts);
                      });
                    },
                    onFilterPressed: () {
                      _showFilterModal(_searchQuery);
                    },
                  ),

                // Tabs for Active & Deactivated Accounts
                TabBar(
                  controller: _tabController,
                  labelStyle:
                      const TextStyle(fontSize: 14, fontFamily: "IRANSans"),
                  tabs: [
                    Tab(text: localizations.activeAccounts),
                    Tab(text: localizations.deactivatedAccounts),
                  ],
                ),

                // Account List with Search and Filter Applied
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAccountList(filteredActiveAccounts, true),
                      _buildAccountList(filteredDeactivatedAccounts, false),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAtTop ? _addAccount : _scrollToTop,
        tooltip: _isAtTop ? 'Add Account' : 'Scroll to Top',
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
            style: const TextStyle(fontSize: 14, fontFamily: "IRANSans")),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${getLocalizedAccountType(context, account['account_type'])}',
                style: const TextStyle(fontSize: 13)),
            Text(
              '\u200E${account['phone']}', // Add the LRM character before the phone number
              style: const TextStyle(fontSize: 13),
            ),
            Text('${account['address']}', style: const TextStyle(fontSize: 13)),
          ],
        ),
        leading: Icon(
            isActive ? Icons.account_circle : Icons.no_accounts_outlined,
            size: 40,
            color: isActive ? Colors.blue : Colors.grey),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: (account['balances'] as Map<String, dynamic>)
                      .entries
                      .map((entry) {
                    return Text(
                      '${entry.value['currency']}: ${NumberFormat('#,###.##').format(entry.value['summary']['balance'])}',
                      style: TextStyle(
                        color: isActive ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              onSelected: onActionSelected,
              itemBuilder: (BuildContext context) {
                return [
                  if (isActive) ...[
                    PopupMenuItem(
                      value: 'transactions',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.listUl, size: 16),
                          SizedBox(width: 8),
                          Text('معاملات حساب'),
                        ],
                      ),
                    ),
                    if (account['id'] > 10) ...[
                      // Prevent edit, delete, deactivate for IDs <= 10
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.userPen,
                                size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('ویرایش حساب'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deactivate',
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.userSlash, size: 16),
                            SizedBox(width: 8),
                            Text('غیرفعال کردن حساب'),
                          ],
                        ),
                      ),
                    ],
                  ] else if (account['id'] >
                      10) // Prevent reactivation for IDs <= 10
                    PopupMenuItem(
                      value: 'reactivate',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.userCheck, size: 16),
                          SizedBox(width: 8),
                          Text('فعال‌سازی مجدد حساب'),
                        ],
                      ),
                    ),
                  if (account['id'] > 10) // Prevent delete for IDs <= 10
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.trash,
                              size: 16, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('حذف حساب'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.shareNodes, size: 16),
                        SizedBox(width: 8),
                        Text('اشتراک گذاری بیلانس'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                        SizedBox(width: 8),
                        Text('ارسال بیلانس'),
                      ],
                    ),
                  ),
                ];
              },
              icon: Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }
}
