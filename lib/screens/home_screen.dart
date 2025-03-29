import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/bottom_navigation_provider.dart';
import '../database/account_db.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/utilities.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    fetchRecentTransactions();
  }

  Future<void> fetchRecentTransactions() async {
    List<Map<String, dynamic>> transactions =
        await AccountDBHelper().getRecentTransactions(5);
    setState(() {
      recentTransactions = transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    int daysSinceLastBackup = 10;
    bool isBackupOverdue = daysSinceLastBackup > 7;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard(
                    'موجودی', '\$12,500', Icons.account_balance_wallet),
                _buildSummaryCard('فاکتورها', '25', Icons.receipt_long),
                _buildSummaryCard('هزینه‌ها', '\$3,200', Icons.money_off),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton('معامله جدید', Icons.add,
                    () => Navigator.pushNamed(context, '/journal/add')),
                _buildActionButton('حساب‌ها', Icons.supervisor_account_outlined,
                    () {
                  Provider.of<BottomNavigationProvider>(context, listen: false)
                      .updateIndex(2);
                }),
                _buildActionButton('گزارش‌ها', Icons.bar_chart, () {
                  Provider.of<BottomNavigationProvider>(context, listen: false)
                      .updateIndex(3);
                }),
                _buildActionButton('تنظیمات', Icons.settings,
                    () => Navigator.pushNamed(context, '/settings')),
              ],
            ),
            const SizedBox(height: 16),
            _buildBackupCard(daysSinceLastBackup, isBackupOverdue),
            const SizedBox(height: 20),
            const Text('تراکنش‌های اخیر',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
                child: Column(children: [
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: recentTransactions.isNotEmpty
                    ? recentTransactions
                        .asMap()
                        .entries
                        .map((entry) => _buildTransactionTile(entry.value,
                            entry.key == recentTransactions.length - 1))
                        .toList()
                    : [const Center(child: Text('No recent transactions'))],
              ),
            ]))
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction, bool isLast) {
    IconData icon = transaction['transaction_type'] == 'credit'
        ? FontAwesomeIcons.plus
        : FontAwesomeIcons.minus;
    Color color =
        transaction['transaction_type'] == 'credit' ? Colors.green : Colors.red;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            children: [
              // Icon with background
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['account_name'],
                      style: const TextStyle(fontFamily: "IRANsans"),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatJalaliDate(transaction['date']),
                    ),
                    Text(
                      transaction['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '${NumberFormat('#,###').format(transaction['amount'])} ${transaction['currency']}',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(), // Add divider only if it's NOT the last transaction
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback action) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: action,
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildBackupCard(int daysSinceLastBackup, bool isBackupOverdue) {
    return Card(
      elevation: 4,
      color: isBackupOverdue ? Colors.red[100] : Colors.green[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup,
                    size: 30,
                    color: isBackupOverdue ? Colors.red : Colors.green),
                const SizedBox(width: 10),
                const Text('پشتیبان‌گیری پایگاه داده',
                    style: TextStyle(fontSize: 18, fontFamily: "IRANSans")),
              ],
            ),
            const SizedBox(height: 8),
            Text('آخرین پشتیبان‌گیری: $daysSinceLastBackup روز قبل',
                style: TextStyle(
                    fontSize: 16,
                    color: isBackupOverdue ? Colors.red : Colors.black)),
            if (isBackupOverdue)
              const Text('⚠ لطفاً پشتیبان‌گیری جدید بگیرید!',
                  style: TextStyle(
                      fontSize: 16, color: Colors.red, fontFamily: "IRANSans")),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement backup functionality
              },
              icon: const Icon(Icons.backup_outlined),
              label: const Text('پشتیبان‌گیری'),
            ),
          ],
        ),
      ),
    );
  }
}
