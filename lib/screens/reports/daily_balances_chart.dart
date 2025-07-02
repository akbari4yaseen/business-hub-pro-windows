import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../database/reports_db.dart';
import '../../utils/date_formatters.dart';
import '../../utils/account_types.dart';
import '../../constants/currencies.dart';

class DailyBalancesChart extends StatefulWidget {
  const DailyBalancesChart({Key? key}) : super(key: key);

  @override
  State<DailyBalancesChart> createState() => _DailyBalancesChartState();
}

class _DailyBalancesChartState extends State<DailyBalancesChart> {
  String _selectedAccountType = 'customer';
  String _selectedCurrency = currencies.first;
  String _selectedPeriod = 'month';

  final Map<String, _ChartData> _cache = {};
  Future<_ChartData>? _chartFuture;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

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

    final rows = await ReportsDBHelper().getAllDailyBalances(
      accountType: _selectedAccountType,
      currency: _selectedCurrency,
    );

    final data = await compute(_processRows, {
      'rows': rows,
      'start': startDate.toIso8601String(),
      'end': now.toIso8601String(),
    });

    return data;
  }

  static _ChartData _processRows(Map<String, dynamic> args) {
    final rows = args['rows'] as List<dynamic>;
    final start = DateTime.parse(args['start'] as String);
    final end = DateTime.parse(args['end'] as String);

    final netMap = <String, double>{};
    for (final row in rows) {
      final date = row['date'] as String;
      final net = (row['net'] as num).toDouble();
      netMap[date] = net;
    }

    final allDates = <DateTime>[];
    final visibleSpots = <FlSpot>[];
    double runningTotal = 0;
    int visibleIndex = 0;

    DateTime current = netMap.keys
        .map((d) => DateTime.parse(d))
        .fold(DateTime.now(), (a, b) => a.isBefore(b) ? a : b);

    while (!current.isAfter(end)) {
      final dateStr = current.toIso8601String().substring(0, 10);
      final net = netMap[dateStr] ?? 0.0;
      runningTotal += net;

      if (!current.isBefore(start)) {
        allDates.add(current);
        visibleSpots.add(FlSpot(visibleIndex.toDouble(), runningTotal.abs()));
        visibleIndex++;
      }

      current = current.add(const Duration(days: 1));
    }

    return _ChartData(dates: allDates, spots: visibleSpots);
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

    return Scaffold(
      appBar: AppBar(title: Text(loc.dailyBalances)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 300,
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
                        SizedBox(
                          width: 200,
                          child: _FilterDropdown(
                            label: loc.currency,
                            value: _selectedCurrency,
                            items: currencies,
                            onChanged: (v) => _onFilter(null, v, null),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      children: periodOptions.map((p) {
                        final sel = p['key'] == _selectedPeriod;
                        return ChoiceChip(
                          label: Text(p['label']!),
                          selected: sel,
                          checkmarkColor: Colors.white,
                          onSelected: (_) => _onFilter(null, null, p['key']),
                          selectedColor: cs.primary,
                          backgroundColor: cs.primary.withValues(alpha: 0.1),
                          labelStyle:
                              TextStyle(color: sel ? cs.onPrimary : cs.primary),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    FutureBuilder<_ChartData>(
                      future: _chartFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final data = snapshot.data!;
                        final spots = data.spots;
                        final dates = data.dates;
                        if (spots.isEmpty) {
                          return SizedBox(
                            height: 250,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.insert_chart_outlined,
                                      size: 48,
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.5)),
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
                            SizedBox(
                              height: 400,
                              child: LineChart(
                                LineChartData(
                                  minY: minY,
                                  maxY: maxY,
                                  gridData: FlGridData(
                                    show: true,
                                    horizontalInterval: yInterval,
                                    getDrawingHorizontalLine: (_) => FlLine(
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.2),
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
                                          final idx = val
                                              .toInt()
                                              .clamp(0, dates.length - 1);
                                          final date = dates[idx];

                                          String label;
                                          switch (_selectedPeriod) {
                                            case 'week':
                                            case 'month':
                                              label = formatLocalizedDateShort(
                                                  context, date);
                                              break;
                                            case '3months':
                                              label = formatLocalizedMonthDay(
                                                  context, date);
                                              break;
                                            default:
                                              label = formatLocalizedYear(
                                                  context, date);
                                          }
                                          return Text(label,
                                              style: theme.textTheme.bodySmall);
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                  ),
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (spots) =>
                                          spots.map((s) {
                                        final date = dates[s.spotIndex];
                                        return LineTooltipItem(
                                          '${formatLocalizedDate(context, date.toString())}\n${s.y.toStringAsFixed(2)}',
                                          theme.textTheme.bodySmall!
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
                                            cs.primary.withValues(alpha: 0.4),
                                            cs.primary.withValues(alpha: 0.05),
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
            ),
          ),
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
    final formatter = NumberFormat('#,##0.##');
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
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

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
