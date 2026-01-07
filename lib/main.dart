import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_localizations/flutter_localizations.dart';

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
      title: 'Le Mie Spese',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it', 'IT')],
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
  int _selectedChartPeriod = 0;

  final Map<String, IconData> _categoryIcons = {
    'Cibo': Icons.fastfood,
    'Trasporti': Icons.directions_car,
    'Svago': Icons.movie,
    'Casa': Icons.home,
    'Altro': Icons.category,
  };

  void _addNewTransaction(
    String txTitle,
    double txAmount,
    DateTime chosenDate,
    String txCategory,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance.collection('expenses').add({
      'title': txTitle,
      'amount': txAmount,
      'date': chosenDate,
      'category': txCategory,
      'userId': user.uid,
    });
  }

  void _editTransactionFirebase(
    String id,
    String txTitle,
    double txAmount,
    DateTime chosenDate,
    String txCategory,
  ) {
    FirebaseFirestore.instance.collection('expenses').doc(id).update({
      'title': txTitle,
      'amount': txAmount,
      'date': chosenDate,
      'category': txCategory,
    });
  }

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

  void _startEditTransaction(BuildContext ctx, Transaction tx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: NewTransaction(
            (title, amount, date, category) =>
                _editTransactionFirebase(tx.id, title, amount, date, category),
            existingTitle: tx.title,
            existingAmount: tx.amount,
            existingDate: tx.date,
            existingCategory: tx.category,
          ),
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Nessuna spesa nel cloud!",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final loadedTransactions = snapshot.data!.docs.map((doc) {
            final data = doc.data();
            return Transaction(
              id: doc.id,
              title: data['title'],
              amount: data['amount'],
              date: (data['date'] as Timestamp).toDate(),
              category: data['category'] ?? 'Altro',
            );
          }).toList();

          loadedTransactions.sort((a, b) => b.date.compareTo(a.date));

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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              SizedBox(
                height: 180,
                child: Chart(recentForChart, _selectedChartPeriod),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: loadedTransactions.length,
                  itemBuilder: (ctx, index) {
                    final tx = loadedTransactions[index];

                    // --- DISMISSIBLE: SWIPE PER CANCELLARE ---
                    return Dismissible(
                      key: ValueKey(
                        tx.id,
                      ), // Chiave univoca per identificare l'elemento
                      background: Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.error, // Sfondo Rosso
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      direction: DismissDirection
                          .endToStart, // Solo da destra a sinistra
                      // QUESTO È IL POPUP DI CONFERMA
                      confirmDismiss: (direction) {
                        return showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sei sicuro?'),
                            content: const Text(
                              'Vuoi eliminare questa spesa definitivamente?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(
                                    ctx,
                                  ).pop(false); // NO -> Non cancellare
                                },
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop(true); // SI -> Procedi
                                },
                                child: const Text('Sì, elimina'),
                              ),
                            ],
                          ),
                        );
                      },

                      // SE L'UTENTE DICE SÌ, CANCELLIAMO DAVVERO
                      onDismissed: (direction) {
                        _deleteTransaction(tx.id);
                      },

                      child: Card(
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
                            child: Icon(
                              _categoryIcons[tx.category] ?? Icons.category,
                              size: 30,
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
                            "${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year}",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '€${tx.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              // Abbiamo tolto il cestino, lasciamo solo la matita!
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.blue,
                                onPressed: () =>
                                    _startEditTransaction(context, tx),
                              ),
                            ],
                          ),
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
