import 'package:flutter/material.dart';
import '../models/transaction.dart';

class BalanceScreen extends StatelessWidget {
  final List<Transaction> allTransactions;

  const BalanceScreen(this.allTransactions, {super.key});

  @override
Widget build(BuildContext context) {
  final totalBalance = allTransactions.fold(0.0, (sum, tx) {
    return tx.isIncome ? sum + tx.amount : sum - tx.amount;
  });

  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "SALDO ATTUALE", 
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          Text(
            "€ ${totalBalance.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              // Colore dinamico: verde se positivo, rosso se negativo
              color: totalBalance >= 0 ? Colors.teal : Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            totalBalance >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 80,
            color: (totalBalance >= 0 ? Colors.teal : Colors.redAccent).withOpacity(0.2),
          ),
        ],
      ),
    ),
  );
}
}