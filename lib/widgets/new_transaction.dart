import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewTransaction extends StatefulWidget {
  final Function(String, double, DateTime, String, bool) addTx;

  // --- NUOVI PARAMETRI OPZIONALI PER LA MODIFICA ---
  final String? existingTitle;
  final double? existingAmount;
  final DateTime? existingDate;
  final String? existingCategory;
  final bool existingIsIncome;

  const NewTransaction(
    this.addTx, {
    this.existingTitle,
    this.existingAmount,
    this.existingDate,
    this.existingCategory,
    super.key,
    this.existingIsIncome = false,
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

final List<String> _expenseCategories = ['Cibo', 'Trasporti', 'Svago', 'Casa', 'Altro'];
final List<String> _incomeCategories = ['Stipendio', 'Regalo', 'Vendita', 'Bonus', 'Altro'];

  @override
  void initState() {
    super.initState();
    // Se ci sono dati esistenti (MODIFICA), riempiamo i campi!
    if (widget.existingTitle != null) {
      _titleController = TextEditingController(text: widget.existingTitle);
      _amountController = TextEditingController(
        text: widget.existingAmount.toString(),
      );
      _selectedDate = widget.existingDate;
      _selectedCategory = widget.existingCategory ?? 'Altro';
      _isIncome = widget.existingIsIncome ?? false;
    } else {
      // Se non ci sono dati (NUOVA SPESA), partiamo vuoti
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _isIncome = false;
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
    // Gestione virgola/punto
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
    );

    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now(), // Parte dalla data salvata o da oggi
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
                  // CAMBIO DINAMICO DELLE CATEGORIE
                  items: (_isIncome ? _incomeCategories : _expenseCategories)
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                ),
              ],
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

  // Helper per i pulsanti di scelta tipo
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
          // Reset della categoria quando si cambia tipo per evitare errori
          _selectedCategory = isIncomeType ? _incomeCategories[0] : _expenseCategories[0];
        });
      },
      child: Text(label),
    );
  }
}
