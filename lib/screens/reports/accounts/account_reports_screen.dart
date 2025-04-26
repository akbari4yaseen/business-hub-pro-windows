import 'package:flutter/material.dart';
import 'account_type_chart.dart';
import 'daily_balances_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountReportsScreen extends StatefulWidget {
  const AccountReportsScreen({Key? key}) : super(key: key);

  @override
  State<AccountReportsScreen> createState() => _AccountReportsScreenState();
}

class _AccountReportsScreenState extends State<AccountReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.accountReports)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionTitle(context, Icons.pie_chart, loc.accountsByType),
          const SizedBox(height: 8),
          const AccountTypeChart(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, Icons.show_chart, loc.dailyBalances),
          const SizedBox(height: 8),
          const DailyBalancesChart(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(text,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
