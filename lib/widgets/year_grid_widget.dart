import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class YearGridWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime referenceDate;

  const YearGridWidget({
    super.key,
    required this.transactions,
    required this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    final int year = referenceDate.year;

    // 1. Somma delle spese per ciascun mese (1 = Gennaio ... 12 = Dicembre)
    final Map<int, double> monthlyExpenses = {};
    for (var tx in transactions) {
      if (!tx.isIncome && tx.date.year == year) {
        final month = tx.date.month;
        monthlyExpenses[month] = (monthlyExpenses[month] ?? 0.0) + tx.amount;
      }
    }

    const months = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              "Riepilogo Mesi $year",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Divider(height: 12),

            // Griglia 4 colonne x 3 righe per i 12 mesi
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final monthNumber = index + 1;
                  final spent = monthlyExpenses[monthNumber] ?? 0.0;
                  final hasSpent = spent > 0.0;

                  return Container(
                    decoration: BoxDecoration(
                      color: hasSpent
                          ? Colors.teal.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasSpent
                            ? Colors.teal.withOpacity(0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          months[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasSpent ? Colors.teal.shade900 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasSpent ? '€${spent.toStringAsFixed(0)}' : '-',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasSpent ? FontWeight.bold : FontWeight.normal,
                              color: hasSpent ? Colors.redAccent.shade700 : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}