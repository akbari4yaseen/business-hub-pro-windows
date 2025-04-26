import 'dart:math';
import 'package:BusinessHub/utils/account_types.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../database/reports_db.dart';
import '../../../constants/currencies.dart';

class DailyBalancesChart extends StatefulWidget {
  const DailyBalancesChart({Key? key}) : super(key: key);

  @override
  State<DailyBalancesChart> createState() => _DailyBalancesChartState();
}

class _DailyBalancesChartState extends State<DailyBalancesChart> {
  String _selectedAccountType = 'customer';
  String _selectedCurrency = 'AFN';
  String _selectedPeriod = 'week';

  final Map<String, List<FlSpot>> _dataCache = {};
  final Map<String, List<DateTime>> _dateCache = {};

  List<FlSpot> _chartData = [];
  List<DateTime> _chartDates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final key = '$_selectedAccountType|$_selectedCurrency|$_selectedPeriod';
    if (_dataCache.containsKey(key)) {
      setState(() {
        _chartData = _dataCache[key]!;
        _chartDates = _dateCache[key]!;
      });
      return;
    }

    setState(() => _isLoading = true);

    final now = DateTime.now();
    late DateTime startDate;
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 6));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6months':
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case '3years':
        startDate = DateTime(now.year - 3, now.month, now.day);
        break;
      case 'all':
        startDate = DateTime(1970);
        break;
      default:
        startDate = DateTime(now.year, now.month - 1, now.day);
    }
    final endDate = now;

    final rows = await ReportsDBHelper().getDailyBalances(
      accountType: _selectedAccountType,
      currency: _selectedCurrency,
      startDate: startDate,
      endDate: endDate,
    );

    double cumulative = 0;
    final List<DateTime> dates = [];
    final List<FlSpot> spots = [];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final date = DateTime.parse(row['date'] as String);
      final net = (row['net'] as num).toDouble();
      cumulative += net;
      dates.add(date);
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    _dataCache[key] = spots;
    _dateCache[key] = dates;
    setState(() {
      _chartData = spots;
      _chartDates = dates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accountTypes = getAccountTypes(loc);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    // localized period options
    final periodOptions = <Map<String, String>>[
      {'key': 'week', 'label': loc.periodWeek},
      {'key': 'month', 'label': loc.periodMonth},
      {'key': '3months', 'label': loc.period3Months},
      {'key': '6months', 'label': loc.period6Months},
      {'key': 'year', 'label': loc.periodYear},
      {'key': '3years', 'label': loc.period3Years},
      {'key': 'all', 'label': loc.periodAll},
    ];

    final double current = _chartData.isNotEmpty ? _chartData.last.y : 0.0;
    final double minY = _chartData.isNotEmpty
        ? _chartData.map((e) => e.y).reduce(min) * 0.95
        : 0.0;
    final double maxY = _chartData.isNotEmpty
        ? _chartData.map((e) => e.y).reduce(max) * 1.05
        : 0.0;
    final int pts = _chartData.length;
    final double xInt = pts > 1 ? ((pts - 1) / 4).ceil().toDouble() : 1.0;
    final double rawYInt = (maxY > minY) ? ((maxY - minY) / 4) : (maxY * 0.25);
    final double yInt = rawYInt > 0 ? rawYInt : 1.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildMetric(
                loc.currentLabel, current, _selectedCurrency, cs.primary),
            const SizedBox(height: 16),
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
                  child: _buildDropdown(
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
                final bool sel = p['key'] == _selectedPeriod;
                return ChoiceChip(
                  label: Text(p['label']!),
                  selected: sel,
                  onSelected: (_) => _onFilter(null, null, p['key']),
                  selectedColor: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: sel ? cs.onPrimary : cs.primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_chartData.isEmpty)
              SizedBox(
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
                      Text(
                        loc.noDataAvailable,
                        style: tt.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 1.7,
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: yInt,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: yInt,
                          reservedSize: 48,
                          getTitlesWidget: (val, meta) => Text(
                            NumberFormat.compactCurrency(
                                    symbol: '', decimalDigits: 0)
                                .format(val),
                            style: tt.bodySmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: xInt,
                          getTitlesWidget: _bottomTitleWidgets,
                        ),
                      ),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots.map((s) {
                          final date = _chartDates[s.spotIndex];
                          return LineTooltipItem(
                            '${DateFormat.yMMMd().format(date)}\n'
                            '${s.y.toStringAsFixed(2)}',
                            tt.bodySmall!.copyWith(color: cs.onSurface),
                          );
                        }).toList(),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartData,
                        isCurved: true,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              cs.primary.withValues(alpha: 0.4),
                              cs.primary.withValues(alpha: 0.05)
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
        ),
      ),
    );
  }

  void _onFilter(String? acc, String? cur, String? per) {
    setState(() {
      if (acc != null) _selectedAccountType = acc;
      if (cur != null) _selectedCurrency = cur;
      if (per != null) _selectedPeriod = per;
    });
    _loadData();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final idx = value.toInt().clamp(0, _chartDates.length - 1);
    final date = _chartDates[idx];
    late DateFormat fmt;
    switch (_selectedPeriod) {
      case 'week':
      case 'month':
        fmt = DateFormat.Md();
        break;
      case '3months':
        fmt = DateFormat.MMMd();
        break;
      case '6months':
      case 'year':
        fmt = DateFormat.yMMM();
        break;
      case '3years':
      case 'all':
        fmt = DateFormat.y();
        break;
      default:
        fmt = DateFormat.Md();
    }
    return Text(fmt.format(date), style: Theme.of(context).textTheme.bodySmall);
  }

  Widget _buildMetric(
      String label, double value, String currencyCode, Color color) {
    final formatter = NumberFormat('#,###.##');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        Text('\u200E${formatter.format(value)} $currencyCode',
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDropdown(
      {required String label,
      required String value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
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
