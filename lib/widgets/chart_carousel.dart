import 'package:flutter/material.dart';
import '../models/transaction.dart';
import './chart.dart';
import './category_chart.dart';

class ChartCarousel extends StatefulWidget {
  final List<Transaction> recentTransactions;
  final int selectedPeriodIndex;

  const ChartCarousel({
    super.key,
    required this.recentTransactions,
    required this.selectedPeriodIndex,
  });

  @override
  State<ChartCarousel> createState() => _ChartCarouselState();
}

class _ChartCarouselState extends State<ChartCarousel> {
  // Il controller vive qui dentro, al sicuro
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // L'AREA CHE SCORRE
        SizedBox(
          height: 220,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Questo setState aggiorna SOLO questo widget, non tutta la Home!
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              // Pagina 0: Grafico a Barre
              Chart(widget.recentTransactions, widget.selectedPeriodIndex),
              // Pagina 1: Grafico a Torta
              CategoryChart(widget.recentTransactions),
            ],
          ),
        ),

        // I PALLINI (INDICATORI)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pallino 1
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 10,
              width: _currentPageIndex == 0 ? 20 : 10, // Si allunga se attivo
              decoration: BoxDecoration(
                color: _currentPageIndex == 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Pallino 2
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 10,
              width: _currentPageIndex == 1 ? 20 : 10, // Si allunga se attivo
              decoration: BoxDecoration(
                color: _currentPageIndex == 1
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
