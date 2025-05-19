import 'account_reports_screen.dart';
import 'package:flutter/material.dart';
import 'system_account_reports_screen.dart';
import 'daily_balances_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'periodic_reports_screen.dart';

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
