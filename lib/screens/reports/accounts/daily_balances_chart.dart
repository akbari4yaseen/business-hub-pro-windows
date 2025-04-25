import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DailyBalancesChart extends StatefulWidget {
  const DailyBalancesChart({Key? key}) : super(key: key);

  @override
  State<DailyBalancesChart> createState() => _DailyBalancesChartState();
}

class _DailyBalancesChartState extends State<DailyBalancesChart> {
  // Filter options
  final List<String> _accountTypes = [
    'Customer',
    'Supplier',
    'Owner',
    'Exchanger'
  ];
  final List<String> _currencies = ['USD', 'AFN', 'EUR', 'GBP'];
  final List<String> _periodOptions = [
    '1W',
    '1M',
    '3M',
    '6M',
    '1Y',
    '3Y',
    'All'
  ];

  String _selectedAccountType = 'Customer';
  String _selectedCurrency = 'USD';
  String _selectedPeriod = '1W';

  // Cached data by filter key
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
    setState(() => _isLoading = true);
    await Future.delayed(
        const Duration(milliseconds: 300)); // simulate data fetch
    _updateChartData();
    setState(() => _isLoading = false);
  }

  void _updateChartData() {
    final key = '$_selectedAccountType|$_selectedCurrency|$_selectedPeriod';
    if (_dataCache.containsKey(key)) {
      _chartData = _dataCache[key]!;
      _chartDates = _dateCache[key]!;
      return;
    }
    final rand = Random();
    final now = DateTime.now();
    final List<DateTime> dates = [];
    final List<FlSpot> spots = [];

    int count;
    Duration stepDays = const Duration(days: 1);
    int stepMonths = 0;

    switch (_selectedPeriod) {
      case '1W':
        count = 7;
        break;
      case '1M':
        count = 30;
        break;
      case '3M':
        count = 13;
        stepDays = const Duration(days: 7);
        break;
      case '6M':
        count = 6;
        stepMonths = 1;
        break;
      case '1Y':
        count = 12;
        stepMonths = 1;
        break;
      case '3Y':
        count = 12;
        stepMonths = 3;
        break;
      case 'All':
        count = 24;
        stepMonths = 1;
        break;
      default:
        count = 30;
    }

    for (int i = 0; i < count; i++) {
      DateTime date;
      if (stepMonths > 0) {
        date = DateTime(
            now.year, now.month - (count - 1 - i) * stepMonths, now.day);
      } else {
        date = now.subtract(Duration(days: stepDays.inDays * (count - 1 - i)));
      }
      dates.add(date);
      spots.add(FlSpot(i.toDouble(), 1000 + rand.nextDouble() * 500));
    }

    _dataCache[key] = spots;
    _dateCache[key] = dates;
    _chartData = spots;
    _chartDates = dates;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    // Compute current metric
    final double current = _chartData.isNotEmpty ? _chartData.last.y : 0.0;

    // Chart bounds and intervals
    final double minY = _chartData.isNotEmpty
        ? _chartData.map((e) => e.y).reduce(min) * 0.95
        : 0.0;
    final double maxY = _chartData.isNotEmpty
        ? _chartData.map((e) => e.y).reduce(max) * 1.05
        : 0.0;
    final int pts = _chartData.length;
    final double xInt = pts > 1 ? ((pts - 1) / 4).ceil().toDouble() : 1.0;
    final double yInt = (maxY > minY) ? ((maxY - minY) / 4) : (maxY * 0.25);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Current metric only
            _buildMetric('Current', current, _selectedCurrency, cs.primary),
            const SizedBox(height: 16),
            // Filters
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Account',
                    value: _selectedAccountType,
                    items: _accountTypes,
                    onChanged: (v) => _onFilter(v, null, null),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Currency',
                    value: _selectedCurrency,
                    items: _currencies,
                    onChanged: (v) => _onFilter(null, v, null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _periodOptions.map((p) {
                final bool sel = p == _selectedPeriod;
                return ChoiceChip(
                  label: Text(p),
                  selected: sel,
                  onSelected: (_) => _onFilter(null, null, p),
                  selectedColor: cs.primary,
                  backgroundColor: cs.primary.withOpacity(0.1),
                  labelStyle: TextStyle(color: sel ? cs.onPrimary : cs.primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Chart or loader
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
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
                        color: cs.onSurfaceVariant.withOpacity(0.2),
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
                                    symbol: '\$', decimalDigits: 0)
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
                              cs.primary.withOpacity(0.4),
                              cs.primary.withOpacity(0.05)
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
      _loadData();
    });
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final int idx = value.toInt().clamp(0, _chartDates.length - 1);
    final date = _chartDates[idx];
    DateFormat fmt;
    switch (_selectedPeriod) {
      case '1W':
      case '1M':
        fmt = DateFormat.Md();
        break;
      case '3M':
        fmt = DateFormat.MMMd();
        break;
      case '6M':
      case '1Y':
        fmt = DateFormat.yMMM();
        break;
      case '3Y':
      case 'All':
        fmt = DateFormat.y();
        break;
      default:
        fmt = DateFormat.Md();
    }
    return Text(fmt.format(date), style: Theme.of(context).textTheme.bodySmall);
  }

  // Helper to build summary metric
  Widget _buildMetric(
    String label,
    double value,
    String currencyCode,
    Color color,
  ) {
    final formatter = NumberFormat('#,###.##');
    final formatted = formatter.format(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
        ),
        Text(
          '\u200E$formatted $currencyCode',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
