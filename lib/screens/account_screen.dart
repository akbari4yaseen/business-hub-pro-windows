import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showOptions(BuildContext context) {
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
              _buildOption(Icons.format_list_bulleted, 'Transactions', () {}),
              Divider(),
              _buildOption(Icons.edit, 'Edit', () {}),
              _buildOption(Icons.delete, 'Delete', () {}),
              _buildOption(Icons.block, 'Deactivate', () {}),
              Divider(),
              _buildOption(Icons.share, 'Share Balances', () {}),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(text,
          style: TextStyle(
            fontSize: 16,
          )),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: 16, fontFamily: "IRANSans"),
            tabs: const [
              Tab(text: 'حساب‌های فعال'),
              Tab(text: 'حساب‌های غیرفعال'),
            ],
          ),
          Expanded(
            child: Container(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AccountList(
                      accounts: _activeAccounts,
                      isActive: true,
                      onMoreOptions: _showOptions),
                  AccountList(
                      accounts: _deactivatedAccounts,
                      isActive: false,
                      onMoreOptions: _showOptions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountList extends StatelessWidget {
  final List<Map<String, dynamic>> accounts;
  final bool isActive;
  final Function(BuildContext) onMoreOptions;

  const AccountList({
    required this.accounts,
    required this.isActive,
    required this.onMoreOptions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
                style: const TextStyle(fontSize: 16, fontFamily: "IRANSans")),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${account['account_type']}',
                    style: const TextStyle(fontSize: 14)),
                Text(
                  'Balances: ${account['balances'].entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}').join(', ')}',
                  style: TextStyle(
                      color: isActive ? Colors.green[700] : Colors.red[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            leading: Icon(
                isActive ? Icons.account_circle : Icons.no_accounts_outlined,
                size: 40,
                color: isActive ? Colors.blue : Colors.grey),
            trailing: isActive
                ? IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => onMoreOptions(context))
                : null,
          ),
        );
      },
    );
  }
}

final List<Map<String, dynamic>> _activeAccounts = [
  {
    'name': 'یاسین اکبری',
    'account_type': 'Customer',
    'balances': {'USD': 1500.75, 'EUR': 1300.50}
  },
  {
    'name': 'رحمت الله اکبری',
    'account_type': 'Customer',
    'balances': {'USD': 1500.75, 'EUR': 1300.50}
  },
  {
    'name': 'اسماعیل اکبری',
    'account_type': 'Customer',
    'balances': {'USD': 15000.75, 'EUR': 1300.50}
  },
  {
    'name': 'احمد کریمی',
    'account_type': 'Supplier',
    'balances': {'PKR': 230000.00, 'USD': 450.75}
  },
  {
    'name': 'فرهاد جوادی',
    'account_type': 'Employee',
    'balances': {'AFN': 9800.00}
  },
  {
    'name': 'خزانه',
    'account_type': 'System',
    'balances': {'AFN': 9800.00}
  },
];

final List<Map<String, dynamic>> _deactivatedAccounts = [
  {
    'name': 'امید',
    'account_type': 'Customer',
    'balances': {'USD': 0.00}
  },
  {
    'name': 'کریم امیری',
    'account_type': 'Customer',
    'balances': {'IRR': 0.00, 'EUR': 0.00}
  },
];
