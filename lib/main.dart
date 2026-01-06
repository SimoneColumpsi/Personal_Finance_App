import 'package:flutter/material.dart';

void main() {
  runApp(const PersonalFinanceApp());
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Spese',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Transaction> _transactions = [
    Transaction(
      id: 't1',
      title: 'Nuove Scarpe Nike',
      amount: 69.99,
      date: DateTime.now(),
    ),
    Transaction(
      id: 't2',
      title: 'Spesa Esselunga',
      amount: 45.50,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  void _addNewTransaction() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;

    if (enteredTitle.isEmpty || enteredAmount <= 0) {
      return;
    }

    setState(() {
      _transactions.add(
        Transaction(
          id: DateTime.now().toString(),
          title: enteredTitle,
          amount: enteredAmount,
          date: DateTime.now(),
        ),
      );
    });

    _titleController.clear();
    _amountController.clear();

    Navigator.of(context).pop();
  }

  // [NUOVO] Funzione per CANCELLARE una spesa
  void _deleteTransaction(String idDaCancellare) {
    setState(() {
      // "Rimuovi dove l'id è uguale a quello che ti ho passato"
      _transactions.removeWhere((tx) => tx.id == idDaCancellare);
    });
  }

  void _startAddNewTransaction(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Titolo Spesa'),
                controller: _titleController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Importo (€)'),
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addNewTransaction,
                child: const Text('Aggiungi Transazione'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie Spese'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _transactions.isEmpty
          ? const Center(
              child: Text("Nessuna spesa inserita!"),
            ) // [NUOVO] Se vuoto mostra scritta
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (ctx, index) {
                final tx = _transactions[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: FittedBox(
                          child: Text('€${tx.amount.toStringAsFixed(2)}'),
                        ),
                      ),
                    ),
                    title: Text(
                      tx.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      tx.date.toString().substring(0, 10),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    // [NUOVO] Il cestino rosso a destra
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () => _deleteTransaction(tx.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startAddNewTransaction(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
  });
}
