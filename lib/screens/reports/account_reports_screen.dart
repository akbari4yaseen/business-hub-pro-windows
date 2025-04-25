import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/account_db.dart';

class AccountReportsScreen extends StatefulWidget {
  const AccountReportsScreen({Key? key}) : super(key: key);

  @override
  State<AccountReportsScreen> createState() => _AccountReportsScreenState();
}

class _AccountReportsScreenState extends State<AccountReportsScreen> {
  late Future<List<Map<String, dynamic>>> _accountTypeCountsFuture;

  @override
  void initState() {
    super.initState();
    _accountTypeCountsFuture = AccountDBHelper().getAccountTypeCounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionTitle(context, Icons.pie_chart, 'Accounts by Type'),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _accountTypeCountsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No accounts found.',
                        style: theme.textTheme.bodyMedium);
                  }

                  final data = snapshot.data!;
                  final total =
                      data.fold<int>(0, (sum, e) => sum + (e['count'] as int));

                  return Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            sections: data.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final count = item['count'] as int;
                              final percent = total > 0 ? (count / total) : 0.0;

                              final color = theme.colorScheme.primary
                                  .withOpacity((index + 1) / (data.length + 1));

                              return PieChartSectionData(
                                value: count.toDouble(),
                                color: color,
                                radius: 60,
                                title: '${(percent * 100).toStringAsFixed(1)}%',
                                titleStyle: theme.textTheme.titleSmall
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: data.map((item) {
                          final count = item['count'] as int;
                          final percent = total > 0 ? (count / total) : 0.0;
                          final color = theme.colorScheme.primary.withOpacity(
                              (data.indexOf(item) + 1) / (data.length + 1));
                          return Chip(
                            backgroundColor: color.withOpacity(0.2),
                            avatar:
                                CircleAvatar(backgroundColor: color, radius: 6),
                            label: Text(
                              '${item['account_type']} (${count}, ${(percent * 100).toStringAsFixed(1)}%)',
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, Icons.show_chart, 'Daily Balances'),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coming Soon',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Text('Stay tuned for daily balance charts.',
                          style: theme.textTheme.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
        Text(
          text,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
