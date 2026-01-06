import 'package:flutter/material.dart';

// --- NUOVO COMPONENTE: IL FORM PER INSERIRE I DATI ---
class NewTransaction extends StatefulWidget {
  final Function(String, double, DateTime) addTx;

  const NewTransaction(this.addTx, {super.key});

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate; // Può essere null se l'utente non ha ancora scelto

  void _submitData() {
    if (_amountController.text.isEmpty) {
      return;
    }
    final enteredTitle = _titleController.text;
    final enteredAmount = double.parse(_amountController.text);

    // Validazione: se manca titolo, prezzo o data, fermati!
    if (enteredTitle.isEmpty || enteredAmount <= 0 || _selectedDate == null) {
      return;
    }

    // Passa i dati al componente padre (HomePage)
    widget.addTx(enteredTitle, enteredAmount, _selectedDate!);

    // Chiudi il foglio
    Navigator.of(context).pop();
  }

  // Funzione che apre il calendario di Android
  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      // Se l'utente preme annulla (pickedDate è null), non fare nulla
      if (pickedDate == null) {
        return;
      }
      // Altrimenti aggiorna lo stato con la data scelta
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          // RIGA PER LA DATA
          SizedBox(
            height: 70,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Nessuna data scelta!'
                        : 'Data: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  ),
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
          ),
          ElevatedButton(
            onPressed: _submitData,
            child: const Text('Aggiungi Transazione'),
          ),
        ],
      ),
    );
  }
}
