import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/chart_carousel.dart';
import '../widgets/line_chart_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const AnalyticsScreen(this.transactions, {super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0=Settimana, 1=Mese, 2=Anno

  double _calculateTotal(List<Transaction> txs, DateTime startDate) {
    return txs
        .where((tx) => 
            !tx.isIncome && 
            (tx.date.isAfter(startDate) || tx.date.isAtSameMomentAs(startDate)))
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final firstDayMonth = DateTime(now.year, now.month, 1);
    final firstDayYear = DateTime(now.year, 1, 1);

    final weeklyTotal = _calculateTotal(widget.transactions, monday);
    final monthlyTotal = _calculateTotal(widget.transactions, firstDayMonth);
    final yearlyTotal = _calculateTotal(widget.transactions, firstDayYear);

    List<Transaction> filteredForChart = [];
    if (_selectedPeriod == 0) {
      filteredForChart = widget.transactions.where((tx) => !tx.isIncome && (tx.date.isAfter(monday) || tx.date.isAtSameMomentAs(monday))).toList();
    } else if (_selectedPeriod == 1) {
      filteredForChart = widget.transactions.where((tx) => !tx.isIncome && (tx.date.isAfter(firstDayMonth) || tx.date.isAtSameMomentAs(firstDayMonth))).toList();
    } else {
      filteredForChart = widget.transactions.where((tx) => !tx.isIncome && (tx.date.isAfter(firstDayYear) || tx.date.isAtSameMomentAs(firstDayYear))).toList();
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            // Tasti filtro
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton('Settimana', 0),
                _buildFilterButton('Mese', 1),
                _buildFilterButton('Anno', 2),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // --- UNICA BARRA CON GRAFICI SCORREVOLI ---
            const SizedBox(height: 10),
              SizedBox(
                height: 250, 
                child: ChartCarousel(
                  recentTransactions: filteredForChart,
                  selectedPeriodIndex: _selectedPeriod,
                ),
              ),

            const SizedBox(height: 30), // Spazio tra grafico e totali

            // --- TOTALI SOTTO IL GRAFICO ---
            _buildTotalCard("TOTALE SETTIMANA", weeklyTotal, const Color(0xFF4DB6AC)),
            _buildTotalCard("TOTALE MESE", monthlyTotal, const Color(0xFF009688)),
            _buildTotalCard("TOTALE ANNO", yearlyTotal, const Color(0xFF00695C)),

              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }
  
    Widget _buildFilterButton(String label, int period) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          onPressed: () => setState(() => _selectedPeriod = period),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedPeriod == period ? const Color(0xFF009688) : Colors.grey[300],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _selectedPeriod == period ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }
  
    Widget _buildTotalCard(String title, double amount, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '€${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }