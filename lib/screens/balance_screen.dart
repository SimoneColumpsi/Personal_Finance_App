import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';

class BalanceScreen extends StatelessWidget {
  final List<Transaction> allTransactions;

  const BalanceScreen(this.allTransactions, {super.key});

  Future<void> _addAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuovo Contenitore'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome Conto (es. Revolut, Risparmi)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('accounts')
                    .add({'name': name, 'createdAt': Timestamp.now()});
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, String accountId, String accountName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Elimina "$accountName"?'),
        content: const Text('Verrà rimosso il contenitore. Le transazioni collegate rimarranno invariate.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Elimina', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .doc(accountId)
          .delete();
    }
  }

  void _showTransferDialog(BuildContext context, List<Map<String, dynamic>> accounts) {
    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea almeno due contenitori per effettuare un trasferimento.')),
      );
      return;
    }

    String? fromId = accounts[0]['id'];
    String? toId = accounts[1]['id'];
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Giroconto / Spostamento', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sposta denaro tra i tuoi contenitori senza creare spese o entrate.'),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: fromId,
                    decoration: const InputDecoration(labelText: 'Da Contenitore'),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc['id'],
                        child: Text(acc['name']),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => fromId = val),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: toId,
                    decoration: const InputDecoration(labelText: 'A Contenitore'),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<String>(
                        value: acc['id'],
                        child: Text(acc['name']),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => toId = val),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Importo (€)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
                  if (amount <= 0 || fromId == toId) return;

                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('transfers')
                        .add({
                      'fromAccountId': fromId,
                      'toAccountId': toId,
                      'amount': amount,
                      'date': Timestamp.now(),
                    });
                  }
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
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: user == null
          ? const Stream.empty()
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('accounts')
              .snapshots(),
      builder: (context, accountSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: user == null
              ? const Stream.empty()
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('transfers')
                  .snapshots(),
          builder: (context, transferSnapshot) {
            // 1. Gestione box di default se l'utente è nuovo
            List<Map<String, dynamic>> accounts = [];
            if (accountSnapshot.hasData && accountSnapshot.data!.docs.isEmpty) {
              // Inseriamo di default Contanti e Carta se vuoto
              FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('accounts').add({'name': 'Contanti', 'createdAt': Timestamp.now()});
              FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('accounts').add({'name': 'Carta', 'createdAt': Timestamp.now()});
            } else if (accountSnapshot.hasData) {
              accounts = accountSnapshot.data!.docs.map((doc) {
                return {'id': doc.id, 'name': (doc.data() as Map<String, dynamic>)['name'] ?? 'Conto'};
              }).toList();
            }

            // 2. Lettura trasferimenti
            List<Map<String, dynamic>> transfers = [];
            if (transferSnapshot.hasData) {
              transfers = transferSnapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return {
                  'from': d['fromAccountId'],
                  'to': d['toAccountId'],
                  'amount': (d['amount'] as num).toDouble(),
                };
              }).toList();
            }

            // 3. Calcolo saldi per ogni account
            Map<String, double> accountBalances = {};
            for (var acc in accounts) {
              accountBalances[acc['id']] = 0.0;
            }

            // Calcolo transazioni (usando paymentMethod che corrisponderà al nome del box)
            for (var tx in allTransactions) {
              final matchingAcc = accounts.firstWhere(
                (acc) => acc['name'].toString().toLowerCase() == tx.paymentMethod.toLowerCase(),
                orElse: () => {},
              );
              if (matchingAcc.isNotEmpty) {
                final accId = matchingAcc['id'];
                if (tx.isIncome) {
                  accountBalances[accId] = (accountBalances[accId] ?? 0) + tx.amount;
                } else {
                  accountBalances[accId] = (accountBalances[accId] ?? 0) - tx.amount;
                }
              }
            }

            // Calcolo trasferimenti tra box
            for (var tr in transfers) {
              final String fromId = tr['from'];
              final String toId = tr['to'];
              final double amt = tr['amount'];
              if (accountBalances.containsKey(fromId)) {
                accountBalances[fromId] = accountBalances[fromId]! - amt;
              }
              if (accountBalances.containsKey(toId)) {
                accountBalances[toId] = accountBalances[toId]! + amt;
              }
            }

            double saldoTotale = 0.0;
            accountBalances.forEach((key, val) => saldoTotale += val);

            return Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      "SALDO COMPLESSIVO",
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "€ ${saldoTotale.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: saldoTotale >= 0
                            ? (isDarkMode ? Colors.amber : Colors.teal)
                            : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // BOTTONI AZIONE RAPIDA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _addAccount(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Nuovo Box'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showTransferDialog(context, accounts),
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Sposta Denaro'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // LISTA DINAMICA DEI BOX
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: accounts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemBuilder: (ctx, i) {
                        final acc = accounts[i];
                        final balance = accountBalances[acc['id']] ?? 0.0;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        acc['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (accounts.length > 1)
                                      InkWell(
                                        onTap: () => _deleteAccount(context, acc['id'], acc['name']),
                                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                Text(
                                  "€ ${balance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0 ? Colors.green : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}