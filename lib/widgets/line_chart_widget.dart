import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class LineChartWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const LineChartWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    Map<int, double> monthlySums = {};
    double maxAmount = 0;

    for (var tx in transactions) {
      if (!tx.isIncome) {
        int month = tx.date.month;
        monthlySums[month] = (monthlySums[month] ?? 0) + tx.amount;
        if (monthlySums[month]! > maxAmount) maxAmount = monthlySums[month]!;
      }
    }

    List<FlSpot> spots = [];
    for (int i = 1; i <= 12; i++) {
      spots.add(FlSpot(i.toDouble(), monthlySums[i] ?? 0));
    }

    return Container(
      height: 250,
      // Padding sinistro a 20 per far stare i numeri dell'asse Y senza SideTitleWidget
      padding: const EdgeInsets.fromLTRB(10, 25, 25, 10),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxAmount == 0 ? 100 : maxAmount * 1.3,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.teal.shade900,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '€${spot.y.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            
            // --- ASSE Y (SINISTRA) ---
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: maxAmount == 0 ? 20 : (maxAmount / 3),
                getTitlesWidget: (value, meta) {
                  String text = '';
                  if (value >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(1)}k';
                  } else {
                    text = value.toInt().toString();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),

            // --- ASSE X (MESI) ---
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const months = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
                  if (value.toInt() >= 1 && value.toInt() <= 12) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        months[value.toInt() - 1],
                        style: TextStyle(
                          fontSize: 10, 
                          color: Colors.grey.shade600, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.teal,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.withOpacity(0.4),
                    Colors.teal.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}