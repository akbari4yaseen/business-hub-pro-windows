import 'account_reports_screen.dart';
import 'package:flutter/material.dart';
import 'system_account_reports_screen.dart';
import 'daily_balances_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'periodic_reports_screen.dart';
import 'purchase_reports_screen.dart';
import 'sales_reports_screen.dart';
import 'stock_movement_reports_screen.dart';
import 'stock_value_reports_screen.dart';
import 'financial_balance_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reports),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text(loc.dailyBalances),
              subtitle: Text(loc.dailyBalancesDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DailyBalancesChart(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(loc.financialBalance),
              subtitle: Text(loc.financialBalanceDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FinancialBalanceScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timeline),
              title: Text(loc.periodicReports),
              subtitle: Text(loc.periodicReportsDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PeriodicReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text(loc.accountReports),
              subtitle: Text(loc.accountReportsDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: Text(loc.systemAccountReports),
              subtitle: Text(loc.systemAccountReportsDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SystemAccountReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: Text(loc.purchaseReports),
              subtitle: Text(loc.purchaseReportsDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PurchaseReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt),
              title: Text(loc.salesReports),
              subtitle: Text(loc.salesReportsDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SalesReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(loc.stockMovementReports),
              subtitle: Text(loc.stockMovementReportsDesc),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StockMovementReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assessment),
              title: Text(loc.stockValueReports ?? 'Stock Value Reports'),
              subtitle: Text(loc.stockValueReportsDesc ??
                  'View current stock values with pricing and summaries'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StockValueReportsScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pie_chart),
              title: Text(loc.moreVisualizations),
              subtitle: Text(loc.moreVisualizationsDesc),
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }
}
