import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import './chart_bar.dart';

class Chart extends StatelessWidget {
  final List<Transaction> recentTransactions;
  final int periodIndex; // 0=Settimana, 1=Mese, 2=Anno
  final DateTime referenceDate; // Data di inizio del periodo visualizzato

  const Chart(
    this.recentTransactions, 
    this.periodIndex, 
    this.referenceDate, 
    {super.key}
  );

  List<Map<String, Object>> get groupedTransactionValues {
    // --- CASO 0: SETTIMANA (Lunedì - Domenica) ---
    if (periodIndex == 0) {
      // referenceDate è già il Lunedì della settimana selezionata
      return List.generate(7, (index) {
        final weekDay = referenceDate.add(Duration(days: index));
        var totalSum = 0.0;

        for (var tx in recentTransactions) {
          if (tx.date.day == weekDay.day &&
              tx.date.month == weekDay.month &&
              tx.date.year == weekDay.year) {
            totalSum += tx.amount;
          }
        }

        String dayName = DateFormat.E('it_IT').format(weekDay);
        String label = dayName.substring(0, 1).toUpperCase() + dayName.substring(1);

        return {'day': label, 'amount': totalSum};
      });
    }
    // --- CASO 1: MESE (4 Settimane fisse del mese selezionato) ---
else if (periodIndex == 1) {
      final firstDayOfMonth = DateTime(referenceDate.year, referenceDate.month, 1);
      final lastDayOfMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0);

      // Troviamo il Lunedì della settimana in cui cade il 1° del mese
      DateTime currentMonday = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));

      List<Map<String, Object>> weeks = [];
      int weekNumber = 1;

      while (currentMonday.isBefore(lastDayOfMonth) || currentMonday.isAtSameMomentAs(lastDayOfMonth)) {
        final sunday = currentMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        
        // Calcola l'inizio e la fine limitati ai confini effettivi del mese
        final startPeriod = currentMonday.isBefore(firstDayOfMonth) ? firstDayOfMonth : currentMonday;
        final endPeriod = sunday.isAfter(lastDayOfMonth) ? lastDayOfMonth : sunday;

        var totalSum = 0.0;
        for (var tx in recentTransactions) {
          if ((tx.date.isAfter(startPeriod) || tx.date.isAtSameMomentAs(startPeriod)) &&
              (tx.date.isBefore(endPeriod) || tx.date.isAtSameMomentAs(endPeriod))) {
            totalSum += tx.amount;
          }
        }

        // Etichetta leggibile con l'intervallo reale (es. "1-6", "7-13", "14-20", ...)
        final label = "${startPeriod.day}-${endPeriod.day}";

        weeks.add({
          'day': label,
          'amount': totalSum,
        });

        // Passa al Lunedì successivo
        currentMonday = currentMonday.add(const Duration(days: 7));
        weekNumber++;
      }

      return weeks;
    }
    // --- CASO 2: ANNO (Gennaio - Dicembre dell'anno selezionato) ---
    else {
      return List.generate(12, (index) {
        final monthNumber = index + 1;
        var totalSum = 0.0;

        for (var tx in recentTransactions) {
          if (tx.date.month == monthNumber && tx.date.year == referenceDate.year) {
            totalSum += tx.amount;
          }
        }

        final dateForName = DateTime(referenceDate.year, monthNumber, 1);
        String monthName = DateFormat.MMM('it_IT').format(dateForName);
        String label = monthName.substring(0, 1).toUpperCase() + monthName.substring(1);

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
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                periodIndex == 0
                    ? "Spese Settimanali"
                    : periodIndex == 1
                    ? "Spese Mensili"
                    : "Spese Annuali (${referenceDate.year})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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