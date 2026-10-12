import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction.dart';

class CategoryChart extends StatefulWidget {
  final List<Transaction> recentTransactions;

  const CategoryChart(this.recentTransactions, {super.key});

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  Map<String, Color> _categoryColors = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryColors();
  }

  // Carica i colori personalizzati salvati su Firestore dall'utente
  Future<void> _loadCategoryColors() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('categories')
          .get();

      Map<String, Color> colorsMap = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String?;
        final hexColor = data['color'] as String?;
        if (name != null) {
          colorsMap[name] = _hexToColor(hexColor ?? '2196f3');
        }
      }

      if (mounted) {
        setState(() {
          _categoryColors = colorsMap;
        });
      }
    } catch (_) {}
  }

  // Utility per convertire la stringa Hex in oggetto Color
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  // Restituisce il colore personalizzato o un fallback coerente
  Color _getCategoryColor(String category) {
    if (_categoryColors.containsKey(category)) {
      return _categoryColors[category]!;
    }
    // Fallback di default per categorie standard se non mappate
    switch (category) {
      case 'Cibo':
        return Colors.redAccent;
      case 'Trasporti':
        return Colors.blueAccent;
      case 'Svago':
        return Colors.purpleAccent;
      case 'Casa':
        return Colors.orangeAccent;
      default:
        return Colors.teal; // Invece di grigio, usiamo un bel teal per evitare confusione
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recentTransactions.isEmpty) {
      return const Center(child: Text("Nessuna spesa nel periodo!"));
    }

    // 1. Calcoliamo il totale generale
    double totalSum = 0.0;
    // 2. Calcoliamo quanto abbiamo speso per ogni categoria
    Map<String, double> categoryTotals = {};

    for (var tx in widget.recentTransactions) {
      totalSum += tx.amount;
      if (categoryTotals.containsKey(tx.category)) {
        categoryTotals[tx.category] = categoryTotals[tx.category]! + tx.amount;
      } else {
        categoryTotals[tx.category] = tx.amount;
      }
    }

    // 3. Creiamo le "fette" della torta
    List<PieChartSectionData> sections = [];
    categoryTotals.forEach((category, amount) {
      final percentage = totalSum > 0 ? (amount / totalSum) * 100 : 0.0;
      sections.add(
        PieChartSectionData(
          color: _getCategoryColor(category),
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
        child: Center( // <-- Centriamo tutto il contenuto nel blocco
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // <-- Centriamo gli elementi orizzontalmente
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LA TORTA
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 160, // Diamo un'altezza fissa controllata alla torta
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 35,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),

              // LA LEGENDA
              Expanded(
                flex: 4,
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: categoryTotals.keys.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getCategoryColor(cat),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}