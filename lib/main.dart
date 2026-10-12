import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import './models/transaction.dart';
import './widgets/new_transaction.dart';
import './widgets/chart_carousel.dart'; 
import './screens/login_screen.dart';
import './services/notification_service.dart';
import './screens/balance_screen.dart'; 
import './screens/analytics_screen.dart';
import './screens/settings_screen.dart';
import './providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await NotificationService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const PersonalFinanceApp(),
    ),
  );
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
      debugShowCheckedModeBanner: false,
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
  int _selectedPageIndex = 1; 

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
    'Stipendio': Icons.payments,        
    'Regalo': Icons.card_giftcard,     
    'Vendita': Icons.sell,             
    'Bonus': Icons.redeem,
  };

  void _addNewTransaction(String txTitle, double txAmount, DateTime chosenDate, String txCategory, bool isIncome, String paymentMethod) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance.collection('expenses').add({
      'title': txTitle,
      'amount': txAmount,
      'date': chosenDate,
      'category': txCategory,
      'isIncome': isIncome,
      'userId': user.uid,
      'paymentMethod': paymentMethod,
    });
  }

  void _editTransactionFirebase(String id, String txTitle, double txAmount, DateTime chosenDate, String txCategory, bool isIncome, String paymentMethod) {
    FirebaseFirestore.instance.collection('expenses').doc(id).update({
      'title': txTitle,
      'amount': txAmount,
      'date': chosenDate,
      'category': txCategory,
      'isIncome': isIncome,
      'paymentMethod': paymentMethod,
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
          (title, amount, date, category, isIncome, method) => 
              _editTransactionFirebase(tx.id, title, amount, date, category, isIncome, method),
          existingTitle: tx.title,
          existingAmount: tx.amount,
          existingDate: tx.date,
          existingCategory: tx.category,
          existingIsIncome: tx.isIncome,
          existingPaymentMethod: tx.paymentMethod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final langProvider = Provider.of<LanguageProvider>(context);
    final texts = langProvider.texts;

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
          final method = data.containsKey('paymentMethod') ? data['paymentMethod'] : 'Contanti';
          return Transaction(
            id: doc.id,
            title: data['title'],
            amount: (data['amount'] as num).toDouble(),
            date: (data['date'] as Timestamp).toDate(),
            category: data['category'] ?? 'Altro',
            isIncome: data['isIncome'] ?? false,
            paymentMethod: method,
          );
        }).toList();

        loadedTransactions.sort((a, b) => b.date.compareTo(a.date));

        final List<String> titles = [
          texts['balance_title'] ?? 'ANALISI SALDO',
          texts['app_title'] ?? 'LE MIE SPESE',
          texts['stats_title'] ?? 'STATISTICHE',
          texts['settings_title'] ?? 'IMPOSTAZIONI',
        ];

        final List<Widget> pages = [
          BalanceScreen(loadedTransactions), 
          
          // Schermata Lista Spese con Ricerca Combinata e Filtro Categoria
          _ExpenseListScreen(
            loadedTransactions, 
            _categoryIcons, 
            _deleteTransaction, 
            _startEditTransaction, 
            isDarkMode,
          ), 

          AnalyticsScreen(loadedTransactions), 
          const SettingsScreen(), 
        ];

        return Scaffold(
          appBar: AppBar(
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
              mainAxisAlignment: MainAxisAlignment.spaceAround, 
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
                const SizedBox(width: 40), 
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
}

// Widget isolato per gestire ricerca (titolo/categoria) e filtri multipli in modo fluido
class _ExpenseListScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final Map<String, IconData> categoryIcons;
  final Function(String) onDelete;
  final Function(BuildContext, Transaction) onEdit;
  final bool isDarkMode;

  const _ExpenseListScreen(
    this.transactions,
    this.categoryIcons,
    this.onDelete,
    this.onEdit,
    this.isDarkMode,
  );

  @override
  State<_ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<_ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool? _filterIsIncome;
  String? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Estrae le categorie disponibili in base al filtro tipo corrente
    final availableCategories = widget.transactions
        .where((tx) => _filterIsIncome == null || tx.isIncome == _filterIsIncome)
        .map((tx) => tx.category)
        .toSet()
        .toList();

    if (_filterCategory != null && !availableCategories.contains(_filterCategory)) {
      _filterCategory = null;
    }

    final filteredTransactions = widget.transactions.where((tx) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = tx.title.toLowerCase().contains(query) ||
          tx.category.toLowerCase().contains(query);
      
      final matchesType = _filterIsIncome == null || tx.isIncome == _filterIsIncome;
      final matchesCategory = _filterCategory == null || tx.category == _filterCategory;

      return matchesQuery && matchesType && matchesCategory;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cerca per titolo o categoria...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Filtro Tipo
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      value: _filterIsIncome,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelText: 'Tipo',
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tutti')),
                        DropdownMenuItem(value: false, child: Text('Spese')),
                        DropdownMenuItem(value: true, child: Text('Entrate')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filterIsIncome = val;
                          _filterCategory = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filtro Categoria Dinamico
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _filterCategory,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelText: 'Categoria',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tutte')),
                        ...availableCategories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => setState(() => _filterCategory = val),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_searchQuery.isNotEmpty || _filterIsIncome != null || _filterCategory != null)
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Resetta filtri',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _filterIsIncome = null;
                          _filterCategory = null;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: filteredTransactions.isEmpty
              ? const Center(child: Text("Nessuna transazione trovata."))
              : ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (ctx, index) {
                    return _buildItem(context, filteredTransactions[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, Transaction tx) {
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
      onDismissed: (_) => widget.onDelete(tx.id),
      child: Card(
        elevation: widget.isDarkMode ? 2 : 4,
        color: widget.isDarkMode ? Colors.grey.shade900 : null,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: widget.isDarkMode ? const BorderSide(color: Colors.amber, width: 1) : BorderSide.none,
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: tx.isIncome 
                ? Colors.green.withOpacity(0.8) 
                : Colors.redAccent.withOpacity(0.7),
            foregroundColor: Colors.white,
            child: Icon(
              widget.categoryIcons[tx.category] ?? Icons.category, 
              size: 30
            ),
          ),
          title: Text(
            tx.title, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          subtitle: Text(
            "${tx.category} • ${tx.date.day}/${tx.date.month}/${tx.date.year}\n[${tx.paymentMethod}]"
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${tx.isIncome ? "+" : "-"} €${tx.amount.toStringAsFixed(2)}', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: tx.isIncome ? Colors.green : Colors.redAccent,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => widget.onEdit(context, tx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}