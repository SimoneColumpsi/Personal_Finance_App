import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';

class BalanceScreen extends StatelessWidget {
  final List<Transaction> allTransactions;

  const BalanceScreen(this.allTransactions, {super.key});

  // Funzione per salvare lo spostamento su Firestore senza toccare le spese/entrate
  Future<void> _updateWarehouseBalance(BuildContext context, double currentWarehouse, double changeAmount, bool isDeposit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newWarehouseAmount = isDeposit
        ? (currentWarehouse + changeAmount)
        : (currentWarehouse - changeAmount);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('cash_storage')
        .set({'warehouseAmount': newWarehouseAmount}, SetOptions(merge: true));
  }

  void _showTransferDialog(BuildContext context, double currentWarehouse, double currentWallet) {
    final amountController = TextEditingController();
    bool isDeposit = true; // true = Versa in Magazzino, false = Preleva nel Portafoglio

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Trasferimento Contanti', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sposta i contanti tra portafoglio e magazzino senza creare spese o entrate:'),
                  const SizedBox(height: 15),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('A Magazzino'),
                        icon: Icon(Icons.archive),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('A Portafoglio'),
                        icon: Icon(Icons.account_balance_wallet),
                      ),
                    ],
                    selected: {isDeposit},
                    onSelectionChanged: (val) {
                      setDialogState(() => isDeposit = val.first);
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Importo (€)',
                      border: const OutlineInputBorder(),
                      helperText: isDeposit
                          ? 'Disponibili nel portafoglio: €${currentWallet.toStringAsFixed(2)}'
                          : 'Disponibili in magazzino: €${currentWarehouse.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  final entered = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
                  if (entered <= 0) return;

                  _updateWarehouseBalance(context, currentWarehouse, entered, isDeposit);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Conferma'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calcolo standard di Carta e Contanti
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
        if (tx.isIncome) {
          totaleContanti += tx.amount;
        } else {
          totaleContanti -= tx.amount;
        }
      }
    }

    final double saldoTotale = totaleContanti + totaleCarta;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    // 2. Ascolto in tempo reale della giacenza del Magazzino da Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: user == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('settings')
              .doc('cash_storage')
              .snapshots(),
      builder: (context, snapshot) {
        double magazzino = 0.0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          magazzino = (data?['warehouseAmount'] as num?)?.toDouble() ?? 0.0;
        }

        // Portafoglio ricavato per differenza
        final double portafoglio = totaleContanti - magazzino;

        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- SALDO COMPLESSIVO ---
                  const Text(
                    "SALDO COMPLESSIVO",
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
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

                  // --- ROW CONTI (CARTA E CONTANTI) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CARD CARTA
                      Expanded(
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.credit_card, color: Colors.blue, size: 20),
                                    SizedBox(width: 6),
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
                      const SizedBox(width: 12),

                      // CARD CONTANTI CON SUDDIVISIONE INTERNA
                      Expanded(
                        child: Card(
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.money, color: Colors.orange, size: 20),
                                    SizedBox(width: 6),
                                    Text("CONTANTI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "€ ${totaleContanti.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: totaleContanti >= 0 ? Colors.green : Colors.redAccent,
                                  ),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Portafoglio:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(
                                      "€${portafoglio.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Magazzino:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(
                                      "€${magazzino.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _showTransferDialog(context, magazzino, portafoglio),
                                    icon: const Icon(Icons.swap_horiz, size: 16),
                                    label: const Text("Sposta", style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),

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
      },
    );
  }
}