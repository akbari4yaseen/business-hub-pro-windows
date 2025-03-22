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

  // Show filter modal
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Account Type Filter
                  ExpansionTile(
                    title: Text("Account Type"),
                    children: [
                      Wrap(
                        spacing: 10,
                        children: [
                          "all",
                          "system",
                          "customer",
                          "supplier",
                          "exchanger"
                        ].map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: _selectedAccountType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedAccountType = selected ? type : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Currency Filter
                  ExpansionTile(
                    title: Text("Currency"),
                    children: [
                      Wrap(
                        spacing: 10,
                        children:
                            ["USD", "EUR", "PKR", "IRR", "AFN"].map((currency) {
                          return ChoiceChip(
                            label: Text(currency),
                            selected: _selectedCurrency == currency,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCurrency = selected ? currency : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Balance Amount Filter
                  ExpansionTile(
                    title: Text("Balance Amount"),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: "Min"),
                              onChanged: (value) {
                                setState(() {
                                  _minBalance = double.tryParse(value);
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: "Max"),
                              onChanged: (value) {
                                setState(() {
                                  _maxBalance = double.tryParse(value);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Positive/Negative Balance Filter
                  ExpansionTile(
                    title: Text("Balance Type"),
                    children: [
                      Wrap(
                        spacing: 10,
                        children: [
                          ChoiceChip(
                            label: Text("Positive"),
                            selected: _isPositiveBalance == true,
                            onSelected: (selected) {
                              setState(() {
                                _isPositiveBalance = selected ? true : null;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text("Negative"),
                            selected: _isPositiveBalance == false,
                            onSelected: (selected) {
                              setState(() {
                                _isPositiveBalance = selected ? false : null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Apply Filters Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: Text("Apply Filters"),
                  ),
                ],
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
    final balances = account['balances'] ?? {'USD': 0.00};
    final balanceText = balances.entries
        .map((e) => "${e.key}: ${NumberFormat('#,###.##').format(e.value)}")
        .join(", ");

    final message = "${account['name']} - Balances: $balanceText";

    if (viaWhatsApp) {
      sendWhatsAppMessage(account['phone'], message);
    } else {
      Share.share(message);
    }
  }

  Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
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
                  onActionSelected: (action) {
                    switch (action) {
                      case 'transactions':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransactionsScreen(account: account),
                          ),
                        );
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
                  },
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
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onFilterPressed: _showFilterModal,
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
        child: FaIcon(
          size: 18,
          _isAtTop ? FontAwesomeIcons.userPlus : FontAwesomeIcons.angleUp,
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
