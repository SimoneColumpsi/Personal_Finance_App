import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class WeekGridWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime referenceDate;

  const WeekGridWidget({
    super.key,
    required this.transactions,
    required this.referenceDate,
  });

  void _showDayDetails(BuildContext context, DateTime day) {
    final dayTxs = transactions.where((tx) =>
        !tx.isIncome &&
        tx.date.year == day.year &&
        tx.date.month == day.month &&
        tx.date.day == day.day
    ).toList();

    final formattedDate = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(day);
    final totalSpent = dayTxs.fold(0.0, (sum, tx) => sum + tx.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                formattedDate.substring(0, 1).toUpperCase() + formattedDate.substring(1),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "Totale speso: €${totalSpent.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 14, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
              ),
              const Divider(height: 20),
              if (dayTxs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("Nessuna spesa registrata in questo giorno.", style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dayTxs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final tx = dayTxs[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.teal.withOpacity(0.15),
                          child: Icon(
                            tx.paymentMethod == 'Carta' ? Icons.credit_card : Icons.money,
                            size: 16,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${tx.category} • ${tx.paymentMethod}"),
                        trailing: Text(
                          "- €${tx.amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> weekDaysData = List.generate(7, (index) {
      final currentDay = referenceDate.add(Duration(days: index));
      double dailyTotal = 0.0;

      for (var tx in transactions) {
        if (!tx.isIncome &&
            tx.date.year == currentDay.year &&
            tx.date.month == currentDay.month &&
            tx.date.day == currentDay.day) {
          dailyTotal += tx.amount;
        }
      }

      final dayLetter = DateFormat.E('it_IT').format(currentDay).substring(0, 1).toUpperCase();
      final isWeekend = (index == 5 || index == 6);

      return {
        'date': currentDay,
        'letter': dayLetter,
        'dayNum': currentDay.day,
        'spent': dailyTotal,
        'isWeekend': isWeekend,
      };
    });

    final formatter = DateFormat('d MMM', 'it_IT');
    final endOfWeek = referenceDate.add(const Duration(days: 6));
    final rangeLabel = "${formatter.format(referenceDate)} - ${formatter.format(endOfWeek)}";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          children: [
            Text(
              "Riepilogo $rangeLabel",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const Divider(height: 12),
            Row(
              children: weekDaysData.map((data) {
                final double spent = data['spent'] as double;
                final bool hasSpent = spent > 0.0;
                final bool isWeekend = data['isWeekend'] as bool;
                final DateTime dayDate = data['date'] as DateTime;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showDayDetails(context, dayDate),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data['letter'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isWeekend ? Colors.redAccent.shade200 : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${data['dayNum']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasSpent ? Colors.teal.shade900 : Colors.black87,
                              fontWeight: hasSpent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hasSpent ? '€${spent.toStringAsFixed(0)}' : '-',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: hasSpent ? FontWeight.bold : FontWeight.normal,
                                color: hasSpent ? Colors.redAccent.shade700 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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