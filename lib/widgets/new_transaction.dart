import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewTransaction extends StatefulWidget {
  // CORRETTO: La funzione ora accetta anche il sesto parametro String per il metodo di pagamento
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
  String _paymentMethod = 'Contanti'; // <--- AGGIUNTA VARIABILE DI STATO MANCANTE

  final List<String> _expenseCategories = ['Cibo', 'Trasporti', 'Svago', 'Casa', 'Altro'];
  final List<String> _incomeCategories = ['Stipendio', 'Regalo', 'Vendita', 'Bonus', 'Altro'];

  @override
  void initState() {
    super.initState();
    if (widget.existingTitle != null) {
      _titleController = TextEditingController(text: widget.existingTitle);
      _amountController = TextEditingController(text: widget.existingAmount.toString());
      _selectedDate = widget.existingDate;
      _selectedCategory = widget.existingCategory ?? 'Altro';
      _isIncome = widget.existingIsIncome;
      _paymentMethod = widget.existingPaymentMethod ?? 'Contanti'; // Ora è definita sopra!
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _isIncome = false;
      _paymentMethod = 'Contanti'; // Default per nuove transazioni
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

    // CORRETTO: Passiamo il sesto parametro alla funzione del main.dart
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
    return Card(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(10),
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
            TextField(
              decoration: const InputDecoration(labelText: 'Importo (€)'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

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

            // 4. NUOVO SELETTORE GRAFICO PER IL METODO DI PAGAMENTO
            const Text("Metodo di pagamento:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Contanti', label: Text('Contanti'), icon: Icon(Icons.money)),
                ButtonSegment(value: 'Carta', label: Text('Carta'), icon: Icon(Icons.credit_card)),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _paymentMethod = newSelection.first;
                });
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