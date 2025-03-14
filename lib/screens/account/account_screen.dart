import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transactions_screen.dart';
import 'edit_account_screen.dart';
import 'add_account_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database//database_helper.dart';
import '../../utils/transaction_helper.dart';

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
  bool _isLoading = false;

  List<Map<String, dynamic>> _activeAccounts = [];
  List<Map<String, dynamic>> _deactivatedAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAccounts();

    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _isAtTop = _scrollController.position.pixels <= 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  void _showOptions(
      BuildContext context, Map<String, dynamic> account, bool isActive) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                _buildOption(FontAwesomeIcons.listUl, 'معاملات حساب', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TransactionsScreen(account: account)),
                  );
                }),
              if (isActive) Divider(),
              if (isActive)
                _buildOption(FontAwesomeIcons.userPen, 'ویرایش حساب', () {
                  _editAccount(context, account);
                }),
              if (isActive)
                _buildOption(FontAwesomeIcons.userSlash, 'غیرفعال کردن حساب',
                    () {
                  _confirmDeactivate(context, account);
                }),
              if (!isActive)
                _buildOption(FontAwesomeIcons.userCheck, 'فعال‌سازی مجدد حساب',
                    () {
                  _confirmReactivate(context, account);
                }),
              _buildOption(FontAwesomeIcons.trash, 'حذف حساب', () {
                _confirmDelete(context, account, isActive);
              }),
              Divider(),
              _buildOption(FontAwesomeIcons.shareNodes, 'اشتراک گذاری بیلانس',
                  () {
                _shareBalances(account);
              }),
              _buildOption(FontAwesomeIcons.whatsapp, 'ارسال بیلانس', () {
                _shareBalances(account, viaWhatsApp: true);
              }),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, Map<String, dynamic> account, bool isActive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأیید حذف"),
        content: Text(
            "آیا مطمئن هستید که می‌خواهید ${account['name']} را حذف کنید؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("لغو"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (isActive) {
                  _activeAccounts.remove(account);
                } else {
                  _deactivatedAccounts.remove(account);
                }
              });
              Navigator.pop(context);
            },
            child: Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأیید غیرفعالسازی"),
        content: Text(
            "آیا مطمئن هستید که می‌خواهید حساب ${account['name']} را غیرفعال کنید؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("لغو"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _activeAccounts.remove(account);
                _deactivatedAccounts.add(account);
              });
              Navigator.pop(context);
              Navigator.pop(context); // Close bottom sheet
            },
            child: Text("غیرفعال کردن", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmReactivate(BuildContext context, Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأیید فعالسازی مجدد"),
        content:
            Text("آیا می‌خواهید حساب ${account['name']} را دوباره فعال کنید؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("لغو"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _deactivatedAccounts.remove(account);
                _activeAccounts.add(account);
              });
              Navigator.pop(context);
              Navigator.pop(context); // Close bottom sheet
            },
            child: Text("فعال‌سازی", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void sendWhatsAppMessage(String phoneNumber, String message) async {
    // Create the WhatsApp URL
    final url =
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    // Try to launch the URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _shareBalances(Map<String, dynamic> account,
      {bool viaWhatsApp = false}) {
    Map<String, dynamic> balances =
        account['balances'] ?? {}; // Ensure balances is not null

    if (balances.isEmpty) {
      balances = {'USD': 0.00}; // Provide a default balance
    }

    String balanceText = balances.entries
        .map((e) => "${e.key}: ${NumberFormat('#,###.##').format(e.value)}")
        .join(", ");

    String message = "${account['name']} - Balances: $balanceText";

    if (viaWhatsApp) {
      sendWhatsAppMessage(account['phone'], message);
    } else {
      Share.share(message);
    }
  }

  void _editAccount(BuildContext context, Map<String, dynamic> account) async {
    final updatedAccount = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(account: account),
      ),
    );

    if (updatedAccount != null) {
      _loadAccounts();
    }
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    final List<Map<String, dynamic>> rawAccounts =
        await DatabaseHelper().getActiveAccounts();

    setState(() {
      _activeAccounts = rawAccounts.map((account) {
        return {
          ...account,
          'balances': aggregateTransactions(
            (account['account_details'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [],
          ),
        };
      }).toList();
      _isLoading = false;
    });
  }

  Widget _buildOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: FaIcon(
        icon,
        size: 16,
      ),
      title: Text(text, style: TextStyle(fontSize: 16)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    );
  }

  void _addAccount() async {
    final newAccount = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAccountScreen()),
    );

    if (newAccount != null) {
      _loadAccounts(); // Refresh list after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: 14, fontFamily: "IRANSans"),
            tabs: const [
              Tab(text: 'حساب‌های فعال'),
              Tab(text: 'حساب‌های غیرفعال'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAccounts,
                        child: AccountList(
                          accounts: _activeAccounts,
                          isActive: true,
                          onMoreOptions: _showOptions,
                          scrollController: _scrollController,
                        ),
                      ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadAccounts,
                        child: AccountList(
                          accounts: _deactivatedAccounts,
                          isActive: false,
                          onMoreOptions: _showOptions,
                          scrollController: _scrollController,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAtTop ? _addAccount : _scrollToTop,
        child: FaIcon(
            size: 18,
            _isAtTop ? FontAwesomeIcons.userPlus : FontAwesomeIcons.angleUp),
        mini: !_isAtTop,
      ),
    );
  }
}

class AccountList extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final bool isActive;
  final Function(BuildContext, Map<String, dynamic>, bool) onMoreOptions;
  final ScrollController scrollController;

  const AccountList({
    required this.accounts,
    required this.isActive,
    required this.onMoreOptions,
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: accounts.length,
      padding: const EdgeInsets.symmetric(vertical: 5),
      itemBuilder: (context, index) {
        final account = accounts[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            title: Text(account['name'],
                style: const TextStyle(fontSize: 14, fontFamily: "IRANSans")),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${account['account_type']}',
                    style: const TextStyle(fontSize: 13)),
                Text(
                  '${account['phone']}',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
                Text('${account['address']}',
                    style: const TextStyle(fontSize: 13)),
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
                            color:
                                isActive ? Colors.green[700] : Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => onMoreOptions(context, account, isActive),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
