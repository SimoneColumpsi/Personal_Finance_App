import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewTransaction extends StatefulWidget {
  // Ora la funzione accetta anche la Stringa della categoria!
  final Function(String, double, DateTime, String) addTx;

  const NewTransaction(this.addTx, {super.key});

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;

  // Questa variabile tiene in memoria la scelta dell'utente
  // Impostiamo 'Altro' come valore di partenza
  String _selectedCategory = 'Altro';

  // Lista delle categorie disponibili
  final List<String> _categories = [
    'Cibo',
    'Trasporti',
    'Svago',
    'Casa',
    'Altro',
  ];

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

    // Passiamo anche la categoria selezionata (_selectedCategory) a main.dart
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
      initialDate: DateTime.now(),
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
          mainAxisSize: MainAxisSize.min, // Importante per il modale
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

            // --- SELETTORE DATA E CATEGORIA ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Selettore Data
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

            // --- MENU A TENDINA (DROPDOWN) ---
            Row(
              children: [
                const Text("Categoria: ", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 15),
                DropdownButton<String>(
                  value: _selectedCategory, // Valore attuale
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  underline: Container(
                    height: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                  onChanged: (String? newValue) {
                    // Quando l'utente cambia scelta, aggiorniamo la variabile
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  // Creiamo la lista delle opzioni
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
              child: const Text('Aggiungi Transazione'),
            ),
          ],
        ),
      ),
    );
  }
}
