import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import './chart_bar.dart';

class Chart extends StatelessWidget {
  final List<Transaction> recentTransactions;
  final int periodIndex; // 0=Settimana, 1=Mese, 2=Anno

  const Chart(this.recentTransactions, this.periodIndex, {super.key});

  List<Map<String, Object>> get groupedTransactionValues {
    final now = DateTime.now();

    // --- CASO 0: SETTIMANA (Lunedì - Domenica) ---
    if (periodIndex == 0) {
      // Troviamo il Lunedì di questa settimana
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      return List.generate(7, (index) {
        final weekDay = startOfWeek.add(Duration(days: index));
        var totalSum = 0.0;

        for (var i = 0; i < recentTransactions.length; i++) {
          if (recentTransactions[i].date.day == weekDay.day &&
              recentTransactions[i].date.month == weekDay.month &&
              recentTransactions[i].date.year == weekDay.year) {
            totalSum += recentTransactions[i].amount;
          }
        }

        // Formattiamo il giorno (es. "lun", "mar")
        String dayName = DateFormat.E('it_IT').format(weekDay);
        String label =
            dayName.substring(0, 1).toUpperCase() + dayName.substring(1);

        return {'day': label, 'amount': totalSum};
      });
    }
    // --- CASO 1: MESE (4 Settimane fisse) ---
    else if (periodIndex == 1) {
      return List.generate(4, (index) {
        var totalSum = 0.0;
        String label = '';

        if (index == 0)
          label = '1-7';
        else if (index == 1)
          label = '8-14';
        else if (index == 2)
          label = '15-21';
        else
          label = '22+';

        for (var tx in recentTransactions) {
          int day = tx.date.day;
          bool isInPeriod = false;

          if (index == 0 && day >= 1 && day <= 7) isInPeriod = true;
          if (index == 1 && day >= 8 && day <= 14) isInPeriod = true;
          if (index == 2 && day >= 15 && day <= 21) isInPeriod = true;
          if (index == 3 && day >= 22) isInPeriod = true;

          if (isInPeriod &&
              tx.date.month == now.month &&
              tx.date.year == now.year) {
            totalSum += tx.amount;
          }
        }

        return {'day': label, 'amount': totalSum};
      });
    }
    // --- CASO 2: ANNO (Gennaio - Dicembre) ---
    else {
      return List.generate(12, (index) {
        final monthNumber = index + 1;
        var totalSum = 0.0;

        for (var tx in recentTransactions) {
          if (tx.date.month == monthNumber && tx.date.year == now.year) {
            totalSum += tx.amount;
          }
        }

        final dateForName = DateTime(now.year, monthNumber, 1);
        String monthName = DateFormat.MMM('it_IT').format(dateForName);
        String label =
            monthName.substring(0, 1).toUpperCase() + monthName.substring(1);

        return {'day': label, 'amount': totalSum};
      });
    }
  }

  double get totalSpending {
    return groupedTransactionValues.fold(0.0, (sum, item) {
      return sum + (item['amount'] as double);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // TITOLO
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                periodIndex == 0
                    ? "Questa Settimana"
                    : periodIndex == 1
                    ? "Questo Mese"
                    : "Quest'Anno (${DateTime.now().year})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // BARRE DEL GRAFICO
            // IMPORTANTE: Expanded serve per dare un'altezza finita alle barre
            // ed evitare l'errore di "Altezza Infinita" che bloccava l'app.
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: groupedTransactionValues.map((data) {
                  return Flexible(
                    fit: FlexFit.tight,
                    child: ChartBar(
                      (data['day'] as String),
                      (data['amount'] as double),
                      totalSpending == 0.0
                          ? 0.0
                          : (data['amount'] as double) / totalSpending,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
