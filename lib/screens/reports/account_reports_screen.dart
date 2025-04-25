import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/account_db.dart';
import '../../utils/utilities.dart';

class AccountReportsScreen extends StatefulWidget {
  const AccountReportsScreen({Key? key}) : super(key: key);

  @override
  State<AccountReportsScreen> createState() => _AccountReportsScreenState();
}

class _AccountReportsScreenState extends State<AccountReportsScreen> {
  late Future<List<Map<String, dynamic>>> _accountTypeCountsFuture;

  // Friendly, pastel-ish accent colors for up to 8 segments
  static const List<Color> _pieColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
  ];

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
        title: const Text('Account Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionTitle(context, Icons.pie_chart, 'Accounts by Type'),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              final idx = entry.key;
                              final item = entry.value;
                              final count = item['count'] as int;
                              final color = _pieColors[idx % _pieColors.length];

                              return PieChartSectionData(
                                value: count.toDouble(),
                                color: color,
                                radius: 60,
                                title:
                                    '${(count / total * 100).toStringAsFixed(1)}%',
                                titleStyle:
                                    theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLegend(data, total, theme),
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

  Widget _buildLegend(
    List<Map<String, dynamic>> data,
    int total,
    ThemeData theme,
  ) {
    return Column(
      children: data.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final cnt = item['count'] as int;
        final pct = total > 0 ? (cnt / total) : 0.0;
        final color = _pieColors[idx % _pieColors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  getLocalizedAccountType(context, item['account_type']),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '$cnt (${(pct * 100).toStringAsFixed(1)}%)',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
