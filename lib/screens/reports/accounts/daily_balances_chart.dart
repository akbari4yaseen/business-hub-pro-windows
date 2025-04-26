import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // for compute
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../database/reports_db.dart';
import '../../../utils/account_types.dart';
import '../../../constants/currencies.dart';

class DailyBalancesChart extends StatefulWidget {
  const DailyBalancesChart({Key? key}) : super(key: key);

  @override
  State<DailyBalancesChart> createState() => _DailyBalancesChartState();
}

class _DailyBalancesChartState extends State<DailyBalancesChart> {
  String _selectedAccountType = 'customer';
  String _selectedCurrency = currencies.first;
  String _selectedPeriod = 'week';

  final Map<String, _ChartData> _cache = {};
  Future<_ChartData>? _chartFuture;
  Timer? _debounce;

  late final DateFormat _fmtShort;
  late final DateFormat _fmtMonth;
  late final DateFormat _fmtYear;

  @override
  void initState() {
    super.initState();
    _fmtShort = DateFormat.Md();
    _fmtMonth = DateFormat.MMMd();
    _fmtYear = DateFormat.y();
    _loadChart();
  }

  void _loadChart() {
    final key = '$_selectedAccountType|$_selectedCurrency|$_selectedPeriod';
    if (_cache.containsKey(key)) {
      _chartFuture = Future.value(_cache[key]);
    } else {
      _chartFuture = _fetchChartData(key);
    }
  }

  Future<_ChartData> _fetchChartData(String key) async {
    final now = DateTime.now();
    final startDate = _computeStartDate(now, _selectedPeriod);
    final rows = await ReportsDBHelper().getDailyBalances(
      accountType: _selectedAccountType,
      currency: _selectedCurrency,
      startDate: startDate,
      endDate: now,
    );
    final data = await compute(_processRows, rows);
    _cache[key] = data;
    return data;
  }

  static _ChartData _processRows(List<dynamic> rows) {
    double cum = 0;
    final dates = <DateTime>[];
    final spots = <FlSpot>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i] as Map<String, dynamic>;
      final date = DateTime.parse(row['date'] as String);
      cum += (row['net'] as num).toDouble();
      dates.add(date);
      spots.add(FlSpot(i.toDouble(), cum));
    }
    return _ChartData(dates: dates, spots: spots);
  }

  static DateTime _computeStartDate(DateTime now, String period) {
    switch (period) {
      case 'week':
        return now.subtract(Duration(days: 6));
      case 'month':
        return DateTime(now.year, now.month - 1, now.day);
      case '3months':
        return DateTime(now.year, now.month - 3, now.day);
      case '6months':
        return DateTime(now.year, now.month - 6, now.day);
      case 'year':
        return DateTime(now.year - 1, now.month, now.day);
      case '3years':
        return DateTime(now.year - 3, now.month, now.day);
      case 'all':
        return DateTime.utc(1970);
      default:
        return DateTime(now.year, now.month - 1, now.day);
    }
  }

  void _onFilter(String? acc, String? cur, String? per) {
    if (acc != null) _selectedAccountType = acc;
    if (cur != null) _selectedCurrency = cur;
    if (per != null) _selectedPeriod = per;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () {
      setState(() {
        _loadChart();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accountTypes = getAccountTypes(loc);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final periodOptions = [
      {'key': 'week', 'label': loc.periodWeek},
      {'key': 'month', 'label': loc.periodMonth},
      {'key': '3months', 'label': loc.period3Months},
      {'key': '6months', 'label': loc.period6Months},
      {'key': 'year', 'label': loc.periodYear},
      {'key': '3years', 'label': loc.period3Years},
      {'key': 'all', 'label': loc.periodAll},
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAccountType,
                    decoration: InputDecoration(
                      labelText: loc.accountLabel,
                      filled: true,
                      fillColor: cs.primary.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: accountTypes.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => _onFilter(v, null, null),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FilterDropdown(
                    label: loc.currency,
                    value: _selectedCurrency,
                    items: currencies,
                    onChanged: (v) => _onFilter(null, v, null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: periodOptions.map((p) {
                final sel = p['key'] == _selectedPeriod;
                return ChoiceChip(
                  label: Text(p['label']!),
                  selected: sel,
                  checkmarkColor: Colors.white,
                  onSelected: (_) => _onFilter(null, null, p['key']),
                  selectedColor: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: sel ? cs.onPrimary : cs.primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            FutureBuilder<_ChartData>(
              future: _chartFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!;
                final spots = data.spots;
                final dates = data.dates;
                if (spots.isEmpty) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_chart_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(loc.noDataAvailable,
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }

                final current = spots.last.y;
                final minY = spots.map((e) => e.y).reduce(min) * 0.95;
                final maxY = spots.map((e) => e.y).reduce(max) * 1.05;
                final yInterval =
                    ((maxY - minY) / 4).clamp(1.0, double.infinity);
                final xInterval = (spots.length > 1)
                    ? ((spots.length - 1) / 4).ceilToDouble()
                    : 1.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Metric(
                        label: loc.currentLabel,
                        value: current,
                        currency: _selectedCurrency),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1.7,
                      child: LineChart(
                        LineChartData(
                          minY: minY,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: yInterval,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: yInterval,
                                reservedSize: 48,
                                getTitlesWidget: (val, meta) => Text(
                                  NumberFormat.compactCurrency(
                                          symbol: '', decimalDigits: 0)
                                      .format(val),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: xInterval,
                                getTitlesWidget: (val, meta) {
                                  final idx =
                                      val.toInt().clamp(0, dates.length - 1);
                                  final date = dates[idx];
                                  late DateFormat fmt;
                                  switch (_selectedPeriod) {
                                    case 'week':
                                    case 'month':
                                      fmt = _fmtShort;
                                      break;
                                    case '3months':
                                      fmt = _fmtMonth;
                                      break;
                                    default:
                                      fmt = _fmtYear;
                                  }
                                  return Text(fmt.format(date),
                                      style: theme.textTheme.bodySmall);
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots.map((s) {
                                final date = dates[s.spotIndex];
                                return LineTooltipItem(
                                  '${DateFormat.yMMMd().format(date)}\n${s.y.toStringAsFixed(2)}',
                                  Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(color: cs.onSurface),
                                );
                              }).toList(),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.4),
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              color: cs.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class _ChartData {
  final List<DateTime> dates;
  final List<FlSpot> spots;
  _ChartData({required this.dates, required this.spots});
}

class _Metric extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  const _Metric(
      {required this.label, required this.value, required this.currency});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###.##');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.7),
                fontSize: 12)),
        Text('\u200E${formatter.format(value)} $currency',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
