import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int daysSinceLastBackup = 10; // Example: Change dynamically
    bool isBackupOverdue =
        daysSinceLastBackup > 7; // Warn if backup older than 7 days

    return Scaffold(
      body: SingleChildScrollView(
        // ✅ Makes the whole screen scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Summary Cards
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

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton('معامله جدید', Icons.add),
                  _buildActionButton(
                      'حساب‌ها', Icons.supervisor_account_outlined),
                  _buildActionButton('گزارش‌ها', Icons.bar_chart),
                  _buildActionButton('تنظیمات', Icons.settings),
                ],
              ),

              const SizedBox(height: 16),

              // Backup Section
              _buildBackupCard(daysSinceLastBackup, isBackupOverdue),

              const SizedBox(height: 16),

              // Recent Transactions
              const Text('تراکنش‌های اخیر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListView(
                shrinkWrap: true, // ✅ Allows ListView inside ScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // ✅ Prevents inner scroll conflicts
                children: const [
                  ListTile(
                    leading: Icon(Icons.shopping_cart, color: Colors.red),
                    title: Text('خرید از فروشگاه'),
                    subtitle: Text('۲۰۲۵/۰۳/۰۹'),
                    trailing: Text('-\$120'),
                  ),
                  ListTile(
                    leading: Icon(Icons.payments, color: Colors.green),
                    title: Text('دریافت پرداخت'),
                    subtitle: Text('۲۰۲۵/۰۳/۰۸'),
                    trailing: Text('+\$500'),
                  ),
                  ListTile(
                    leading: Icon(Icons.restaurant, color: Colors.orange),
                    title: Text('رستوران'),
                    subtitle: Text('۲۰۲۵/۰۳/۰۷'),
                    trailing: Text('-\$45'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Summary Card Widget
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

  // Quick Action Button Widget
  Widget _buildActionButton(String label, IconData icon) {
    return Column(
      children: [
        FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // Backup Card Widget
  Widget _buildBackupCard(int daysSinceLastBackup, bool isBackupOverdue) {
    return Card(
      elevation: 4,
      color: isBackupOverdue
          ? Colors.red[100]
          : Colors.green[100], // Warning Color
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
              const Text(
                '⚠ لطفاً پشتیبان‌گیری جدید بگیرید!',
                style: TextStyle(
                    fontSize: 16, color: Colors.red, fontFamily: "IRANSans"),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                // ElevatedButton.icon(
                //   onPressed: () {
                //     // TODO: Implement Google Drive backup functionality
                //   },
                //   icon: const Icon(Icons.cloud_upload),
                //   label: const Text('پشتیبان‌گیری آنلاین'),
                //   style: ElevatedButton.styleFrom(foregroundColor: Colors.blue),
                // ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement backup functionality
                  },
                  icon: const Icon(Icons.backup_outlined),
                  label: const Text('پشتیبان‌گیری'),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
