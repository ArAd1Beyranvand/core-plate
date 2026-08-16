import 'package:flutter/material.dart';

import '../theme/poster_tokens.dart';

/// Bordered hairline chip used to tag technologies in the poster footer.
class TechChip extends StatelessWidget {
  const TechChip(this.label, {super.key});

  final String label;

  static const Color _labelColor = Color(0xFFC8D2DA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: PosterTokens.hairline),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: PosterTokens.eyebrow.copyWith(color: _labelColor),
      ),
    );
  }
}
