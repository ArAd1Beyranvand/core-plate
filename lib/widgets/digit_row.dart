import 'package:flutter/material.dart';

class DigitRow extends StatelessWidget {
  const DigitRow({super.key, required this.items, required this.gap});

  final List<Widget> items;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i != 0) SizedBox(width: gap),
          items[i],
        ],
      ],
    );
  }
}
