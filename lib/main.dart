import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_localizations/flutter_localizations.dart';

import './models/transaction.dart';
import './widgets/new_transaction.dart';
import './widgets/chart_carousel.dart'; 
import './screens/login_screen.dart';
import './services/notification_service.dart';
import './screens/balance_screen.dart'; 
import './screens/analytics_screen.dart';
import './screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();

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
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
  int _selectedPageIndex = 1; // 1 = Home (Lista), 0 = Saldo

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  final Map<String, IconData> _categoryIcons = {
    'Cibo': Icons.fastfood,
    'Trasporti': Icons.directions_car,
    'Svago': Icons.movie,
    'Casa': Icons.home,
    'Altro': Icons.category,


    'Stipendio': Icons.payments,        // Icona banconote
    'Regalo': Icons.card_giftcard,     // Icona pacco regalo
    'Vendita': Icons.sell,             // Icona cartellino prezzo
    'Bonus': Icons.redeem,
  };

  void _addNewTransaction(String txTitle, double txAmount, DateTime chosenDate, String txCategory, bool isIncome) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance.collection('expenses').add({
      'title': txTitle,
      'amount': txAmount,
      'date': chosenDate,
      'category': txCategory,
      'isIncome': isIncome,
      'userId': user.uid,
    });
  }

  void _editTransactionFirebase(String id, String txTitle, double txAmount, DateTime chosenDate, String txCategory, bool isIncome) {
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
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: NewTransaction(_addNewTransaction),
      ),
    );
  }

  void _startEditTransaction(BuildContext ctx, Transaction tx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: NewTransaction(
          (title, amount, date, category, isIncome) => _editTransactionFirebase(tx.id, title, amount, date, category, isIncome),
          existingTitle: tx.title,
          existingAmount: tx.amount,
          existingDate: tx.date,
          existingCategory: tx.category,
          existingIsIncome: tx.isIncome,
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title, int index) {
    final isSelected = _selectedChartPeriod == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedChartPeriod = index),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Theme.of(context).colorScheme.secondary : null,
          foregroundColor: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey),
        ),
        child: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data?.docs ?? [];
        final loadedTransactions = docs.map((doc) {
          final data = doc.data();
          return Transaction(
            id: doc.id,
            title: data['title'],
            amount: (data['amount'] as num).toDouble(),
            date: (data['date'] as Timestamp).toDate(),
            category: data['category'] ?? 'Altro',
            isIncome: data['isIncome'] ?? false,
          );
        }).toList();

        loadedTransactions.sort((a, b) => b.date.compareTo(a.date));

        // Logica filtri per grafici
        final now = DateTime.now();
        List<Transaction> recentForChart = [];
        if (_selectedChartPeriod == 0) {
          final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          recentForChart = loadedTransactions.where((tx) => tx.date.isAfter(monday) || tx.date.isAtSameMomentAs(monday)).toList();
        } else if (_selectedChartPeriod == 1) {
          final firstDay = DateTime(now.year, now.month, 1);
          recentForChart = loadedTransactions.where((tx) => tx.date.isAfter(firstDay) || tx.date.isAtSameMomentAs(firstDay)).toList();
        } else {
          final firstYear = DateTime(now.year, 1, 1);
          recentForChart = loadedTransactions.where((tx) => tx.date.isAfter(firstYear) || tx.date.isAtSameMomentAs(firstYear)).toList();
        }

        // --- DEFINIZIONE PAGINE ---
        final List<String> titles = [
          'ANALISI SALDO',
          'LE MIE SPESE',
          'STATISTICHE',
          'IMPOSTAZIONI',
        ];

        final List<Widget> pages = [
          BalanceScreen(loadedTransactions), // Indice 0
          ListView.builder(
            itemCount: loadedTransactions.length,
            itemBuilder: (ctx, index) => _buildTransactionItem(context, loadedTransactions[index], isDarkMode),
          ), // Indice 1
          AnalyticsScreen(loadedTransactions), // Indice 2
          const SettingsScreen(), // Indice 3
        ];

        return Scaffold(
          appBar: AppBar(
            // Molto più semplice: pesca il titolo dalla lista in base all'indice
            title: Text(
              titles[_selectedPageIndex],
              style: const TextStyle(fontWeight: FontWeight.bold),
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

          body: pages[_selectedPageIndex],

          
          floatingActionButton: FloatingActionButton(
            onPressed: () => _startAddNewTransaction(context),
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribuisce meglio le icone
              children: [
                IconButton(
                  icon: Icon(Icons.account_balance_wallet, 
                    color: _selectedPageIndex == 0 ? Colors.teal : Colors.grey),
                  onPressed: () => _selectPage(0),
                ),
                IconButton(
                  icon: Icon(Icons.list, 
                    color: _selectedPageIndex == 1 ? Colors.teal : Colors.grey),
                  onPressed: () => _selectPage(1),
                ),
                const SizedBox(width: 40), // Lo spazio per non coprire la scritta "Lista"
                IconButton(
                  icon: Icon(Icons.bar_chart, 
                    color: _selectedPageIndex == 2 ? Colors.teal : Colors.grey),
                  onPressed: () => _selectPage(2),
                ),
                IconButton(
                  icon: Icon(Icons.settings, 
                    color: _selectedPageIndex == 3 ? Colors.teal : Colors.grey),
                  onPressed: () => _selectPage(3),
                ), 
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction tx, bool isDarkMode) {
    return Dismissible(
      key: ValueKey(tx.id),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white, size: 40),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sei sicuro?'),
          content: const Text('Vuoi eliminare questa spesa definitivamente?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sì, elimina')),
          ],
        ),
      ),
      onDismissed: (_) => _deleteTransaction(tx.id),
      child: Card(
        elevation: isDarkMode ? 2 : 4,
        color: isDarkMode ? Colors.grey.shade900 : null,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isDarkMode ? const BorderSide(color: Colors.amber, width: 1) : BorderSide.none,
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            // Cambiamo il colore del cerchio: verde se entrata, il colore primario se spesa
            backgroundColor: tx.isIncome 
                ? Colors.green.withOpacity(0.8) 
                : Colors.redAccent.withOpacity(0.7),
            foregroundColor: Colors.white,
            child: Icon(
              _categoryIcons[tx.category] ?? Icons.category, 
              size: 30
            ),
          ),
          title: Text(
            tx.title, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          subtitle: Text(
            "${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year}"
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tx.isIncome ? "+" : "-"} €${tx.amount.toStringAsFixed(2)}', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  // VERDE per entrate, ROSSO per spese
                  color: tx.isIncome ? Colors.green : Colors.redAccent,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _startEditTransaction(context, tx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}