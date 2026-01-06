import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// IMPORTANTE: Nascondiamo Transaction di Firestore per usare la nostra
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import './models/transaction.dart';
import './widgets/new_transaction.dart';
import './widgets/chart.dart';
import './screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  initializeDateFormatting('it_IT', null).then((_) {
    runApp(const PersonalFinanceApp());
  });
}

class PersonalFinanceApp extends StatefulWidget {
  const PersonalFinanceApp({super.key});

  @override
  State<PersonalFinanceApp> createState() => _PersonalFinanceAppState();
}

class _PersonalFinanceAppState extends State<PersonalFinanceApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Spese',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          secondary: Colors.amber,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Colors.grey.shade900,
          onPrimary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.amber,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.amber),
        ),
      ),
      // IL PORTIERE: Controlla se c'è un utente loggato
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return HomePage(changeTheme: _toggleTheme);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback changeTheme;
  const HomePage({super.key, required this.changeTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 0 = Settimana, 1 = Mese, 2 = Anno
  int _selectedChartPeriod = 0;

  // Funzione che invia i dati al Cloud
  void _addNewTransaction(
    String txTitle,
    double txAmount,
    DateTime chosenDate,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance.collection('expenses').add({
      'title': txTitle,
      'amount': txAmount,
      'date': chosenDate, // Firebase lo convertirà in Timestamp
      'userId': user.uid,
    });
    // NON serve più setState locale, il StreamBuilder aggiornerà la lista da solo!
  }

  // Funzione che cancella dal Cloud
  void _deleteTransaction(String id) {
    FirebaseFirestore.instance.collection('expenses').doc(id).delete();
  }

  void _startAddNewTransaction(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: NewTransaction(_addNewTransaction),
        );
      },
    );
  }

  Widget _buildFilterButton(String title, int index) {
    final isSelected = _selectedChartPeriod == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _selectedChartPeriod = index;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.secondary
              : null,
          foregroundColor: isSelected
              ? Colors.black
              : Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey,
          ),
        ),
        child: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LE MIE SPESE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: widget.changeTheme,
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // QUI C'È LA MAGIA: Ascoltiamo il database in tempo reale
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: user?.uid) // Prendi solo le MIE spese
            .snapshots(),
        builder: (ctx, snapshot) {
          // 1. Se sta caricando i dati
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Se non ci sono dati o lista vuota
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nessuna spesa nel cloud!",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // 3. Se ci sono dati, convertiamoli da "Documento Firebase" a "Transaction"
          final loadedTransactions = snapshot.data!.docs.map((doc) {
            final data = doc.data();
            return Transaction(
              id: doc.id, // L'ID univoco del documento
              title: data['title'],
              amount: data['amount'],
              // Convertiamo il Timestamp di Firebase in DateTime di Dart
              date: (data['date'] as Timestamp).toDate(),
            );
          }).toList();

          // Ordiniamo le spese dalla più recente alla più vecchia (in memoria)
          loadedTransactions.sort((a, b) => b.date.compareTo(a.date));

          // Calcoliamo quali passare al grafico in base al filtro
          DateTime limitDate;
          if (_selectedChartPeriod == 0) {
            limitDate = DateTime.now().subtract(const Duration(days: 7));
          } else if (_selectedChartPeriod == 1) {
            limitDate = DateTime.now().subtract(const Duration(days: 30));
          } else {
            limitDate = DateTime.now().subtract(const Duration(days: 365));
          }

          final recentForChart = loadedTransactions.where((tx) {
            return tx.date.isAfter(limitDate);
          }).toList();

          // 4. Mostriamo la schermata con i dati scaricati
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filtri
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterButton('Settimana', 0),
                    _buildFilterButton('Mese', 1),
                    _buildFilterButton('Anno', 2),
                  ],
                ),
              ),

              // Grafico
              SizedBox(
                height: 180,
                child: Chart(recentForChart, _selectedChartPeriod),
              ),

              // Lista
              Expanded(
                child: ListView.builder(
                  itemCount: loadedTransactions.length,
                  itemBuilder: (ctx, index) {
                    final tx = loadedTransactions[index];
                    return Card(
                      elevation: isDarkMode ? 2 : 4,
                      color: isDarkMode ? Colors.grey.shade900 : null,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: isDarkMode
                            ? const BorderSide(color: Colors.amber, width: 1)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
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
                          "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () => _deleteTransaction(tx.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
