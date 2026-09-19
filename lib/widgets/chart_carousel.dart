import 'package:flutter/material.dart';
import '../models/transaction.dart';
import './category_chart.dart';
import './month_calendar_widget.dart';
import './year_grid_widget.dart';
import './week_grid_widget.dart';

class ChartCarousel extends StatefulWidget {
  final List<Transaction> recentTransactions;
  final int selectedPeriodIndex;
  final DateTime referenceDate;

  const ChartCarousel({
    super.key,
    required this.recentTransactions,
    required this.selectedPeriodIndex,
    required this.referenceDate,
  });

  @override
  State<ChartCarousel> createState() => _ChartCarouselState();
}

class _ChartCarouselState extends State<ChartCarousel> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

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

  Widget _buildPeriodChart() {
    if (widget.selectedPeriodIndex == 0) {
      return WeekGridWidget(
        transactions: widget.recentTransactions,
        referenceDate: widget.referenceDate,
      );
    } else if (widget.selectedPeriodIndex == 1) {
      return MonthCalendarWidget(
        transactions: widget.recentTransactions,
        referenceDate: widget.referenceDate,
      );
    } else {
      return YearGridWidget(
        transactions: widget.recentTransactions,
        referenceDate: widget.referenceDate,
      );
    }
  }

  double _getCarouselHeight() {
    if (widget.selectedPeriodIndex == 0) {
      // Per la settimana: 160 per la tabella, 235 quando fai swipe sulla torta
      return _currentPageIndex == 0 ? 160.0 : 235.0;
    } else if (widget.selectedPeriodIndex == 1) {
      return 365.0; // Mese
    } else {
      return 340.0; // Anno
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: _getCarouselHeight(),
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: [
              _buildPeriodChart(),
              CategoryChart(widget.recentTransactions),
            ],
          ),
        ),
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
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
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