import 'package:flutter/material.dart';
import '../models/transaction.dart';

class BalanceScreen extends StatelessWidget {
  final List<Transaction> allTransactions;

  const BalanceScreen(this.allTransactions, {super.key});

  @override
  Widget build(BuildContext context) {
    // 1. CALCOLO SEPARATO DEI SALDI
    double totaleContanti = 0.0;
    double totaleCarta = 0.0;

    for (var tx in allTransactions) {
      if (tx.paymentMethod == 'Carta') {
        if (tx.isIncome) {
          totaleCarta += tx.amount;
        } else {
          totaleCarta -= tx.amount;
        }
      } else {
        // 'Contanti' o vecchie transazioni senza metodo specificato
        if (tx.isIncome) {
          totaleContanti += tx.amount;
        } else {
          totaleContanti -= tx.amount;
        }
      }
    }

    double saldoTotale = totaleContanti + totaleCarta;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- SEZIONE SALDO TOTALE ---
              const Text(
                "SALDO COMPLESSIVO", 
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 5),
              Text(
                "€ ${saldoTotale.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: saldoTotale >= 0 
                      ? (isDarkMode ? Colors.amber : Colors.teal) 
                      : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 30),

              // --- SEZIONE CONTI SEPARATI (CARTA E CONTANTI) ---
              Row(
                children: [
                  // CARD CARTA
                  Expanded(
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text("CARTA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "€ ${totaleCarta.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: totaleCarta >= 0 ? Colors.green : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // CARD CONTANTI
                  Expanded(
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.money, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text("CONTANTI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "€ ${totaleContanti.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: totaleContanti >= 0 ? Colors.green : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // ICONA DI TREND DI SFONDO
              Icon(
                saldoTotale >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 80,
                color: (saldoTotale >= 0 
                        ? (isDarkMode ? Colors.amber : Colors.teal) 
                        : Colors.redAccent)
                    .withOpacity(0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}