import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int _periodOffset = 0;   // 0 = periodo corrente, -1 = precedente, ecc.

  // Calcola intervallo (inizio e fine) in base al tipo di periodo e all'offset
  DateTimeRange _calculateDateRange() {
    final now = DateTime.now();

    if (_selectedPeriod == 0) {
      // SETTIMANA (da Lunedì a Domenica)
      final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final start = currentMonday.add(Duration(days: _periodOffset * 7));
      final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      return DateTimeRange(start: start, end: end);
    } else if (_selectedPeriod == 1) {
      // MESE
      final targetDate = DateTime(now.year, now.month + _periodOffset, 1);
      final start = DateTime(targetDate.year, targetDate.month, 1);
      final lastDay = DateTime(targetDate.year, targetDate.month + 1, 0);
      final end = DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    } else {
      // ANNO
      final year = now.year + _periodOffset;
      final start = DateTime(year, 1, 1);
      final end = DateTime(year, 12, 31, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    }
  }

  // Etichetta testuale dinamica per il navigatore
  String _getPeriodLabel(DateTimeRange range) {
    if (_selectedPeriod == 0) {
      final formatter = DateFormat('d MMM', 'it_IT');
      return "${formatter.format(range.start)} - ${formatter.format(range.end)}";
    } else if (_selectedPeriod == 1) {
      return DateFormat('MMMM yyyy', 'it_IT').format(range.start).toUpperCase();
    } else {
      return "${range.start.year}";
    }
  }

  double _calculateTotalInRange(List<Transaction> txs, DateTime start, DateTime end) {
    return txs
        .where((tx) =>
            !tx.isIncome &&
            (tx.date.isAfter(start) || tx.date.isAtSameMomentAs(start)) &&
            (tx.date.isBefore(end) || tx.date.isAtSameMomentAs(end)))
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    final range = _calculateDateRange();

    // Filtro per il grafico basato sul range selezionato
    final filteredForChart = widget.transactions.where((tx) {
      return !tx.isIncome &&
          (tx.date.isAfter(range.start) || tx.date.isAtSameMomentAs(range.start)) &&
          (tx.date.isBefore(range.end) || tx.date.isAtSameMomentAs(range.end));
    }).toList();

    // Totale del periodo attualmente navigato
    final currentPeriodTotal = _calculateTotalInRange(widget.transactions, range.start, range.end);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // 1. Tasti filtro (Settimana / Mese / Anno)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton('Settimana', 0),
                _buildFilterButton('Mese', 1),
                _buildFilterButton('Anno', 2),
              ],
            ),

            const SizedBox(height: 10),

            // 2. Barra di navigazione temporale (< Periodo >)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: () => setState(() => _periodOffset--),
                  ),
                  Text(
                    _getPeriodLabel(range),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    // Blocca lo scorrimento verso il futuro se sei già nel periodo corrente
                    onPressed: _periodOffset < 0
                        ? () => setState(() => _periodOffset++)
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. Carosello Grafici con le sole spese dell'intervallo scelto
            ChartCarousel(
              recentTransactions: filteredForChart,
              selectedPeriodIndex: _selectedPeriod,
              referenceDate: range.start,
            ),

            const SizedBox(height: 25),

            // 4. Card con il totale del periodo selezionato
            _buildTotalCard(
              "SPESA DEL PERIODO SELEZIONATO",
              currentPeriodTotal,
              const Color(0xFF00796B),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, int period) {
    final isSelected = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = period;
            _periodOffset = 0; // Reset al periodo corrente quando si cambia modalità
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF009688) : Colors.grey[300],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
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