import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewTransaction extends StatefulWidget {
  final Function(String, double, DateTime, String) addTx;

  // --- NUOVI PARAMETRI OPZIONALI PER LA MODIFICA ---
  final String? existingTitle;
  final double? existingAmount;
  final DateTime? existingDate;
  final String? existingCategory;

  const NewTransaction(
    this.addTx, {
    this.existingTitle,
    this.existingAmount,
    this.existingDate,
    this.existingCategory,
    super.key,
  });

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  DateTime? _selectedDate;
  String _selectedCategory = 'Altro';

  final List<String> _categories = [
    'Cibo',
    'Trasporti',
    'Svago',
    'Casa',
    'Altro',
  ];

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
    } else {
      // Se non ci sono dati (NUOVA SPESA), partiamo vuoti
      _titleController = TextEditingController();
      _amountController = TextEditingController();
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
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(labelText: 'Titolo'),
              controller: _titleController,
              onSubmitted: (_) => _submitData(),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Importo (€)'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSubmitted: (_) => _submitData(),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Nessuna data scelta!'
                            : 'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                      ),
                      TextButton(
                        onPressed: _presentDatePicker,
                        child: const Text(
                          'Scegli Data',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              children: [
                const Text("Categoria: ", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 15),
                DropdownButton<String>(
                  value: _selectedCategory,
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  underline: Container(
                    height: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  items: _categories.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submitData,
              // Cambiamo il testo del bottone se stiamo modificando
              child: Text(
                widget.existingTitle != null
                    ? 'Salva Modifiche'
                    : 'Aggiungi Transazione',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
