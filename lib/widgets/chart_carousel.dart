import 'package:flutter/material.dart';
import '../models/transaction.dart';
import './category_chart.dart';
import './chart.dart'; 
import './line_chart_widget.dart'; // <--- IMPORTANTE: Aggiungi questo import

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
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // Questo serve per resettare la pagina a 0 quando cambi il filtro (Settimana/Mese/Anno)
  @override
  void didUpdateWidget(covariant ChartCarousel oldWidget) {
    if (oldWidget.selectedPeriodIndex != widget.selectedPeriodIndex) {
      _pageController.jumpToPage(0);
      setState(() {
        _currentPageIndex = 0;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220, // Altezza fissa per permettere lo scorrimento
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(), // Rende lo scorrimento più fluido
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              // PAGINA 1: Grafico Temporale
              widget.selectedPeriodIndex == 2
                  ? LineChartWidget(transactions: widget.recentTransactions) // LINEA per Anno
                  : Chart(widget.recentTransactions, widget.selectedPeriodIndex), // BARRE per gli altri
              
              // PAGINA 2: Grafico a Torta
              CategoryChart(widget.recentTransactions),
            ],
          ),
        ),
        // Indicatori (i pallini sotto il grafico)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(0),
            _buildDot(1),
          ],
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      height: 8,
      width: _currentPageIndex == index ? 18 : 8,
      decoration: BoxDecoration(
        color: _currentPageIndex == index
            ? Theme.of(context).primaryColor
            : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}