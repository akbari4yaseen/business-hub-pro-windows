import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../database/reports_db.dart';
import '../../../utils/utilities.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountTypeChart extends StatefulWidget {
  const AccountTypeChart({Key? key}) : super(key: key);

  @override
  State<AccountTypeChart> createState() => _AccountTypeChartState();
}

class _AccountTypeChartState extends State<AccountTypeChart> {
  late Future<List<Map<String, dynamic>>> _accountTypeCountsFuture;

  // Pastel-ish accent colors for up to 8 slices
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
    _accountTypeCountsFuture = ReportsDBHelper().getAccountTypeCounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _accountTypeCountsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snap.data;
            if (data == null || data.isEmpty) {
              return Text(loc.noDataAvailable,
                  style: theme.textTheme.bodyMedium);
            }

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
                        final cnt = item['count'] as int;
                        final color = _pieColors[idx % _pieColors.length];
                        return PieChartSectionData(
                          value: cnt.toDouble(),
                          color: color,
                          radius: 60,
                          title: '${(cnt / total * 100).toStringAsFixed(1)}%',
                          titleStyle: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildLegend(
      List<Map<String, dynamic>> data, int total, ThemeData theme) {
    return Column(
      children: data.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final cnt = item['count'] as int;
        final pct = total > 0 ? cnt / total : 0.0;
        final color = _pieColors[idx % _pieColors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      getLocalizedAccountType(context, item['account_type']),
                      style: theme.textTheme.bodyMedium)),
              Text('$cnt (${(pct * 100).toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      }).toList(),
    );
  }
}
