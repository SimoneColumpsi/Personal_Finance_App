import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './chart_bar.dart';
import '../models/transaction.dart';

class Chart extends StatelessWidget {
  final List<Transaction> recentTransactions;
  final int periodIndex; // 0=Settimana, 1=Mese, 2=Anno

  // Ora accettiamo l'indice del periodo nel costruttore
  const Chart(this.recentTransactions, this.periodIndex, {super.key});

  List<Map<String, Object>> get groupedTransactionValues {
    // CASO 0: SETTIMANA (7 GIORNI)
    if (periodIndex == 0) {
      return List.generate(7, (index) {
        final weekDay = DateTime.now().subtract(Duration(days: index));
        var totalSum = 0.0;

        for (var i = 0; i < recentTransactions.length; i++) {
          if (recentTransactions[i].date.day == weekDay.day &&
              recentTransactions[i].date.month == weekDay.month &&
              recentTransactions[i].date.year == weekDay.year) {
            totalSum += recentTransactions[i].amount;
          }
        }

        String dayName = DateFormat.E('it_IT').format(weekDay);
        // "lun" -> "Lun"
        String label =
            dayName.substring(0, 1).toUpperCase() + dayName.substring(1);

        return {'day': label, 'amount': totalSum};
      }).reversed.toList();
    }
    // CASO 1: MESE (ULTIME 4 SETTIMANE)
    else if (periodIndex == 1) {
      return List.generate(4, (index) {
        // Calcoliamo l'intervallo di questa settimana
        final weekStart = DateTime.now().subtract(
          Duration(days: (index + 1) * 7),
        );
        final weekEnd = DateTime.now().subtract(Duration(days: index * 7));

        var totalSum = 0.0;

        for (var tx in recentTransactions) {
          if (tx.date.isAfter(weekStart) && tx.date.isBefore(weekEnd)) {
            totalSum += tx.amount;
          }
        }

        return {'day': '${4 - index}ª Set', 'amount': totalSum};
      }).reversed.toList();
    }
    // CASO 2: ANNO (ULTIMI 12 MESI)
    else {
      return List.generate(12, (index) {
        // Calcoliamo il mese
        final monthDate = DateTime(
          DateTime.now().year,
          DateTime.now().month - index,
          1,
        );

        var totalSum = 0.0;

        for (var tx in recentTransactions) {
          if (tx.date.month == monthDate.month &&
              tx.date.year == monthDate.year) {
            totalSum += tx.amount;
          }
        }

        String monthName = DateFormat.MMM('it_IT').format(monthDate);
        // "gen" -> "Gen"
        String label =
            monthName.substring(0, 1).toUpperCase() + monthName.substring(1);

        return {'day': label, 'amount': totalSum};
      }).reversed.toList();
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
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: groupedTransactionValues.map((data) {
            return Flexible(
              fit: FlexFit.tight,
              child: ChartBar(
                data['day'] as String,
                data['amount'] as double,
                totalSpending == 0.0
                    ? 0.0
                    : (data['amount'] as double) / totalSpending,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
