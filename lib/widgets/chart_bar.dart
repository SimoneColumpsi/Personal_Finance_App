import 'package:flutter/material.dart';

class ChartBar extends StatelessWidget {
  final String label; // Es: "L", "M", "M" (Giorno)
  final double spendingAmount; // Es: 50.00
  final double spendingPctOfTotal; // Es: 0.5 (cioè il 50% dell'altezza)

  const ChartBar(
    this.label,
    this.spendingAmount,
    this.spendingPctOfTotal, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder serve per sapere quanto spazio abbiamo in altezza
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Column(
          children: [
            // 1. L'importo scritto in alto (ridotto per stare nello spazio)
            SizedBox(
              height: constraints.maxHeight * 0.15,
              child: FittedBox(
                child: Text('€${spendingAmount.toStringAsFixed(2)}'),
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.05),

            // 2. La barra vera e propria (il tubo)
            SizedBox(
              height: constraints.maxHeight * 0.6,
              width: 10,
              child: Stack(
                children: [
                  // Sfondo grigio (tubo vuoto)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1.0),
                      color: const Color.fromRGBO(220, 220, 220, 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Parte colorata (tubo pieno) che cambia altezza
                  FractionallySizedBox(
                    heightFactor:
                        spendingPctOfTotal, // Qui decidiamo quanto è alta!
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.05),

            // 3. La lettera del giorno in basso
            SizedBox(
              height: constraints.maxHeight * 0.15,
              child: FittedBox(child: Text(label)),
            ),
          ],
        );
      },
    );
  }
}
