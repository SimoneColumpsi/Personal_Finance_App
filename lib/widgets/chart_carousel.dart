import 'package:flutter/material.dart';
import '../models/transaction.dart';
import './category_chart.dart';
import './chart.dart'; // <--- TORNATO ALL'ORIGINALE

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              // USA LA CLASSE ORIGINALE "Chart"
              Chart(widget.recentTransactions, widget.selectedPeriodIndex),
              CategoryChart(widget.recentTransactions),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 10,
              width: _currentPageIndex == 0 ? 20 : 10,
              decoration: BoxDecoration(
                color: _currentPageIndex == 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 10,
              width: _currentPageIndex == 1 ? 20 : 10,
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
