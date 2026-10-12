import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewTransaction extends StatefulWidget {
  final Function(String, double, DateTime, String, bool, String) addTx;

  final String? existingTitle;
  final double? existingAmount;
  final DateTime? existingDate;
  final String? existingCategory;
  final bool existingIsIncome;
  final String? existingPaymentMethod;

  const NewTransaction(
    this.addTx, {
    this.existingTitle,
    this.existingAmount,
    this.existingDate,
    this.existingCategory,
    super.key,
    this.existingIsIncome = false,
    this.existingPaymentMethod,
  });

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  DateTime? _selectedDate;
  String _selectedCategory = 'Altro';
  bool _isIncome = false; 
  String _paymentMethod = 'Contanti'; 

  final List<String> _expenseCategories = ['Cibo', 'Trasporti', 'Svago', 'Casa', 'Altro'];
  final List<String> _incomeCategories = ['Stipendio', 'Regalo', 'Vendita', 'Bonus', 'Altro'];
  
  // Lista dinamica dei box caricati da Firestore
  List<String> _availableAccounts = ['Contanti', 'Carta'];

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    if (widget.existingTitle != null) {
      _titleController = TextEditingController(text: widget.existingTitle);
      _amountController = TextEditingController(text: widget.existingAmount.toString());
      _selectedDate = widget.existingDate;
      _selectedCategory = widget.existingCategory ?? 'Altro';
      _isIncome = widget.existingIsIncome;
      _paymentMethod = widget.existingPaymentMethod ?? 'Contanti';
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _selectedDate = DateTime.now(); // Default data odierna per comodità
      _isIncome = false;
      _paymentMethod = 'Contanti';
    }
  }

  // Carica i box personalizzati da Firestore
  Future<void> _loadAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _availableAccounts = snapshot.docs
              .map((doc) => doc.data()['name'].toString())
              .toList();
              
          // Se il metodo attuale non è presente nella lista, seleziona il primo
          if (!_availableAccounts.contains(_paymentMethod)) {
            _paymentMethod = _availableAccounts.first;
          }
        });
      }
    } catch (e) {
      // Gestione silenziosa in caso di errore di rete
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (_amountController.text.isEmpty) {
      return;
    }

    final enteredTitle = _titleController.text;
    final enteredAmount = double.parse(
      _amountController.text.replaceAll(',', '.'),
    );

    if (enteredTitle.isEmpty || enteredAmount <= 0 || _selectedDate == null) {
      return;
    }

    widget.addTx(
      enteredTitle,
      enteredAmount,
      _selectedDate!,
      _selectedCategory,
      _isIncome,
      _paymentMethod,
    );

    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(), 
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale("it", "IT"),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Assicuriamoci che il valore selezionato esista nella lista dei menu a tendina
    if (!_availableAccounts.contains(_paymentMethod) && _availableAccounts.isNotEmpty) {
      _paymentMethod = _availableAccounts.first;
    }

    return Card(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 1. SCELTA TIPO (ENTRATA O SPESA)
            const Text("Tipo di operazione:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeButton("SPESA", false, Colors.red),
                const SizedBox(width: 20),
                _buildTypeButton("ENTRATA", true, Colors.green),
              ],
            ),
            const Divider(height: 30),

            // 2. CAMPI TESTUALI
            TextField(
              decoration: const InputDecoration(labelText: 'Titolo'),
              controller: _titleController,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: 'Importo (€)'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 15),

            // 3. DATA E CATEGORIA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _presentDatePicker,
                  child: Text(_selectedDate == null 
                    ? 'Scegli Data' 
                    : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                ),
                DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                  items: (_isIncome ? _incomeCategories : _expenseCategories)
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                ),
              ],
            ),
            const Divider(height: 20),

            // 4. SELETTORE DINAMICO DEL CONTENITORE
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Contenitore / Metodo:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _availableAccounts.map((acc) {
                return DropdownMenuItem(
                  value: acc,
                  child: Text(acc),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _paymentMethod = val;
                  });
                }
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitData,
              child: const Text('Conferma'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isIncomeType, Color color) {
    bool isSelected = _isIncome == isIncomeType;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade300,
        foregroundColor: isSelected ? Colors.white : Colors.black54,
      ),
      onPressed: () {
        setState(() {
          _isIncome = isIncomeType;
          _selectedCategory = isIncomeType ? _incomeCategories[0] : _expenseCategories[0];
        });
      },
      child: Text(label),
    );
  }
}