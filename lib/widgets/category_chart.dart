import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';

class CategoryChart extends StatelessWidget {
  final List<Transaction> recentTransactions;

  const CategoryChart(this.recentTransactions, {super.key});

  // Mappa dei colori per le categorie
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cibo':
        return Colors.redAccent;
      case 'Trasporti':
        return Colors.blueAccent;
      case 'Svago':
        return Colors.purpleAccent;
      case 'Casa':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recentTransactions.isEmpty) {
      return const Center(child: Text("Nessuna spesa nel periodo!"));
    }

    // 1. Calcoliamo il totale generale
    double totalSum = 0.0;
    // 2. Calcoliamo quanto abbiamo speso per ogni categoria
    Map<String, double> categoryTotals = {};

    for (var tx in recentTransactions) {
      totalSum += tx.amount;
      if (categoryTotals.containsKey(tx.category)) {
        categoryTotals[tx.category] = categoryTotals[tx.category]! + tx.amount;
      } else {
        categoryTotals[tx.category] = tx.amount;
      }
    }

    // 3. Creiamo le "fette" della torta
    List<PieChartSectionData> sections = [];
    categoryTotals.forEach((category, amount) {
      final percentage = (amount / totalSum) * 100;
      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(category),
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%', // Mostra es. 40%
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // LA TORTA
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            // LA LEGENDA (Spiegazione colori)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryTotals.keys.map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getCategoryColor(cat),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
