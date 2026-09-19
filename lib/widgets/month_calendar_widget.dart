import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class MonthCalendarWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final DateTime referenceDate;

  const MonthCalendarWidget({
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
    final int year = referenceDate.year;
    final int month = referenceDate.month;

    final Map<int, double> dailyExpenses = {};
    for (var tx in transactions) {
      if (!tx.isIncome && tx.date.year == year && tx.date.month == month) {
        final day = tx.date.day;
        dailyExpenses[day] = (dailyExpenses[day] ?? 0.0) + tx.amount;
      }
    }

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final int leadingEmptyDays = firstDayOfMonth.weekday - 1;

    final totalGridCells = leadingEmptyDays + daysInMonth;
    final int totalRows = (totalGridCells / 7).ceil();

    const weekDays = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekDays.map((d) {
                final isWeekend = (d == 'S' || d == 'D');
                return SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isWeekend ? Colors.redAccent.shade200 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 10),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalRows * 7,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - leadingEmptyDays + 1;

                  if (index < leadingEmptyDays || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final spent = dailyExpenses[dayNumber] ?? 0.0;
                  final hasSpent = spent > 0.0;
                  final dayDate = DateTime(year, month, dayNumber);

                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _showDayDetails(context, dayDate),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasSpent
                            ? Colors.teal.withOpacity(0.08)
                            : Colors.grey.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasSpent
                              ? Colors.teal.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasSpent ? FontWeight.bold : FontWeight.normal,
                              color: hasSpent ? Colors.teal.shade900 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hasSpent ? '€${spent.toStringAsFixed(0)}' : '-',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: hasSpent ? FontWeight.bold : FontWeight.normal,
                                color: hasSpent ? Colors.redAccent.shade700 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
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