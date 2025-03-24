import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for the chart
    final List<FlSpot> spots = [
      FlSpot(0, 100), // Day 1, Amount 100
      FlSpot(1, 200), // Day 2, Amount 200
      FlSpot(2, 150), // Day 3, Amount 150
      FlSpot(3, 300), // Day 4, Amount 300
      FlSpot(4, 250), // Day 5, Amount 250
      FlSpot(5, 400), // Day 6, Amount 400
      FlSpot(6, 350), // Day 7, Amount 350
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Daily Sales Report',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // Map x-axis values to days
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          return Text(days[value.toInt()]);
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // Display amounts on the y-axis
                          return Text('\$${value.toInt()}');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 500,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: Colors.blue.withOpacity(0.3)),
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
}
