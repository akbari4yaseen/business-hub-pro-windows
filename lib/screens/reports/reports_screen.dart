import 'package:flutter/material.dart';
import 'accounts/account_reports_screen.dart';
import 'system_account_reports_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportsScreen extends StatelessWidget {
  final VoidCallback openDrawer;
  const ReportsScreen({Key? key, required this.openDrawer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: openDrawer,
        ),
        title: Text(loc.reports),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.pie_chart),
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
              leading: const Icon(Icons.show_chart),
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
