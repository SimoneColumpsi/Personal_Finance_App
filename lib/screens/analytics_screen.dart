import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/chart_carousel.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const AnalyticsScreen(this.transactions, {super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0=Settimana, 1=Mese, 2=Anno

  @override
  Widget build(BuildContext context) {
    // FILTRIAMO: Prendiamo solo le SPESE (isIncome == false) per il grafico
    final onlyExpenses = widget.transactions.where((tx) => !tx.isIncome).toList();
    
    // Logica temporale (simile a quella che avevi nel main)
    final now = DateTime.now();
    List<Transaction> filteredTx = [];
    
    if (_selectedPeriod == 0) {
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      filteredTx = onlyExpenses.where((tx) => tx.date.isAfter(monday) || tx.date.isAtSameMomentAs(monday)).toList();
    } else if (_selectedPeriod == 1) {
      final firstDay = DateTime(now.year, now.month, 1);
      filteredTx = onlyExpenses.where((tx) => tx.date.isAfter(firstDay) || tx.date.isAtSameMomentAs(firstDay)).toList();
    } else {
      final firstYear = DateTime(now.year, 1, 1);
      filteredTx = onlyExpenses.where((tx) => tx.date.isAfter(firstYear) || tx.date.isAtSameMomentAs(firstYear)).toList();
    }

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Selettore periodo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFilterButton('Settimana', 0),
              _buildFilterButton('Mese', 1),
              _buildFilterButton('Anno', 2),
            ],
          ),
          const SizedBox(height: 20),
          // Il grafico mostrerà ora solo le spese!
          ChartCarousel(
            recentTransactions: filteredTx,
            selectedPeriodIndex: _selectedPeriod,
          ),
          // Qui in futuro aggiungeremo un grafico a torta per categorie
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, int index) {
    bool isSelected = _selectedPeriod == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.teal : null,
          foregroundColor: isSelected ? Colors.white : Colors.teal,
        ),
        onPressed: () => setState(() => _selectedPeriod = index),
        child: Text(label),
      ),
    );
  }
}